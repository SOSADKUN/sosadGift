import 'package:flutter/material.dart';

/// A short birthday greeting before the diary opens.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3000),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onComplete();
        });
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final reveal = _entrance.drive(
      CurveTween(curve: const Interval(0, .35, curve: Curves.easeOutCubic)),
    );
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2E5F5), Color(0xFFFFF2EB), Color(0xFFF5DFE8)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              top: -100,
              right: -110,
              child: _Halo(size: 330, color: Color(0x33C5A1DF)),
            ),
            const Positioned(
              bottom: -140,
              left: -120,
              child: _Halo(size: 420, color: Color(0x33EFA3B5)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = (constraints.maxWidth * .55)
                      .clamp(120.0, 240.0)
                      .clamp(0.0, constraints.maxHeight * .43);
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      child: FadeTransition(
                        opacity: reduced
                            ? const AlwaysStoppedAnimation(1)
                            : reveal,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(size * .23),
                                border: Border.all(
                                  color: Colors.white70,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33A85C7F),
                                    blurRadius: 40,
                                    offset: Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(size * .23),
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  width: size,
                                  height: size,
                                ),
                              ),
                            ),
                            const SizedBox(height: 34),
                            const Text(
                              '今年的生日，依旧是我',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF775266),
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              '妳滴专属惊喜OWO',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFA78291),
                                fontSize: 12,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 30),
                            const Icon(
                              Icons.favorite_rounded,
                              size: 15,
                              color: Color(0xFFD298A9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}
