import 'package:flutter/material.dart';

import '../widgets/video_player_widget.dart';

/// Short opening intro between the unlocked door and the birthday cake.
class DoorOpeningScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const DoorOpeningScreen({super.key, required this.onComplete});

  @override
  State<DoorOpeningScreen> createState() => _DoorOpeningScreenState();
}

class _DoorOpeningScreenState extends State<DoorOpeningScreen>
    with SingleTickerProviderStateMixin {
  // Set this to your opening video after adding it to pubspec.yaml.
  static const String? _openingVideoAsset = null;
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });

  @override
  void initState() {
    super.initState();
    if (_openingVideoAsset == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_openingVideoAsset != null) {
      return VideoPlayerWidget(
        assetPath: _openingVideoAsset!,
        onComplete: widget.onComplete,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF190F20),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final opening = Curves.easeInOutCubic.transform(
            ((_controller.value - 0.12) / 0.68).clamp(0.0, 1.0),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFE8B0),
                      Color.lerp(
                        const Color(0xFFA6647A),
                        const Color(0xFFFFCBA0),
                        opening,
                      )!,
                      const Color(0xFF301C34),
                    ],
                    radius: 0.9,
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: 1 - opening,
                  child: Transform.translate(
                    offset: Offset(
                      -MediaQuery.sizeOf(context).width * opening,
                      0,
                    ),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.85,
                      height: MediaQuery.sizeOf(context).height * 0.75,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(110),
                          right: Radius.circular(12),
                        ),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFAC765D), Color(0xFF5A3040)],
                        ),
                        border: Border.all(
                          color: const Color(0xFFE9BC76),
                          width: 5,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 25),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFFFD996),
                        size: 54,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: opening,
                  child: const Text(
                    '惊喜就在门后 ♡',
                    style: TextStyle(
                      color: Color(0xFF572E48),
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
