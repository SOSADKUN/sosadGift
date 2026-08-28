import 'dart:async';
import 'package:flutter/material.dart';

/// Reveals [text] one character at a time. Restarts automatically whenever
/// [text] changes, so swapping in a new sentence re-triggers the typing effect.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 35),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    _charCount = 0;
    _timer = Timer.periodic(widget.charDuration, (timer) {
      if (_charCount >= widget.text.length) {
        timer.cancel();
        return;
      }
      setState(() => _charCount++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget.text.substring(0, _charCount), style: widget.style);
  }
}
