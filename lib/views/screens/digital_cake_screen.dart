import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../../config/treasure_hunt_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/birthday_cinematic_scene.dart';
import '../widgets/birthday_fireworks.dart';

/// Reveal, hold-to-blow interaction, then a complete fireworks celebration.
class DigitalCakeScreen extends StatefulWidget {
  const DigitalCakeScreen({
    super.key,
    this.onComplete,
    this.birthdayPlayer,
    this.fireworksPlayer,
    this.blowLevels,
  });
  final VoidCallback? onComplete;

  /// Optional player for testing audio completion independently of native audio.
  final AudioPlayer? birthdayPlayer;
  final AudioPlayer? fireworksPlayer;

  /// Injectable microphone levels for platforms without a native recorder.
  final Stream<double>? blowLevels;

  @override
  State<DigitalCakeScreen> createState() => _DigitalCakeScreenState();
}

class _DigitalCakeScreenState extends State<DigitalCakeScreen>
    with TickerProviderStateMixin {
  late final _birthdayPlayer = widget.birthdayPlayer ?? AudioPlayer();
  bool _completed = false;
  bool _musicError = false;
  StreamSubscription<void>? _birthdayComplete;
  bool _songFinished = false;
  bool _blownOut = false;
  bool _micActive = false;
  bool _holdingBlow = false;
  bool _micStarting = false;
  String? _micMessage;
  int _micSession = 0;
  StreamSubscription<double>? _levelSub;
  bool _celebrationFinished = false;
  late final _fireworkSound = widget.fireworksPlayer ?? AudioPlayer();
  late final AnimationController _celebration =
      AnimationController(
        vsync: this,
        duration: const Duration(seconds: 6),
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _celebrationFinished = true;
          _scheduleFinale();
        }
      });

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSub;

  // dBFS (decibels relative to full scale) — negative values, 0 is loudest
  // possible. Ambient room noise is typically around -50 to -35 dBFS; a
  // close blow spikes up sharply toward 0. Tune this if it's too
  // sensitive/insensitive for your mic setup.
  static const double _blowThresholdDb = -20.0;

  bool _cakeReady = false;

  @override
  void initState() {
    super.initState();
    _birthdayComplete = _birthdayPlayer.onPlayerComplete.listen((_) {
      _songFinished = true;
      _scheduleFinale();
    });
    _playBirthdaySong();
  }

  Future<void> _playBirthdaySong() async {
    if (mounted) setState(() => _musicError = false);
    try {
      await _birthdayPlayer.setReleaseMode(ReleaseMode.release);
      if (!mounted) return;
      await _birthdayPlayer.play(
        AssetSource(TreasureHuntConfig.birthdaySong),
        volume: 0.65,
      );
    } catch (error) {
      debugPrint('Birthday music unavailable: $error');
      if (mounted) setState(() => _musicError = true);
    }
  }

  Future<void> _initMic() async {
    if (!_cakeReady || _blownOut || _micStarting) return;
    final session = ++_micSession;
    setState(() {
      _holdingBlow = true;
      _micStarting = true;
      _micMessage = null;
    });
    bool active() =>
        mounted && _holdingBlow && !_blownOut && session == _micSession;
    try {
      if (widget.blowLevels != null) {
        _levelSub = widget.blowLevels!.listen(_onLevel);
        if (active()) setState(() => _micActive = true);
        return;
      }
      final status = await Permission.microphone.request();
      if (!active()) return;
      if (!status.isGranted) {
        setState(() => _micMessage = '需要麦克风权限才能吹灭蜡烛');
        return;
      }
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission() || !active()) return;
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      if (!active()) {
        await recorder.stop();
        return;
      }
      _audioSub = stream.listen(
        _onAudioChunk,
        onError: (_) {
          if (mounted) setState(() => _micMessage = '麦克风暂时不可用，请重试');
          _releaseBlow();
        },
      );
      setState(() => _micActive = true);
    } catch (_) {
      if (mounted) setState(() => _micMessage = '麦克风暂时不可用，请在真机重试');
    } finally {
      if (mounted) setState(() => _micStarting = false);
    }
  }

  void _releaseBlow() {
    _micSession++;
    _audioSub?.cancel();
    _audioSub = null;
    _levelSub?.cancel();
    _levelSub = null;
    _recorder?.stop().catchError((Object _) => null);
    if (mounted) {
      setState(() {
        _holdingBlow = false;
        _micActive = false;
      });
    }
  }

  void _onLevel(double level) {
    if (_holdingBlow &&
        _micActive &&
        _cakeReady &&
        !_blownOut &&
        level >= _blowThresholdDb) {
      _blowOutCandle();
    }
  }

  void _onAudioChunk(Uint8List chunk) => _onLevel(_decibelsFromPcm16(chunk));

  /// Computes RMS-based dBFS from a chunk of little-endian 16-bit PCM audio.
  double _decibelsFromPcm16(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return -160.0;

    final byteData = ByteData.sublistView(bytes);
    double sumSquares = 0;
    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      sumSquares += sample * sample;
    }

    final rms = sqrt(sumSquares / sampleCount);
    if (rms <= 0) return -160.0;
    return 20 * log(rms / 32768) / ln10;
  }

  void _blowOutCandle() {
    if (_blownOut || !_holdingBlow || !_micActive || !_cakeReady) return;
    setState(() => _blownOut = true);
    HapticFeedback.mediumImpact();
    _releaseBlow();
    _celebration.forward();
    _fireworkSound
        .play(AssetSource('audio/birthday_fireworks.wav'), volume: .65)
        .catchError((Object _) {});
  }

  void _scheduleFinale() {
    if (!mounted ||
        !_songFinished ||
        !_cakeReady ||
        !_blownOut ||
        !_celebrationFinished ||
        _completed) {
      return;
    }
    _completed = true;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _celebration.dispose();
    _fireworkSound.dispose().catchError((Object _) {});
    _levelSub?.cancel();
    _birthdayComplete?.cancel();
    _birthdayPlayer.dispose();
    _audioSub?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF180F20),
    body: Stack(
      fit: StackFit.expand,
      children: [
        BirthdayCinematicScene(
          blownOut: _blownOut,
          onReady: () {
            if (!mounted) return;
            setState(() => _cakeReady = true);
            _scheduleFinale();
          },
          onCandleTap: () {},
        ),
        IgnorePointer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const Text(
                    'JUST FOR YOU',
                    style: TextStyle(
                      color: Color(0xFFD9BDD0),
                      fontSize: 9,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Happy Birthday',
                    style: TextStyle(
                      color: Color(0xFFFFF0E2),
                      fontSize: 30,
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _cakeReady ? 1 : 0,
                    duration: const Duration(milliseconds: 900),
                    child: Text(
                      _blownOut ? '生日快乐！！！' : '闭上眼睛，许一个愿。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF7E5DF),
                        fontSize: _blownOut ? 28 : 17,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 65),
                ],
              ),
            ),
          ),
        ),
        if (_blownOut) BirthdayFireworks(animation: _celebration),
        Positioned(
          bottom: MediaQuery.paddingOf(context).bottom + 10,
          left: 0,
          right: 0,
          child: Center(
            child: _musicError
                ? TextButton.icon(
                    onPressed: _playBirthdaySong,
                    icon: const Icon(Icons.music_note),
                    label: const Text('重新播放生日歌'),
                  )
                : _cakeReady && !_blownOut
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_micMessage != null)
                        Text(
                          _micMessage!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      Listener(
                        onPointerDown: (_) => _initMic(),
                        onPointerUp: (_) => _releaseBlow(),
                        onPointerCancel: (_) => _releaseBlow(),
                        child: Semantics(
                          button: true,
                          label: '按住吹蜡烛',
                          child: Container(
                            key: const ValueKey('hold-to-blow'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _micActive
                                  ? const Color(0xFFBB749C)
                                  : const Color(0xFF6D456B),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFE9BADA),
                              ),
                            ),
                            child: Text(
                              _micStarting
                                  ? '正在开启麦克风…'
                                  : _micActive
                                  ? '对着麦克风吹气～'
                                  : '按住这里，吹蜡烛',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    ),
  );
}
