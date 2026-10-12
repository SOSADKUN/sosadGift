/// Replace these assets with the recording and location photo for the real hunt.
abstract final class TreasureHuntConfig {
  static const voiceAssets = [
    'music/voice1_mystery.wav',
    'music/voice2_mystery.wav',
  ];
  static const locationPhoto = 'assets/music/hunt_location.jpg';
  static const birthdaySong = 'audio/birthday_instrumental.wav';
  static const finalQrCode = 'SOSAD-GIFT-FINALE';

  static bool acceptsQr(String? value) => value?.trim() == finalQrCode;
}
