class GameMusicTrack {
  const GameMusicTrack(this.asset, this.title, this.source);
  final String asset;
  final String title;
  final String source;
  String get credit =>
      '$title\nKevin MacLeod (incompetech.com)\n\nCreative Commons Attribution 4.0\nhttps://creativecommons.org/licenses/by/4.0/\n\n$source\n\n原始录音未剪辑，循环播放。';
}

abstract final class GameMusicConfig {
  static const tracks = [
    GameMusicTrack(
      'music/game1_carefree.mp3',
      'Carefree',
      'https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1400037',
    ),
    GameMusicTrack(
      'music/game2_sneaky_snitch.mp3',
      'Sneaky Snitch',
      'https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100772',
    ),
    GameMusicTrack(
      'music/game3_investigations.mp3',
      'Investigations',
      'https://incompetech.com/music/royalty-free/mp3-royaltyfree/Investigations.mp3',
    ),
    GameMusicTrack(
      'music/game4_monkeys.mp3',
      'Monkeys Spinning Monkeys',
      'https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1400011',
    ),
  ];
  static GameMusicTrack? forAsset(String? asset) {
    for (final track in tracks) {
      if (track.asset == asset) return track;
    }
    return null;
  }
}
