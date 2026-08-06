import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// "30秒按30个小鸡毛" — tap 30 feathers before the 30-second timer runs out.
class GameThreeScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const GameThreeScreen({super.key, required this.onComplete});

  @override
  State<GameThreeScreen> createState() => _GameThreeScreenState();
}

class _GameThreeScreenState extends State<GameThreeScreen> {
  static const _target = 30;
  static const _seconds = 30;

  int _tapped = 0;
  int _secondsLeft = _seconds;
  Timer? _timer;
  Offset _featherPos = const Offset(0.5, 0.5);
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _finish(success: _tapped >= _target);
    });
    _moveFeather();
  }

  void _moveFeather() {
    final rnd = Random();
    setState(() {
      _featherPos = Offset(0.1 + rnd.nextDouble() * 0.8, 0.15 + rnd.nextDouble() * 0.6);
    });
  }

  void _onTapFeather() {
    if (_finished) return;
    setState(() => _tapped++);
    if (_tapped >= _target) {
      _finish(success: true);
    } else {
      _moveFeather();
    }
  }

  void _finish({required bool success}) {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    if (success) {
      Future.delayed(const Duration(milliseconds: 400), widget.onComplete);
    } else {
      // give them another try
      setState(() {
        _tapped = 0;
        _secondsLeft = _seconds;
        _finished = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) _finish(success: _tapped >= _target);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '$_tapped / $_target   •   ⏱ $_secondsLeft s',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            Positioned(
              left: _featherPos.dx * constraints.maxWidth - 24,
              top: _featherPos.dy * constraints.maxHeight,
              child: GestureDetector(
                onTap: _onTapFeather,
                child: const Text('🪶', style: TextStyle(fontSize: 48)),
              ),
            ),
          ],
        );
      },
    );
  }
}