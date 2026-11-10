import 'dart:convert';

/// Kirish sessiyasi. Ma'lum vaqt faollik bo'lmasa yoki umumiy muddat tugasa —
/// qayta kirish talab qilinadi (bolalarning maxfiy ma'lumotlari ochiq qolib ketmasin).
class AuthSession {
  /// Faolliksiz shu vaqt o'tsa sessiya tugaydi
  static const Duration idleTimeout = Duration(hours: 2);

  /// Faollikdan qat'i nazar, sessiyaning eng uzoq muddati (bir ish kuni)
  static const Duration maxAge = Duration(hours: 12);

  static const prefsKey = 'auth_session';

  final String userId;
  final DateTime issuedAt;
  final DateTime lastActive;

  const AuthSession({
    required this.userId,
    required this.issuedAt,
    required this.lastActive,
  });

  factory AuthSession.start(String userId, {DateTime? now}) {
    final t = now ?? DateTime.now();
    return AuthSession(userId: userId, issuedAt: t, lastActive: t);
  }

  bool isValid({DateTime? now}) {
    final t = now ?? DateTime.now();
    if (lastActive.isAfter(t.add(const Duration(minutes: 5)))) {
      return false; // soat orqaga surilgan
    }
    return t.difference(lastActive) < idleTimeout &&
        t.difference(issuedAt) < maxAge;
  }

  AuthSession touched({DateTime? now}) => AuthSession(
    userId: userId,
    issuedAt: issuedAt,
    lastActive: now ?? DateTime.now(),
  );

  String encode() => jsonEncode({
    'userId': userId,
    'issuedAt': issuedAt.toIso8601String(),
    'lastActive': lastActive.toIso8601String(),
  });

  static AuthSession? decode(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession(
        userId: m['userId'] as String,
        issuedAt: DateTime.parse(m['issuedAt'] as String),
        lastActive: DateTime.parse(m['lastActive'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}
