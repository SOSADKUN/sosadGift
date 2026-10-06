import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// The whole door fills with light until the screen is entirely white.
class DoorOpeningScreen extends StatefulWidget {
  const DoorOpeningScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<DoorOpeningScreen> createState() => _DoorOpeningScreenState();
}

class _DoorOpeningScreenState extends State<DoorOpeningScreen>
    with SingleTickerProviderStateMixin {
  final _sound = AudioPlayer();

  Future<void> _playOpeningSound() async {
    try {
      await _sound.play(AssetSource('audio/door_open.wav'), volume: .8);
    } catch (_) {}
  }

  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 5600),
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _playOpeningSound();
  }

  @override
  void dispose() {
    _controller.dispose();
    _sound.dispose().catchError((Object _) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final opening = Curves.easeInOutCubic.transform(
            ((_controller.value - .32) / .48).clamp(0.0, 1.0),
          );
          final white = Curves.easeInOut.transform(
            ((_controller.value - .6) / .24).clamp(0.0, 1.0),
          );
          final reduced = MediaQuery.disableAnimationsOf(context);
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: reduced
                    ? 1
                    : 1 +
                          .32 *
                              Curves.easeInOutCubic.transform(
                                (_controller.value / .32).clamp(0.0, 1.0),
                              ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (final left in [true, false])
                      Positioned(
                        left: left ? 0 : box.maxWidth / 2,
                        top: 0,
                        width: box.maxWidth / 2,
                        height: box.maxHeight,
                        child: Transform.translate(
                          offset: Offset(
                            reduced
                                ? 0
                                : (left ? -1 : 1) * box.maxWidth * .6 * opening,
                            0,
                          ),
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: left
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              minWidth: box.maxWidth,
                              maxWidth: box.maxWidth,
                              minHeight: box.maxHeight,
                              maxHeight: box.maxHeight,
                              child: Image.asset(
                                'assets/photos/bigDoor.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: opening,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.15,
                        colors: [
                          Colors.white,
                          Color(0xDDFFF4DB),
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: white,
                  child: const ColoredBox(
                    key: ValueKey('door-whiteout'),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
