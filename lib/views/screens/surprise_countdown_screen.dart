import 'dart:async';
import 'package:flutter/material.dart';

class SurpriseCountdownScreen extends StatefulWidget {
  const SurpriseCountdownScreen({
    super.key,
    required this.onComplete,
    this.now,
  });
  final VoidCallback onComplete;
  final DateTime Function()? now;

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

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deadline = _now().add(const Duration(seconds: 30));
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _completed) return;
    final milliseconds = _deadline.difference(_now()).inMilliseconds;
    final remaining = (milliseconds / 1000).ceil().clamp(0, 30);
    if (remaining != _seconds) setState(() => _seconds = remaining);
    if (remaining == 0) {
      _completed = true;
      _timer?.cancel();
      widget.onComplete();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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
              '恭喜你完成小游戏 居然解密成功',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 16),
            const Text('那就最后啦 闭上双眼倒数30秒～ 不能作弊哦', style: TextStyle(color: Colors.white70)),
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
