import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A cylindrical "coverflow" style photo carousel: cards curve away from the
/// viewer as they slide toward the edges, looping and auto-advancing on
/// their own (still swipeable by hand too).
class CurvedPhotoCarousel extends StatefulWidget {
  final List<String?> imageAssets;
  final Duration autoPlayInterval;

  const CurvedPhotoCarousel({
    super.key,
    required this.imageAssets,
    this.autoPlayInterval = const Duration(seconds: 3),
  });

  @override
  State<CurvedPhotoCarousel> createState() => _CurvedPhotoCarouselState();
}

class _CurvedPhotoCarouselState extends State<CurvedPhotoCarousel> {
  // Fake "infinite" looping: start deep into a huge virtual list so the
  // user can auto-advance/swipe either direction for a very long time.
  static const _loopMultiplier = 5000;

  late final PageController _controller;
  Timer? _autoTimer;
  double _page = 0;

  int get _count => widget.imageAssets.length;

  @override
  void initState() {
    super.initState();
    final initialPage = (_loopMultiplier ~/ 2) * _count;
    _page = initialPage.toDouble();
    _controller = PageController(
      viewportFraction: 0.62,
      initialPage: initialPage,
    );
    _controller.addListener(() {
      final p = _controller.page;
      if (p != null) setState(() => _page = p);
    });
    if (_count > 1) {
      _autoTimer = Timer.periodic(widget.autoPlayInterval, (_) {
        if (!mounted ||
            !_controller.hasClients ||
            _controller.position.isScrollingNotifier.value) {
          return;
        }
        _controller.nextPage(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth * 0.62;
        const angleStep = 0.85;
        final radius = pageWidth / math.sin(angleStep);
        return PageView.builder(
          controller: _controller,
          itemCount: _count * _loopMultiplier,
          itemBuilder: (context, index) {
            final asset = widget.imageAssets[index % _count];
            final delta = (index - _page).clamp(-2.0, 2.0);
            final angle = delta * angleStep;
            // Follow the outside of a cylinder: the center is closest, and
            // each side recedes in depth with its outer edge turning away.
            // Subtract PageView's horizontal movement to follow a circular arc.
            final translateX = radius * math.sin(angle) - delta * pageWidth;
            final depth = radius * (math.cos(angle) - 1);
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, -0.0016)
                ..translateByDouble(translateX, 0.0, depth, 1.0)
                ..rotateY(angle),
              child: Opacity(
                opacity: 1 - delta.abs().clamp(0.0, 1.0) * 0.18,
                child: _PhotoCard(imageAsset: asset),
              ),
            );
          },
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String? imageAsset;
  const _PhotoCard({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: imageAsset == null
              ? _placeholder()
              : Image.asset(imageAsset!, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF3E4D0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 48,
        color: Color(0xFFB08B62),
      ),
    );
  }
}
