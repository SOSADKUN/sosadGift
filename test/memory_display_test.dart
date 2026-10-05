import 'package:flutter_test/flutter_test.dart';
import 'package:gift/config/memory_display_config.dart';

void main() {
  test('discovers numbered photos and sorts numerically with gaps', () {
    expect(
      MemoryDisplayConfig.orderedPhotos([
        'assets/last_display_image/image120.jpg',
        'assets/last_display_image/image10.webp',
        'assets/last_display_image/README.md',
        'assets/last_display_image/image2.png',
        'assets/last_display_image/image1.jpeg',
        'assets/last_display_image/image0.jpg',
        'assets/photos/image3.jpg',
      ]),
      [
        'assets/last_display_image/image1.jpeg',
        'assets/last_display_image/image2.png',
        'assets/last_display_image/image10.webp',
        'assets/last_display_image/image120.jpg',
      ],
    );
  });
  test('120 photos loop from the last photo back to the first', () {
    final photos = MemoryDisplayConfig.orderedPhotos(
      List.generate(
        120,
        (i) => 'assets/last_display_image/image${120 - i}.jpg',
      ),
    );
    expect(photos.length, 120);
    expect(photos.first, endsWith('image1.jpg'));
    expect(photos.last, endsWith('image120.jpg'));
    expect(MemoryDisplayConfig.nextIndex(119, photos.length), 0);
    expect(MemoryDisplayConfig.nextIndex(0, photos.length), 1);
    expect(MemoryDisplayConfig.nextIndex(0, 1), 0);
    expect(MemoryDisplayConfig.nextIndex(0, 0), 0);
  });
}
