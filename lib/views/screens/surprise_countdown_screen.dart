import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SurpriseCountdownScreen extends StatefulWidget {
  const SurpriseCountdownScreen({
    super.key,
    required this.onComplete,
    this.now,
    this.audioPlayerFactory,
  });
  final VoidCallback onComplete;
  final DateTime Function()? now;
  final AudioPlayer Function()? audioPlayerFactory;

  @override
  State<SurpriseCountdownScreen> createState() =>
      _SurpriseCountdownScreenState();
}

class _SurpriseCountdownScreenState extends State<SurpriseCountdownScreen>
    with WidgetsBindingObserver {
  static final _audioContext = AudioContext(
    android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    iOS: AudioContextIOS(options: {AVAudioSessionOptions.mixWithOthers}),
  );
  late final DateTime _deadline;
  Timer? _timer;
  static const _durationSeconds = 90;
  int _seconds = _durationSeconds;
  bool _completed = false;

  bool _active = true;
  int? _lastBeep;
  late final AudioPlayer _beep;
  late final Future<void> _beepReady;
  late final Map<int, AudioPlayer> _voices;
  late final Map<int, Future<void>> _voiceReady;
  int? _lastSpoken;

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _beep = widget.audioPlayerFactory?.call() ?? AudioPlayer();
    _beepReady = _prepareBeep();
    _lastBeep = _durationSeconds;
    _playBeep(_durationSeconds);
    _deadline = _now().add(const Duration(seconds: _durationSeconds));
    _voices = {
      for (var n = 1; n <= 10; n++)
        n: widget.audioPlayerFactory?.call() ?? AudioPlayer(),
    };
    _voiceReady = {for (var n = 1; n <= 10; n++) n: _prepareVoice(n)};
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _completed || !_active) return;
    final milliseconds = _deadline.difference(_now()).inMilliseconds;
    final remaining = (milliseconds / 1000).ceil().clamp(0, _durationSeconds);
    if (remaining != _seconds) setState(() => _seconds = remaining);
    if (remaining > 0 && _lastBeep != remaining) {
      _lastBeep = remaining;
      if (remaining > 10) _playBeep(remaining);
    }
    if (remaining == 0) {
      for (final voice in _voices.values) {
        voice.stop().catchError((Object _) {});
      }
      _finish();
    } else if (remaining <= 10 && _lastSpoken != remaining) {
      _lastSpoken = remaining;
      unawaited(_speak(remaining));
    }
  }

  Future<void> _prepareVoice(int number) async {
    try {
      final voice = _voices[number]!;
      await voice.setAudioContext(_audioContext);
      await voice.setReleaseMode(ReleaseMode.stop);
      await voice.setVolume(.85);
      await voice.setSource(AssetSource('audio/countdown_$number.wav'));
    } catch (e) {
      debugPrint('English countdown unavailable: $e');
    }
  }

  Future<void> _speak(int number) async {
    try {
      await _voiceReady[number];
      if (!mounted || !_active || _completed || _seconds != number) return;
      await _voices[number]!.seek(Duration.zero);
      await _voices[number]!.resume();
    } catch (_) {}
  }

  Future<void> _prepareBeep() async {
    try {
      await _beep.setAudioContext(_audioContext);
      await _beep.setReleaseMode(ReleaseMode.stop);
      await _beep.setVolume(.3);
      await _beep.setSource(AssetSource('audio/countdown_tick.wav'));
    } catch (e) {
      debugPrint('Countdown tick unavailable: $e');
    }
  }

  Future<void> _playBeep(int second) async {
    try {
      await _beepReady;
      if (!mounted || !_active || _seconds != second) return;
      await _beep.seek(Duration.zero);
      await _beep.resume();
    } catch (_) {}
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    _timer?.cancel();
    widget.onComplete();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _tick();
    } else {
      _beep.pause().catchError((Object _) {});
      for (final voice in _voices.values) {
        voice.pause().catchError((Object _) {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _beep.dispose().catchError((Object _) {});
    for (final voice in _voices.values) {
      voice.dispose().catchError((Object _) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF190F20),
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFECD2A4), size: 40),
            const SizedBox(height: 24),
            const Text(
              '恭喜妳完成小游戏 居然解密成功了',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 16),
            const Text(
              '那就最后啦 闭上双眼倒数1分30秒～ 不能作弊哦',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 36),
            Text(
              '$_seconds',
              style: const TextStyle(
                color: Color(0xFFECD2A4),
                fontSize: 88,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
