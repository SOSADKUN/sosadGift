import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/config/game_music_config.dart';
import 'package:gift/config/treasure_hunt_config.dart';

void main() {
  test(
    'four games select distinct downloaded MP3 recordings with attribution',
    () {
      expect(GameMusicConfig.tracks.map((t) => t.asset).toSet().length, 4);
      for (final track in GameMusicConfig.tracks) {
        final bytes = File('assets/${track.asset}').readAsBytesSync();
        expect(bytes.length, greaterThan(100000));
        expect(
          String.fromCharCodes(bytes.take(3)) == 'ID3' || bytes.first == 0xff,
          isTrue,
        );
        expect(track.credit, contains('Kevin MacLeod'));
        expect(
          track.credit,
          contains('https://creativecommons.org/licenses/by/4.0/'),
        );
        expect(GameMusicConfig.forAsset(track.asset), same(track));
      }
    },
  );
  test(
    'phone selects clear speech recordings without the five-second music tail',
    () {
      for (final path in TreasureHuntConfig.voiceAssets) {
        expect(path, endsWith('_clear.wav'));
        final bytes = File('assets/$path').readAsBytesSync();
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
        // Mono 22.05kHz 16-bit speech: both newly rendered messages are under 6s.
        expect(bytes.length, lessThan(22050 * 2 * 6 + 10000));
        expect(bytes.length, greaterThan(100000));
      }
    },
  );
}
