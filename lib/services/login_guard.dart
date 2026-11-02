import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Parolni tanlab topishdan himoya.
///
/// - [maxFailures] ta noto'g'ri urinish [window] ichida bo'lsa — login bloklanadi.
/// - Har bir keyingi bloklash ikki barobar uzoq: 15 → 30 → 60 daqiqa ... [maxLock] gacha
///   (qurilma soatini oldinga surib chetlab o'tish amalda foydasiz bo'ladi).
/// - Soat orqaga surilsa (oxirgi qayddan oldingi vaqt) — login bloklangan hisoblanadi.
/// - Hisoblagich login nomi bo'yicha ham, hisob bo'yicha ham yuritiladi ([accountKey]):
///   telefon va pochta bilan navbatma-navbat urinish cheklovni ikki barobar oshirmaydi.
/// - Hisoblagich qurilmada saqlanadi — ilovani qayta ishga tushirish uni nolga tushirmaydi.
class LoginGuard {
  static const int maxFailures = 5;
  static const Duration window = Duration(minutes: 15);
  static const Duration lockDuration = Duration(minutes: 15);
  static const Duration maxLock = Duration(hours: 24);

  /// Bloklashlar seriyasi shu vaqt davomida xatosiz o'tsa — qayta boshlanadi
  static const Duration lockMemory = Duration(days: 1);
  static const _prefsKey = 'auth_login_attempts';
  static const _accountPrefix = '#account:';

  /// Hisob bo'yicha hisoblagich kaliti
  static String accountKey(String userId) => '$_accountPrefix$userId';

  /// Loginni bir xil ko'rinishga keltirish: pochta — kichik harf, telefon — oxirgi 9 raqam
  static String normalize(String identifier) {
    if (identifier.startsWith(_accountPrefix)) return identifier;
    final id = identifier.trim().toLowerCase();
    if (id.contains('@')) return id;
    final digits = id.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 9 ? digits.substring(digits.length - 9) : id;
  }

  /// Jurnal uchun yashirilgan login: "ps***@talim.uz", "***4567"
  static String mask(String identifier) {
    final id = identifier.trim();
    final at = id.indexOf('@');
    if (at > 0) {
      final name = id.substring(0, at);
      return '${name.substring(0, name.length < 2 ? name.length : 2)}***${id.substring(at)}';
    }
    final digits = id.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 4 ? '***${digits.substring(digits.length - 4)}' : '***';
  }

  /// [lockCount]-chi bloklash davomiyligi
  static Duration lockFor(int lockCount) {
    final minutes = lockDuration.inMinutes * pow(2, max(0, lockCount - 1));
    return Duration(minutes: min(minutes.toInt(), maxLock.inMinutes));
  }

  Future<Map<String, dynamic>> _load(SharedPreferences prefs) async {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(prefs.getString(_prefsKey) ?? '{}') as Map,
      );
    } catch (_) {
      return {};
    }
  }

  /// Saqlashdan oldin eskirgan yozuvlar olib tashlanadi (ro'yxat cheksiz o'smasin)
  Future<void> _save(SharedPreferences prefs, Map<String, dynamic> data, DateTime now) {
    data.removeWhere((_, v) {
      final e = v as Map;
      final last = DateTime.tryParse(e['lastAt'] as String? ?? '');
      final until = DateTime.tryParse(e['lockedUntil'] as String? ?? '');
      final active = until != null && until.isAfter(now);
      return !active && (last == null || now.difference(last) > lockMemory);
    });
    return prefs.setString(_prefsKey, jsonEncode(data));
  }

  /// Login bloklangan bo'lsa — qolgan vaqt, aks holda null
  Future<Duration?> lockRemaining(String identifier, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = (await _load(prefs))[normalize(identifier)] as Map?;
    if (entry == null) return null;
    final t = now ?? DateTime.now();
    final last = DateTime.tryParse(entry['lastAt'] as String? ?? '');
    final until = DateTime.tryParse(entry['lockedUntil'] as String? ?? '');
    // Soat oxirgi qayddan orqaga surilgan — bloklash davom etadi
    if (until != null && last != null && t.isBefore(last.subtract(const Duration(minutes: 5)))) {
      return until.difference(last);
    }
    if (until == null || !until.isAfter(t)) return null;
    return until.difference(t);
  }

  /// Noto'g'ri urinishni qayd etadi. true — shu urinish bilan login bloklandi.
  Future<bool> registerFailure(String identifier, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final data = await _load(prefs);
    final key = normalize(identifier);
    final entry = Map<String, dynamic>.from(data[key] as Map? ?? {});

    final last = DateTime.tryParse(entry['lastAt'] as String? ?? '');
    var lockCount = (entry['lockCount'] as num?)?.toInt() ?? 0;
    if (last != null && t.difference(last) > lockMemory) lockCount = 0;

    final failures = ((entry['failures'] as List?) ?? const [])
        .map((e) => DateTime.tryParse(e.toString()))
        .whereType<DateTime>()
        .where((d) => t.difference(d) < window && !d.isAfter(t))
        .toList()
      ..add(t);

    var locked = false;
    if (failures.length >= maxFailures) {
      lockCount += 1;
      entry['lockedUntil'] = t.add(lockFor(lockCount)).toIso8601String();
      failures.clear();
      locked = true;
    }
    entry['lockCount'] = lockCount;
    entry['lastAt'] = t.toIso8601String();
    entry['failures'] = failures.map((d) => d.toIso8601String()).toList();
    data[key] = entry;
    await _save(prefs, data, t);
    return locked;
  }

  /// Muvaffaqiyatli kirishdan keyin hisoblagich tozalanadi
  Future<void> registerSuccess(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    final data = await _load(prefs)..remove(normalize(identifier));
    await _save(prefs, data, DateTime.now());
  }
}
