import 'package:flutter/material.dart';

/// Final screen: digital cake with a candle to "blow out".
/// TODO: for a real blow-detection, use the `microphone`/`noise_meter`
/// package to detect breath volume and trigger _blowOutCandle().
/// For now it's tap-to-blow so the flow works end-to-end.
class DigitalCakeScreen extends StatefulWidget {
  const DigitalCakeScreen({super.key});

  @override
  State<DigitalCakeScreen> createState() => _DigitalCakeScreenState();
}

class _DigitalCakeScreenState extends State<DigitalCakeScreen> {
  bool _blownOut = false;

  void _blowOutCandle() => setState(() => _blownOut = true);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _blowOutCandle,
            child: Text(
              _blownOut ? '🎂' : '🎂🕯️',
              style: const TextStyle(fontSize: 100),
            ),
          ),
          const SizedBox(height: 24),
          if (_blownOut)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '今年、明年、未来的每一年，我也不会缺席。\n生日快乐 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20, height: 1.6),
              ),
            )
          else
            const Text(
              '闭上眼睛，许个愿，然后点一下蜡烛吹熄它吧',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
        ],
      ),
    );
  }
}