import 'package:flutter/material.dart';

/// A cream, grid-lined notebook page with cute corner doodles —
/// the visual base for diary-style screens. Drop content on top via [child].
class DiaryPageBackground extends StatelessWidget {
  final Widget? child;

  const DiaryPageBackground({super.key, this.child});

  static const _paper = Color(0xFFFBF6EA);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _paper,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _GridPainter()),

          // gold corner protector, top-right
          const Positioned(top: 0, right: 0, child: _GoldCorner()),

          // corner doodles
          const Positioned(top: 18, left: 14, child: _TopLeftDoodle()),
          const Positioned(top: 60, right: 20, child: _TopRightDoodle()),
          const Positioned(bottom: 18, left: 14, child: _BottomLeftDoodle()),
          const Positioned(bottom: 18, right: 14, child: _BottomRightDoodle()),

          // scattered stars
          const Positioned(top: 130, left: 24, child: _Star(size: 16)),
          const Positioned(top: 210, right: 30, child: _Star(size: 18)),
          const Positioned(bottom: 140, left: 30, child: _Star(size: 16)),
          const Positioned(bottom: 150, right: 90, child: _Star(size: 14)),

          ?child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  static const _spacing = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCE7F0)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += _spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoldCorner extends StatelessWidget {
  const _GoldCorner();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TriangleClipper(),
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFEAD6A0), Color(0xFFC9A15E)],
          ),
        ),
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Star extends StatelessWidget {
  final double size;
  const _Star({required this.size});

  @override
  Widget build(BuildContext context) {
    return Text('⭐', style: TextStyle(fontSize: size));
  }
}

class _TopLeftDoodle extends StatelessWidget {
  const _TopLeftDoodle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text('🌸', style: TextStyle(fontSize: 22)),
        Text('🌷', style: TextStyle(fontSize: 20)),
        Text('🌼', style: TextStyle(fontSize: 18)),
      ],
    );
  }
}

class _TopRightDoodle extends StatelessWidget {
  const _TopRightDoodle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('🐻', style: TextStyle(fontSize: 26)),
        Text('🌸', style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

class _BottomLeftDoodle extends StatelessWidget {
  const _BottomLeftDoodle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🐻', style: TextStyle(fontSize: 26)),
        Row(
          children: [
            Text('🌷', style: TextStyle(fontSize: 16)),
            Text('🌸', style: TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }
}

class _BottomRightDoodle extends StatelessWidget {
  const _BottomRightDoodle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('🐷', style: TextStyle(fontSize: 18)),
        Text('🐻', style: TextStyle(fontSize: 28)),
        Text('🌸', style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
