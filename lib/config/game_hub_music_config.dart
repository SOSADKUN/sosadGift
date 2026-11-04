abstract final class GameHubMusicConfig {
  static const asset = 'music/GameMusic.mp3';
  static const volume = .12;

  // User-confirmed chorus entry in GameMusic.mp3.
  static const chorusStart = Duration(seconds: 16);
  static const fallbackIntroDuration = Duration(seconds: 12);
}
