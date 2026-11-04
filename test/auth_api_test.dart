import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/services/api_client.dart';
import 'package:talim_nazorat/services/auth_api.dart';

Map<String, dynamic> _user({String role = 'PSYCHOLOGIST'}) => {
  'id': 'u1',
  'email': 'dilnoza@maktab.uz',
  'full_name': 'Karimova Dilnoza',
  'role': role,
  'institution_id': null,
  'phone': '+998901112233',
  'mfa_enabled': false,
  'can_stay_signed_in': role != 'SUPER_ADMIN',
  'profile': {
    'institution_name': '14-sonli maktab',
    'district': 'Chortoq tumani',
    'experience_years': 4,
  },
};

http.Response _json(int status, Map<String, dynamic> body, {Map<String, String>? headers}) =>
    http.Response(jsonEncode(body), status, headers: {
      'content-type': 'application/json',
      ...?headers,
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('teacher login with "Eslab qolish" is complete in one step', () async {
    late http.Request sent;
    final client = MockClient((req) async {
      sent = req;
      return _json(200, {
        'state': 'ok',
        'csrf_token': 'tok-1',
        'remembered': true,
        'user': _user(),
      });
    });
    final api = AuthApi(ApiClient(client: client, baseUrl: 'https://individ.uz'));

    final r = await api.login('dilnoza@maktab.uz', 'Kuchli-Tog-Yoli-2026', remember: true);
    expect(r.step, AuthStep.ok);
    expect(r.remembered, isTrue);
    expect(r.canStaySignedIn, isTrue);
    expect(r.user.role, UserRole.psychologist);
    expect(r.user.institutionName, '14-sonli maktab');
    expect(r.user.experienceYears, 4);
    expect(r.user.password, isNull);
    expect(sent.headers['X-Requested-With'], 'XMLHttpRequest');
    expect(jsonDecode(sent.body), {
      'email': 'dilnoza@maktab.uz',
      'password': 'Kuchli-Tog-Yoli-2026',
      'remember': true,
    });
  });

  test('admin login asks for the emailed code; the CSRF token is reused', () async {
    final seen = <http.BaseRequest>[];
    final client = MockClient((req) async {
      seen.add(req);
      if (req.url.path == '/api/auth/login') {
        return _json(200, {
          'state': 'email_code_required',
          'csrf_token': 'tok-1',
          'resend_after': 60,
          'user': _user(role: 'SUPER_ADMIN'),
        });
      }
      return _json(200, {
        'state': 'ok',
        'csrf_token': 'tok-2',
        'user': _user(role: 'SUPER_ADMIN'),
      });
    });
    final api = AuthApi(ApiClient(client: client, baseUrl: 'https://individ.uz'));

    final r = await api.login('boss@maktab.uz', 'Kuchli-Tog-Yoli-2026');
    expect(r.step, AuthStep.emailCode);
    expect(r.resendAfter, 60);
    expect(r.canStaySignedIn, isFalse);

    final done = await api.verifyEmailCode('123456');
    expect(done.step, AuthStep.ok);
    expect(seen.last.headers['X-CSRF-Token'], 'tok-1'); // token from the previous answer
    expect(jsonDecode((seen.last as http.Request).body), {'code': '123456'});
  });

  test('server errors become readable ApiExceptions with retry_after', () async {
    final client = MockClient(
      (_) async => _json(429, {
        'code': 'resend_too_soon',
        'message': 'Kodni 42 soniyadan keyin qayta so‘rashingiz mumkin',
        'retry_after': 42,
      }),
    );
    final api = AuthApi(ApiClient(client: client, baseUrl: 'https://individ.uz'));
    await expectLater(
      api.resendEmailCode(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.retryAfter, 'retryAfter', 42)
            .having((e) => e.message, 'message', contains('42 soniya')),
      ),
    );
  });

  test('a network failure is reported in Uzbek, not as a crash', () async {
    final client = MockClient((_) async => throw http.ClientException('offline'));
    final api = AuthApi(ApiClient(client: client, baseUrl: 'https://individ.uz'));
    await expectLater(
      api.login('a@b.uz', 'x'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'network')),
    );
  });

  test('mobile: the session cookie is kept across app restarts until logout', () async {
    final cookiesSent = <String?>[];
    MockClient server() => MockClient((req) async {
      cookiesSent.add(req.headers['Cookie']);
      if (req.url.path == '/api/auth/logout') {
        return _json(200, {'ok': true}, headers: {
          'set-cookie': 'individ_session=""; Max-Age=0; Path=/',
        });
      }
      return _json(
        200,
        {'state': 'ok', 'csrf_token': 't', 'remembered': true, 'user': _user()},
        headers: {
          'set-cookie':
              'individ_session=S1; expires=Wed, 04 Dec 2026 10:00:00 GMT; Max-Age=2592000; HttpOnly; Path=/',
        },
      );
    });

    await AuthApi(ApiClient(client: server(), baseUrl: 'https://individ.uz'))
        .login('dilnoza@maktab.uz', 'p', remember: true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('api_session_cookie'), 'individ_session=S1');

    // The app is closed and opened again: a fresh client finds the saved session.
    final reopened = AuthApi(ApiClient(client: server(), baseUrl: 'https://individ.uz'));
    await reopened.me();
    expect(cookiesSent[1], 'individ_session=S1');

    await reopened.logout();
    expect(prefs.getString('api_session_cookie'), isNull);
  });
}
