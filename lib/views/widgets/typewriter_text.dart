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
      if (_charCount >= widget.text.characters.length) {
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
    final visibleText = MediaQuery.disableAnimationsOf(context)
        ? widget.text
        : widget.text.characters.take(_charCount).toString();
    // Reserve the full sentence's layout so the writing does not jump as
    // a new line appears. Expose the complete sentence to screen readers.
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Opacity(opacity: 0, child: Text(widget.text, style: widget.style)),
            Text(visibleText, style: widget.style),
          ],
        ),
      ),
    );
  }
}
