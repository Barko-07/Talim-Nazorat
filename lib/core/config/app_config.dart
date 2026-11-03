import 'package:flutter/foundation.dart';

import '../../services/password_hasher.dart';

/// Yig'ish (build) vaqtida beriladigan muhit o'zgaruvchilari. Sirlar kodda ham,
/// GitHub'da ham saqlanmaydi — faqat yig'ishda beriladi:
///
/// ```
/// flutter build apk \
///   --dart-define=ADMIN_EMAIL=admin@maktab.uz \
///   --dart-define=ADMIN_PASSWORD_HASH='pbkdf2$...'   # dart run tool/hash_password.dart
/// ```
///
/// Ochiq parol hech qachon berilmaydi — faqat PBKDF2 xeshi.
class AppConfig {
  /// Birinchi tizim administratorining login pochtasi
  static const adminEmail = String.fromEnvironment('ADMIN_EMAIL');

  /// Administrator parolining PBKDF2 xeshi (tool/hash_password.dart bilan olinadi)
  static const adminPasswordHash = String.fromEnvironment(
    'ADMIN_PASSWORD_HASH',
  );

  /// Administrator ismi (ixtiyoriy)
  static const adminFullName = String.fromEnvironment(
    'ADMIN_FULL_NAME',
    defaultValue: 'Tizim administratori',
  );

  /// Kelajakdagi server manzili (HTTPS bo'lishi shart)
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Demo rejimi faqat aniq yoqilganda ishlaydi; release yig‘ilishlarda standart o‘chiq.
  static const demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  static bool get hasAdminBootstrap =>
      adminEmail.isNotEmpty && adminPasswordHash.isNotEmpty;

  /// Sozlamalardagi muammolar ro'yxati (bo'sh — hammasi joyida).
  /// Release yig'ishda tekshiriladi va jurnalga yoziladi.
  static List<String> problems({bool isRelease = kReleaseMode}) {
    final issues = <String>[];
    if (adminEmail.isNotEmpty != adminPasswordHash.isNotEmpty) {
      issues.add('ADMIN_EMAIL va ADMIN_PASSWORD_HASH birga berilishi kerak.');
    }
    if (adminEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(adminEmail)) {
      issues.add('ADMIN_EMAIL noto‘g‘ri formatda.');
    }
    if (adminPasswordHash.isNotEmpty &&
        !PasswordHasher.isHashed(adminPasswordHash)) {
      issues.add(
        'ADMIN_PASSWORD_HASH ochiq parol emas, PBKDF2 xeshi bo‘lishi kerak (tool/hash_password.dart).',
      );
    }
    if (apiBaseUrl.isNotEmpty && !apiBaseUrl.startsWith('https://')) {
      issues.add('API_BASE_URL faqat https:// bilan boshlanishi kerak.');
    }
    if (isRelease && !hasAdminBootstrap) {
      issues.add(
        'Release yig‘ishda administrator sozlanmagan — ADMIN_EMAIL va ADMIN_PASSWORD_HASH bering.',
      );
    }
    return issues;
  }
}
