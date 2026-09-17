import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Screen blending drops black from the animation without modifying the GIF.
class ExplosionOverlay extends StatelessWidget {
  final String asset;
  const ExplosionOverlay({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Positioned.fill(
      child: AbsorbPointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1100),
          builder: (context, t, child) {
            final shake = reduced
                ? 0.0
                : math.sin(t * math.pi * 24) * 12 * (1 - t);
            return Transform.translate(
              offset: Offset(shake, shake * 0.5),
              child: Transform.scale(
                scale: reduced
                    ? 1
                    : 0.55 + Curves.easeOutCubic.transform(t) * 1.15,
                child: child,
              ),
            );
          },
          child: Center(
            child: _ScreenBlend(
              child: Image.asset(
                asset,
                width: MediaQuery.sizeOf(context).width * 0.85,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenBlend extends SingleChildRenderObjectWidget {
  const _ScreenBlend({required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderScreenBlend();
}

class _RenderScreenBlend extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.saveLayer(
      offset & size,
      Paint()..blendMode = BlendMode.screen,
    );
    super.paint(context, offset);
    context.canvas.restore();
  }
}
