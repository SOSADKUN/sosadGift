class StoryStep {
  final String sentence;
  final String? imageAsset; // fill in the real photo path later

  const StoryStep({required this.sentence, this.imageAsset});
}

class StoryEntry {
  final String year;
  final String title;
  final List<StoryStep> steps;

  const StoryEntry({
    required this.year,
    required this.title,
    required this.steps,
  });
}

/// Mock placeholder copy — swap in the real story text/photos later.
final List<StoryEntry> kStoryEntries = [
  const StoryEntry(
    year: 'Year One',
    title: 'Mock title one',
    steps: [
      StoryStep(sentence: 'This is the first mock sentence for year one.'),
      StoryStep(sentence: 'This is the second mock sentence for year one.'),
      StoryStep(sentence: 'This is the third mock sentence for year one.'),
    ],
  ),
  const StoryEntry(
    year: 'Year Two',
    title: 'Mock title two',
    steps: [
      StoryStep(sentence: 'This is the first mock sentence for year two.'),
      StoryStep(sentence: 'This is the second mock sentence for year two.'),
    ],
  ),
  const StoryEntry(
    year: 'Year Three',
    title: 'Mock title three',
    steps: [
      StoryStep(sentence: 'This is the first mock sentence for year three.'),
      StoryStep(sentence: 'This is the second mock sentence for year three.'),
      StoryStep(sentence: 'This is the third mock sentence for year three.'),
    ],
  ),
  const StoryEntry(
    year: 'Year Four',
    title: 'Mock title four',
    steps: [
      StoryStep(sentence: 'This is the first mock sentence for year four.'),
      StoryStep(sentence: 'This is the second mock sentence for year four.'),
    ],
  ),
];
