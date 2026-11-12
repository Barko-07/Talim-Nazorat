import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';

/// Server qaytargan xato: `code` — mashina uchun (masalan `invalid_code`),
/// `message` — foydalanuvchiga ko'rsatiladigan o'zbekcha matn.
class ApiException implements Exception {
  final int status;
  final String code;
  final String message;

  /// "Kodni qayta yuborish" uchun necha soniya kutish kerakligi (429 javobida).
  final int? retryAfter;

  const ApiException(this.status, this.code, this.message, {this.retryAfter});

  /// Sessiya tugagan yoki bekor qilingan — qayta kirish kerak.
  bool get isUnauthenticated => status == 401 && code == 'unauthenticated';

  @override
  String toString() => message;
}

/// Individ API bilan aloqa. Himoya qoidalari serverdagi bilan bir xil:
/// har bir so'rovda `X-Requested-With`, o'zgartiruvchi so'rovlarda CSRF tokeni.
///
/// Sessiya HttpOnly cookie'da. Brauzerda uni brauzerning o'zi saqlaydi va
/// yuboradi (JavaScript, demak XSS ham, uni o'qiy olmaydi). Telefon ilovasida
/// cookie'ni shu sinf boshqaradi va ilovaning shaxsiy xotirasida saqlaydi —
/// "Eslab qolish" ilova qayta ochilganda ham ishlashi uchun. Muddati serverda
/// tekshiriladi. Telefonda u himoyalangan xotirada (Keystore/Keychain) turadi.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? _defaultBaseUrl).replaceAll(RegExp(r'/+$'), '');

  /// Saytda — o'sha domen (bo'sh). Telefon ilovasida, API_BASE_URL berilmasa,
  /// release ilova asosiy serverga ulanadi (yig'ishda esdan chiqsa ham).
  static String get _defaultBaseUrl =>
      AppConfig.apiBaseUrl.isNotEmpty
          ? AppConfig.apiBaseUrl
          : (kIsWeb || !kReleaseMode ? '' : 'https://individ.uz');

  static ApiClient _instance = ApiClient();

  /// Ilova bo'ylab yagona mijoz (bitta sessiya cookie'si).
  static ApiClient get instance => _instance;

  /// Faqat testlar uchun: ekranlarni soxta server bilan sinash.
  @visibleForTesting
  static set instance(ApiClient client) => _instance = client;

  static const _timeout = Duration(seconds: 20);
  static const _sessionCookiePrefs = 'api_session_cookie';

  final http.Client _client;
  final String _baseUrl;
  String _csrfToken = '';

  /// Faqat telefon/desktop ilovasida ishlatiladi (brauzerda cookie'ni brauzer boshqaradi).
  final Map<String, String> _cookies = {};
  bool _cookiesLoaded = false;

  set csrfToken(String value) => _csrfToken = value;

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) => _send('POST', path, body);

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) =>
      _send('PUT', path, body);

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body);

  /// Javobi ro'yxat bo'lgan so'rovlar uchun (masalan /api/admin/users).
  Future<List<dynamic>> getList(String path) async =>
      (await _send('GET', path))['items'] as List<dynamic>;

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    await _loadCookies();
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers['X-Requested-With'] = 'XMLHttpRequest';
    request.headers['Accept'] = 'application/json';
    if (method != 'GET' && _csrfToken.isNotEmpty) {
      request.headers['X-CSRF-Token'] = _csrfToken;
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (!kIsWeb && _cookies.isNotEmpty) {
      request.headers['Cookie'] = _cookies.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      );
    } on TimeoutException {
      throw const ApiException(
        0,
        'network',
        'Server javob bermadi. Internet aloqasini tekshirib, qayta urinib ko‘ring.',
      );
    } catch (_) {
      throw const ApiException(
        0,
        'network',
        'Internet aloqasi yo‘q. Ulanishni tekshirib, qayta urinib ko‘ring.',
      );
    }

    if (!kIsWeb) await _rememberCookies(response);

    Map<String, dynamic> data = const {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) data = decoded;
        // Ro'yxat qaytaradigan endpoint'lar: {'items': [...]} ko'rinishiga keltiriladi.
        if (decoded is List) data = {'items': decoded};
      } catch (_) {}
    }
    final token = data['csrf_token'];
    if (token is String && token.isNotEmpty) _csrfToken = token;

    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        data['code'] as String? ?? 'error',
        _errorMessage(response.statusCode, data),
        retryAfter: (data['retry_after'] as num?)?.toInt(),
      );
    }
    return data;
  }

  String _errorMessage(int status, Map<String, dynamic> data) {
    final message = data['message'];
    final errors = data['errors'];
    if (status == 422 && errors is List && errors.isNotEmpty) {
      // Maydon xatolari: "email: value is not a valid email address"
      final first = errors.first;
      if (first is Map && first['message'] is String) {
        final text = (first['message'] as String).replaceFirst(
          'Value error, ',
          '',
        );
        return '${message ?? 'Ma’lumotlar noto‘g‘ri'}: $text';
      }
    }
    if (message is String && message.isNotEmpty) return message;
    if (status >= 500) {
      return 'Serverda vaqtinchalik xatolik. Birozdan so‘ng qayta urinib ko‘ring.';
    }
    return 'So‘rov bajarilmadi ($status).';
  }

  // ---------------------------------------------------------------- cookies (mobile/desktop)

  static const _secure = FlutterSecureStorage();

  /// Release ilovada (Play Market) — himoyalangan xotira. Debug va testlarda
  /// oddiy xotira (testlarda himoyalangan xotira plagini yo'q).
  static const _useSecure = kReleaseMode;

  /// Telefonda sessiya himoyalangan xotirada (Android Keystore / iOS Keychain)
  /// turadi. Himoyalangan xotira bo'lmasa (masalan testlarda) — oddiy xotira.
  Future<String?> _readSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_useSecure) return prefs.getString(_sessionCookiePrefs);
    try {
      final v = await _secure.read(key: _sessionCookiePrefs);
      final old = prefs.getString(_sessionCookiePrefs);
      if (v == null && old != null) {
        // Eski versiyadan: oddiy xotiradagini himoyalanganga ko'chiramiz.
        await _secure.write(key: _sessionCookiePrefs, value: old);
        await prefs.remove(_sessionCookiePrefs);
        return old;
      }
      return v;
    } catch (_) {
      return prefs.getString(_sessionCookiePrefs);
    }
  }

  Future<void> _writeSaved(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_useSecure) {
      if (value == null) {
        await prefs.remove(_sessionCookiePrefs);
      } else {
        await prefs.setString(_sessionCookiePrefs, value);
      }
      return;
    }
    try {
      if (value == null) {
        await _secure.delete(key: _sessionCookiePrefs);
      } else {
        await _secure.write(key: _sessionCookiePrefs, value: value);
      }
      await prefs.remove(_sessionCookiePrefs);
    } catch (_) {
      if (value == null) {
        await prefs.remove(_sessionCookiePrefs);
      } else {
        await prefs.setString(_sessionCookiePrefs, value);
      }
    }
  }

  Future<void> _loadCookies() async {
    if (kIsWeb || _cookiesLoaded) return;
    _cookiesLoaded = true;
    final saved = await _readSaved();
    final eq = saved?.indexOf('=') ?? -1;
    if (saved != null && eq > 0) {
      _cookies[saved.substring(0, eq)] = saved.substring(eq + 1);
    }
  }

  Future<void> _rememberCookies(http.Response response) async {
    final raw = response.headers['set-cookie'];
    if (raw == null) return;
    // http paketi bir nechta Set-Cookie'ni vergul bilan qo'shib beradi; Expires
    // sanasidagi vergul bilan adashmaslik uchun faqat "nom=" boshlanishida bo'lamiz.
    for (final cookie in raw.split(RegExp(r',(?=\s*[A-Za-z0-9_-]+=)'))) {
      final parts = cookie.split(';');
      final eq = parts.first.indexOf('=');
      if (eq <= 0) continue;
      final name = parts.first.substring(0, eq).trim();
      final value = parts.first.substring(eq + 1).trim();
      final attrs = parts.skip(1).map((p) => p.trim().toLowerCase());
      final deleted =
          value.isEmpty ||
          attrs.any((a) => a == 'max-age=0' || a.startsWith('max-age=-'));
      if (deleted) {
        _cookies.remove(name);
      } else {
        _cookies[name] = value;
      }
      if (name.endsWith('individ_session')) {
        await _writeSaved(deleted ? null : '$name=$value');
      }
    }
  }

  /// Tizimdan chiqqanda: sessiya cookie'si va CSRF tokeni unutiladi.
  Future<void> clearSession() async {
    _csrfToken = '';
    _cookies.clear();
    if (!kIsWeb) await _writeSaved(null);
  }
}
