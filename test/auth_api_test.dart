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
  'can_remember_device': true,
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

  test('login maps the server state and user; headers carry CSRF protections', () async {
    final seen = <http.BaseRequest>[];
    final client = MockClient((req) async {
      seen.add(req);
      if (req.url.path == '/api/auth/login') {
        return _json(200, {
          'state': 'email_code_required',
          'csrf_token': 'tok-1',
          'resend_after': 60,
          'user': _user(),
        });
      }
      return _json(200, {'state': 'ok', 'csrf_token': 'tok-2', 'user': _user()});
    });
    final api = AuthApi(ApiClient(client: client, baseUrl: 'https://individ.uz'));

    final r = await api.login('dilnoza@maktab.uz', 'Kuchli-Tog-Yoli-2026');
    expect(r.step, AuthStep.emailCode);
    expect(r.resendAfter, 60);
    expect(r.canRememberDevice, isTrue);
    expect(r.user.role, UserRole.psychologist);
    expect(r.user.institutionName, '14-sonli maktab');
    expect(r.user.experienceYears, 4);
    expect(r.user.password, isNull);

    final done = await api.verifyEmailCode('123456', remember: true);
    expect(done.step, AuthStep.ok);
    expect(seen.last.headers['X-Requested-With'], 'XMLHttpRequest');
    expect(seen.last.headers['X-CSRF-Token'], 'tok-1'); // token from the previous answer
    expect(jsonDecode((seen.last as http.Request).body), {
      'code': '123456',
      'remember_device': true,
    });
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

  test('mobile: session cookie is sent back; remembered-device cookie survives logout', () async {
    final cookiesSent = <String?>[];
    final client = MockClient((req) async {
      cookiesSent.add(req.headers['Cookie']);
      switch (req.url.path) {
        case '/api/auth/email-code/verify':
          return _json(
            200,
            {'state': 'ok', 'csrf_token': 't', 'user': _user()},
            headers: {
              'set-cookie':
                  'individ_session=S2; HttpOnly; Path=/; SameSite=strict,individ_device=D1; expires=Wed, 04 Dec 2026 10:00:00 GMT; HttpOnly; Path=/',
            },
          );
        case '/api/auth/logout':
          return _json(200, {'ok': true}, headers: {
            'set-cookie': 'individ_session=""; Max-Age=0; Path=/',
          });
      }
      return _json(200, {'state': 'email_code_required', 'csrf_token': 't', 'user': _user()},
          headers: {'set-cookie': 'individ_session=S1; HttpOnly; Path=/'});
    });
    final api = AuthApi(ApiClient(client: client, baseUrl: 'https://individ.uz'));

    await api.login('dilnoza@maktab.uz', 'p');
    await api.verifyEmailCode('123456', remember: true);
    await api.logout();
    await api.login('dilnoza@maktab.uz', 'p');

    expect(cookiesSent[0], isNull);
    expect(cookiesSent[1], 'individ_session=S1');
    expect(cookiesSent[2], allOf(contains('individ_session=S2'), contains('individ_device=D1')));
    expect(cookiesSent[3], 'individ_device=D1'); // session gone, device remembered
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('api_device_cookie'), 'individ_device=D1');
  });
}
