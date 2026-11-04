import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

abstract final class AppUnlockPolicy {
  // 2026-11-07 23:30 in Malaysia (UTC+08:00), independent of device timezone.
  static final unlockAt = DateTime.utc(2026, 11, 7, 15, 30);
  static bool isOpen(DateTime now) => !now.toUtc().isBefore(unlockAt);

  static const _iterations = 210000;
  static const _salt = '8fff411a6f73ae86ed6573ed9976211d17d20e6313a93e49';
  static const _hash =
      '60ac8256fbea3c09e9b0a744c97c0451489d36aa2ed267c89badcc3bfb5728a9';

  static Future<bool> verifyAdminPassword(String password) =>
      compute(_verify, password);

  static bool _verify(String password) {
    final salt = List<int>.generate(
      _salt.length ~/ 2,
      (i) => int.parse(_salt.substring(i * 2, i * 2 + 2), radix: 16),
    );
    final actual = deriveKey(password, salt, _iterations);
    final expected = List<int>.generate(
      _hash.length ~/ 2,
      (i) => int.parse(_hash.substring(i * 2, i * 2 + 2), radix: 16),
    );
    var difference = 0;
    for (var i = 0; i < expected.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    return difference == 0;
  }

  /// PBKDF2-HMAC-SHA256, one 32-byte block (RFC 8018 section 5.2).
  @visibleForTesting
  static List<int> deriveKey(String password, List<int> salt, int iterations) {
    assert(iterations > 0);
    final hmac = Hmac(sha256, utf8.encode(password));
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(u);
    for (var iteration = 1; iteration < iterations; iteration++) {
      u = hmac.convert(u).bytes;
      for (var i = 0; i < result.length; i++) {
        result[i] ^= u[i];
      }
    }
    return result;
  }
}
