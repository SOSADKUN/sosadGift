import 'package:flutter/material.dart';

/// A white space reveals an unidentified object before the phone is discovered.
class PhoneFloorScene extends StatefulWidget {
  const PhoneFloorScene({super.key, required this.onPickUp});
  final VoidCallback onPickUp;

  @override
  State<PhoneFloorScene> createState() => _PhoneFloorSceneState();
}

class _PhoneFloorSceneState extends State<PhoneFloorScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
    animationBehavior: AnimationBehavior.preserve,
  );
  bool _found = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _arrival.forward();
  }

  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  void _inspect() {
    if (_arrival.value < .85 || _found) return;
    setState(() => _found = true);
  }

  void _open() {
    if (_opening) return;
    _opening = true;
    widget.onPickUp();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: AnimatedBuilder(
      animation: _arrival,
      builder: (context, _) {
        final reveal = Curves.easeInOutCubic.transform(
          ((_arrival.value - .18) / .67).clamp(0.0, 1.0),
        );
        final prompt = Curves.easeOut.transform(
          ((_arrival.value - .85) / .15).clamp(0.0, 1.0),
        );
        return LayoutBuilder(
          builder: (context, box) => Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: box.maxWidth / 2 - 62,
                top: box.maxHeight * .44 - 105,
                child: Opacity(
                  opacity: reveal,
                  child: AnimatedRotation(
                    turns: _found ? 0 : -.045,
                    duration: const Duration(milliseconds: 600),
                    child: Semantics(
                      button: true,
                      label: _found ? '捡到的手机' : '查看黑色物体',
                      child: GestureDetector(
                        key: const ValueKey('floor-phone'),
                        onTap: _inspect,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          width: 124,
                          height: 225,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101014),
                            borderRadius: BorderRadius.circular(
                              _found ? 24 : 16,
                            ),
                            border: _found
                                ? Border.all(
                                    color: const Color(0xFF86838C),
                                    width: 2,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: _found ? .18 : .1,
                                ),
                                blurRadius: _found ? 28 : 42,
                                offset: const Offset(6, 16),
                              ),
                            ],
                          ),
                          child: AnimatedOpacity(
                            opacity: _found ? 1 : 0,
                            duration: const Duration(milliseconds: 600),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF62506A),
                                      Color(0xFF292238),
                                      Color(0xFF191625),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF101014),
                                        borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(9),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.lock_outline,
                                      size: 18,
                                      color: Colors.white60,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      '一条未读消息',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 35,
                                      height: 3,
                                      margin: const EdgeInsets.only(bottom: 9),
                                      decoration: BoxDecoration(
                                        color: Colors.white54,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 26,
                right: 26,
                bottom: MediaQuery.paddingOf(context).bottom + 42,
                child: Opacity(
                  opacity: _found ? 1 : prompt,
                  child: IgnorePointer(
                    ignoring: !_found && prompt < .9,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _found
                          ? _card(
                              key: const ValueKey('phone-discovered'),
                              title: '原来是一部手机。',
                              subtitle: '你捡起了一部手机。\n屏幕里，似乎藏着一段未读的故事。',
                              action: '打开手机',
                              onTap: _open,
                            )
                          : _card(
                              key: const ValueKey('mysterious-object'),
                              title: '那是什么？',
                              subtitle: '白光里，似乎有一个黑色的东西…',
                              action: '走近看看',
                              onTap: _inspect,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _card({
    required Key key,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) => Container(
    key: key,
    constraints: const BoxConstraints(maxWidth: 380),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFFAF9F7),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFEAE6E2)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 24,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF26212C),
            fontSize: 23,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF918890),
            fontSize: 13,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF302738),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
          ),
          child: Text(action),
        ),
      ],
    ),
  );
}
