class StoryStep {
  final String sentence;
  final String? imageAsset;
  final String? videoAsset;

  const StoryStep({required this.sentence, this.imageAsset, this.videoAsset})
    : assert(imageAsset == null || videoAsset == null);
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
    year: '2022',
    title: '原神启动',
    steps: [
      StoryStep(
        sentence: '刚刚的开头放原神启动～其实是因为 我觉得原神是我们相遇的契机w！',
        imageAsset: 'assets/photos/story/2022/1.jpg',
      ),
      StoryStep(
        sentence: '我们真正的开始 是从这个story reply开始的哈哈哈哈 也是因为domino和原神联动ww',
        imageAsset: 'assets/photos/story/2022/2.jpg',
      ),
      StoryStep(
        sentence: '当年我们聊了好多原神话题 那年的我们 还只是网友关系',
        videoAsset: 'assets/photos/story/2022/3.mp4',
      ),
      StoryStep(
        sentence: '所以你的生日 我只能从原神里送一个小小的礼物了www',
        imageAsset: 'assets/photos/story/2022/5.jpg',
      ),
      StoryStep(
        sentence: '你看你 当时收到20块的月卡 居然就说爱我来钓我www！',
        imageAsset: 'assets/photos/story/2022/4.jpg',
      ),
    ],
  ),
  const StoryEntry(
    year: '2023',
    title: '香水一日游',
    steps: [
      StoryStep(
        sentence: '送香水给你之前 其实也是偷之前信息的idea www',
        imageAsset: 'assets/photos/story/2023/1.jpg',
      ),
      StoryStep(
        sentence: ' 直接去puchong找你的我 的却考虑得不周到wwww 但我第一次那么大胆诶！',
        imageAsset: 'assets/photos/story/2023/2.jpg',
      ),
      StoryStep(
        sentence: '看回去依旧感觉如此不真实 我真的 很喜欢看到你开心的样子w',
        imageAsset: 'assets/photos/story/2023/3.jpg',
      ),
      StoryStep(
        sentence: '然后哦我其实很怕我送的东西 你已经买了噗哈哈哈哈',
        imageAsset: 'assets/photos/story/2023/4.jpg',
      ),
    ],
  ),
  const StoryEntry(
    year: '2024',
    title: '翻版MUAJI噗',
    steps: [
      StoryStep(
        sentence: '这一年吼 你真的很大胆！ 怎么可以随便跟一个男人出来住酒店',
        imageAsset: 'assets/photos/story/2024/1.jpg',
      ),
      StoryStep(
        sentence: '这年礼物送了个超级不像仓鼠的muaji 但是花了好多钱钱的！（后面的花朵还是你教我买的wwww ',
        imageAsset: 'assets/photos/story/2024/2.jpg',
      ),
      StoryStep(
        sentence: '为了跟商家沟通 我偷了很多照片！！！但我还是有下心思derrQwQ 所以你只能虚心接受了哈哈哈哈哈',
        imageAsset: 'assets/photos/story/2024/2.5.jpg',
      ),
      StoryStep(
        sentence: '这一年生日 我记得你都还要做工QwQ 但是没有照片可以记录噗 放一张同款房型纪念w ',
        imageAsset: 'assets/photos/story/2024/3.jpg',
      ),
      StoryStep(
        sentence: '但至少我觉得 我们当下在享受 所以没录那么多！ 但是 我们两 更近一步了！！ ',
        imageAsset: 'assets/photos/story/2024/4.jpg',
      ),
    ],
  ),
  const StoryEntry(
    year: '2025',
    title: 'PortDickson 之旅',
    steps: [
      StoryStep(
        sentence: '我的两天一夜成名作w',
        imageAsset: 'assets/photos/story/2025/1.jpg',
      ),
      StoryStep(
        sentence: '黄金黄金 美照美照OwO 快乐快乐www',
        imageAsset: 'assets/photos/story/2025/2.jpg',
      ),
    ],
  ),
];
