/// Phone messages and the hand-drawn clue for the birthday hunt.
abstract final class TreasureHuntConfig {
  static const voiceAssets = [
    'music/voice1_mysterious_clear.wav',
    'music/voice2_gift_clue_clear.wav',
  ];
  static const locationPhoto = 'assets/music/hunt_location.png';
  static const birthdaySong = 'audio/birthday_classical.mp3';
  static const finalQrCode = 'SOSAD-GIFT-FINALE';

  static bool acceptsQr(String? value) => value?.trim() == finalQrCode;
}
