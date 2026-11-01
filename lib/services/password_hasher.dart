import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Parollarni PBKDF2-HMAC-SHA256 orqali xeshlash.
/// Saqlash formati: `pbkdf2$<iteratsiya>$<salt base64>$<xesh base64>`
class PasswordHasher {
  static const _prefix = 'pbkdf2';
  static const _iterations = 20000;
  static const _saltLength = 16;
  static const _keyLength = 32;

  /// Saqlangan qiymat xeshlangan formatdami?
  static bool isHashed(String? stored) =>
      stored != null && stored.startsWith('$_prefix\$');

  static String hash(String password) {
    final rnd = Random.secure();
    final salt = Uint8List.fromList(
      List.generate(_saltLength, (_) => rnd.nextInt(256)),
    );
    final key = _pbkdf2(utf8.encode(password), salt, _iterations, _keyLength);
    return '$_prefix\$$_iterations\$${base64Encode(salt)}\$${base64Encode(key)}';
  }

  /// Yangi xodim uchun tasodifiy vaqtinchalik parol (o'xshash belgilarsiz)
  static String generateTemporary({int length = 10}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  static bool verify(String password, String? stored) {
    if (!isHashed(stored)) return false;
    final parts = stored!.split('\$');
    if (parts.length != 4) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;
    final salt = base64Decode(parts[2]);
    final expected = base64Decode(parts[3]);
    final actual = _pbkdf2(
      utf8.encode(password),
      salt,
      iterations,
      expected.length,
    );
    return _constantTimeEquals(actual, expected);
  }

  static Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final out = BytesBuilder();
    var block = 1;
    while (out.length < keyLength) {
      final blockIndex = ByteData(4)..setUint32(0, block);
      var u = hmac.convert([...salt, ...blockIndex.buffer.asUint8List()]).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.add(t);
      block++;
    }
    return Uint8List.fromList(out.toBytes().sublist(0, keyLength));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
