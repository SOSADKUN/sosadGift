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
  late final DateTime _deadline;
  Timer? _timer;
  int _seconds = 30;
  bool _completed = false;
  bool _ending = false;
  bool _greetingDone = false;
  bool _active = true;
  int? _lastSpoken;
  late final List<AudioPlayer> _voices;
  late final List<Future<void>> _voiceReady;

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voices = List.generate(
      11,
      (_) => widget.audioPlayerFactory?.call() ?? AudioPlayer(),
    );
    _voiceReady = List.generate(11, _prepareVoice);
    _deadline = _now().add(const Duration(seconds: 30));
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _completed || !_active) return;
    if (_ending) {
      if (_greetingDone) _finish();
      return;
    }
    final milliseconds = _deadline.difference(_now()).inMilliseconds;
    final remaining = (milliseconds / 1000).ceil().clamp(0, 30);
    if (remaining != _seconds) setState(() => _seconds = remaining);
    if (remaining == 0) {
      _ending = true;
      _sayBirthday();
    } else if (remaining <= 10 && _lastSpoken != remaining) {
      _lastSpoken = remaining;
      _speak(remaining);
    }
  }

  Future<void> _prepareVoice(int number) async {
    try {
      await _voices[number].setReleaseMode(ReleaseMode.stop);
      await _voices[number].setVolume(.85);
      await _voices[number].setSource(
        AssetSource('audio/countdown_$number.wav'),
      );
    } catch (error) {
      debugPrint('Countdown voice unavailable: $error');
    }
  }

  Future<void> _speak(int number) async {
    try {
      await _voiceReady[number];
      if (!mounted || !_active || _seconds != number || _ending) return;
      await _voices[number].resume();
    } catch (_) {}
  }

  Future<void> _sayBirthday() async {
    StreamSubscription<void>? completion;
    try {
      await _voiceReady[0];
      if (!mounted || !_active) {
        _ending = false;
        return;
      }
      final finished = Completer<void>();
      completion = _voices[0].onPlayerComplete.listen((_) {
        if (!finished.isCompleted) finished.complete();
      });
      await _voices[0].resume();
      await finished.future.timeout(const Duration(seconds: 2));
    } catch (_) {
      // Audio errors must not prevent the birthday reveal.
    } finally {
      completion?.cancel();
    }
    if (!mounted) return;
    _greetingDone = true;
    if (_active) _finish();
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
      for (final voice in _voices) {
        voice.pause().catchError((Object _) {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (final voice in _voices) {
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
              '恭喜你完成小游戏 居然解密成功了',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 16),
            const Text(
              '那就最后啦 闭上双眼倒数30秒～ 不能作弊哦',
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
