import 'package:flutter/material.dart';

class DoorKeyGlow extends StatelessWidget {
  const DoorKeyGlow({super.key, required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [Colors.white, color, color.withValues(alpha: .2)],
      ),
      boxShadow: [
        BoxShadow(color: color, blurRadius: 40, spreadRadius: 18),
        BoxShadow(
          color: color.withValues(alpha: .75),
          blurRadius: 110,
          spreadRadius: 45,
        ),
        const BoxShadow(color: Colors.white, blurRadius: 12, spreadRadius: 3),
      ],
    ),
  );
}

const doorHolePositions = [
  Offset(352, 628),
  Offset(549, 628),
  Offset(352, 837),
  Offset(549, 837),
];
const doorHoleColors = [
  Color(0xFFFFA7D9),
  Color(0xFF99DEFF),
  Color(0xFFC6A6FF),
  Color(0xFFFFDF89),
];

class LitDoorImage extends StatelessWidget {
  const LitDoorImage({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = box.maxWidth / 900 > box.maxHeight / 1600
          ? box.maxWidth / 900
          : box.maxHeight / 1600;
      final rect = Rect.fromLTWH(
        (box.maxWidth - 900 * scale) / 2,
        (box.maxHeight - 1600 * scale) / 2,
        900 * scale,
        1600 * scale,
      );
      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Image.asset('assets/photos/bigDoor.png', fit: BoxFit.cover),
          for (var i = 0; i < doorHolePositions.length; i++)
            Positioned(
              left: rect.left + doorHolePositions[i].dx * rect.width / 900 - 20,
              top: rect.top + doorHolePositions[i].dy * rect.height / 1600 - 20,
              child: DoorKeyGlow(
                key: ValueKey('opening-key-glow-$i'),
                color: doorHoleColors[i],
              ),
            ),
        ],
      );
    },
  );
}
