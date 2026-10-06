import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FoundPhoneLockScreen extends StatefulWidget {
  const FoundPhoneLockScreen({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;

  @override
  State<FoundPhoneLockScreen> createState() => _FoundPhoneLockScreenState();
}

class _FoundPhoneLockScreenState extends State<FoundPhoneLockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _wrong = false;
  bool _unlocked = false;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  void _press(String value) {
    if (_unlocked) return;
    HapticFeedback.selectionClick();
    setState(() {
      _wrong = false;
      _pin += value;
    });
    if (_pin.length < 4) return;
    if (_pin == '0917') {
      _unlocked = true;
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong = true;
        _pin = '';
      });
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF473751), Color(0xFF28213E), Color(0xFF191727)],
      ),
    ),
    child: LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFECD2A4),
                  size: 28,
                ),
                const SizedBox(height: 22),
                const Text(
                  '输入密码',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '解锁这部手机，看看谁留下了消息',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      MediaQuery.disableAnimationsOf(context)
                          ? 0
                          : sin(_shake.value * pi * 6) * 9 * (1 - _shake.value),
                      0,
                    ),
                    child: child,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (i) => Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _pin.length
                              ? const Color(0xFFECD2A4)
                              : Colors.transparent,
                          border: Border.all(
                            color: _wrong
                                ? const Color(0xFFFF98AA)
                                : Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 24,
                  child: Text(
                    _wrong ? '密码不对，再试一次' : '输入 4 位密码',
                    style: TextStyle(
                      color: _wrong ? const Color(0xFFFF98AA) : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.08,
                  children: [
                    for (final digit in [
                      '1',
                      '2',
                      '3',
                      '4',
                      '5',
                      '6',
                      '7',
                      '8',
                      '9',
                    ])
                      _key(digit),
                    const SizedBox(),
                    _key('0'),
                    IconButton(
                      tooltip: '删除一位',
                      onPressed: () => setState(() {
                        if (_pin.isNotEmpty) {
                          _pin = _pin.substring(0, _pin.length - 1);
                        }
                        _wrong = false;
                      }),
                      icon: const Icon(
                        Icons.backspace_outlined,
                        color: Colors.white60,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '一段未读的故事，正在等你。',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _key(String digit) => Material(
    color: const Color(0x227F738F),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: () => _press(digit),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    ),
  );
}
