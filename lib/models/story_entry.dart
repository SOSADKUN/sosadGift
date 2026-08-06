class StoryEntry {
  final String year; // e.g. "第一年"
  final String title; // short headline
  final String body; // the story text
  final String? imageAsset; // optional photo for this year

  const StoryEntry({
    required this.year,
    required this.title,
    required this.body,
    this.imageAsset,
  });
}

/// Your 4-year recap — fill in the real text/photos here.
final List<StoryEntry> kStoryEntries = [
  const StoryEntry(
    year: '第一年',
    title: '认识',
    body: '因为玩原神认识了你，然后每一年的生日我都没有缺席。',
  ),
  const StoryEntry(
    year: '第二年',
    title: '驾车',
    body: 'TODO: 驾车 + 一串串 的故事', // 一串串 candy/snack story
  ),
  const StoryEntry(
    year: '第三年',
    title: 'B Hotel',
    body: 'TODO: 仓鼠 的故事',
  ),
  const StoryEntry(
    year: '第四年',
    title: 'PD',
    body: 'TODO: PD 偷他的 IG 照片 的故事',
  ),
];