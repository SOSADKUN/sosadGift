abstract final class MemoryDisplayConfig {
  static const photoDirectory = 'assets/last_display_image/';
  static const musicAsset = 'music/memory_bgm.mp3';
  static const fallbackMusic = 'audio/memory_piano.wav';
  static const photoDuration = Duration(seconds: 5);

  static List<String> orderedPhotos(Iterable<String> assets) {
    final pattern = RegExp(
      r'^assets/last_display_image/image([1-9][0-9]*)\.(jpg|jpeg|png|webp)$',
      caseSensitive: false,
    );
    final photos = assets.where((path) => pattern.hasMatch(path)).toList();
    photos.sort((a, b) {
      final first = int.parse(pattern.firstMatch(a)!.group(1)!);
      final second = int.parse(pattern.firstMatch(b)!.group(1)!);
      final order = first.compareTo(second);
      return order == 0 ? a.compareTo(b) : order;
    });
    return photos;
  }

  static int nextIndex(int current, int count) =>
      count == 0 ? 0 : (current + 1) % count;
}
