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

/// A dreamlike cake reveal; only the end of the birthday song advances it.
class DigitalCakeScreen extends StatefulWidget {
  const DigitalCakeScreen({super.key, this.onComplete, this.birthdayPlayer});
  final VoidCallback? onComplete;

  /// Optional player for testing audio completion independently of native audio.
  final AudioPlayer? birthdayPlayer;

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
    final status = await Permission.microphone.request();
    if (!mounted || !status.isGranted || _blownOut) return;

    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission() || !mounted) return;
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _audioSub = stream.listen(_onAudioChunk, onError: (_) {});
      if (mounted) setState(() => _micActive = true);
    } catch (_) {
      // Simulator / unsupported platform — silently fall back to tap-only.
    }
  }

  void _onAudioChunk(Uint8List chunk) {
    if (_blownOut) return;
    if (_decibelsFromPcm16(chunk) >= _blowThresholdDb) {
      _blowOutCandle();
    }
  }

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
    if (_blownOut) return;
    setState(() => _blownOut = true);
    HapticFeedback.mediumImpact();
    _audioSub?.cancel();
    _recorder?.stop();
    _scheduleFinale();
  }

  void _scheduleFinale() {
    if (!mounted || !_songFinished || !_cakeReady || _completed) return;
    _completed = true;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
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
          onCandleTap: _blowOutCandle,
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
                      _blownOut ? '愿你的每一年，都被温柔以待。' : '闭上眼睛，许一个愿。',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF7E5DF),
                        fontSize: 17,
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
                : _cakeReady
                ? IconButton(
                    tooltip: '开启吹蜡烛',
                    onPressed: _micActive || _blownOut ? null : _initMic,
                    icon: Icon(
                      _micActive ? Icons.mic : Icons.mic_none,
                      color: const Color(0xFFBBA3BE),
                      size: 18,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    ),
  );
}
