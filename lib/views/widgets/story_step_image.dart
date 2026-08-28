import 'package:flutter/material.dart';

/// Shows the photo for the current story step. Sized to fit either a
/// horizontal or a vertical image without cropping.
class StoryStepImage extends StatelessWidget {
  final String? imageAsset;
  final int stepNumber;

  const StoryStepImage({
    super.key,
    required this.imageAsset,
    required this.stepNumber,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageAsset == null
            ? _MockSlide(number: stepNumber)
            : Image.asset(imageAsset!, fit: BoxFit.contain),
      ),
    );
  }
}

class _MockSlide extends StatelessWidget {
  final int number;
  const _MockSlide({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      color: const Color(0xFFF3E4D0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 40, color: Color(0xFFB08B62)),
          const SizedBox(height: 8),
          Text('Mock photo $number',
              style: const TextStyle(color: Color(0xFFB08B62), fontSize: 14)),
        ],
      ),
    );
  }
}
