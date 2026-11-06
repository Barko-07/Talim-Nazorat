import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talim_nazorat/core/theme/app_theme.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/screens/admin/server/server_history_tab.dart';
import 'package:talim_nazorat/screens/admin/server/server_institutions_tab.dart';
import 'package:talim_nazorat/screens/admin/server/server_users_tab.dart';
import 'package:talim_nazorat/services/admin_api.dart';
import 'package:talim_nazorat/services/api_client.dart';

Map<String, dynamic> _user(
  String id,
  String name, {
  bool pending = false,
  bool active = true,
  String? inst,
}) => {
  'id': id,
  'email': '$id@maktab.uz',
  'full_name': name,
  'role': 'PSYCHOLOGIST',
  'institution_id': inst,
  'is_active': active,
  'mfa_enabled': false,
  'locked': false,
  'must_change_password': false,
  'pending_approval': pending,
  'phone': '+998901112233',
  'profile': {'institution_name': '14-sonli maktab', 'district': 'Chortoq tumani'},
};

final _institutions = [
  {'id': 'i1', 'name': '14-sonli maktab', 'region': 'Namangan', 'users': 2},
  {'id': 'i2', 'name': '9-sonli maktab', 'region': 'Namangan', 'users': 0},
];

/// Fake /api/admin: records every write, answers reads from in-memory lists.
class _FakeAdminServer {
  final users = <Map<String, dynamic>>[
    _user('u1', 'Karimova Dilnoza', pending: true),
    _user('u2', 'Aliyev Bobur', inst: 'i1'),
    _user('u3', 'Qodirova Nodira', inst: 'i1', active: false),
  ];
  final writes = <String>[];

  http.Client get client => MockClient((req) async {
    final path = req.url.path;
    if (req.method != 'GET') {
      writes.add('${req.method} $path ${req.body}');
      expect(req.headers['X-Requested-With'], 'XMLHttpRequest');
    }
    if (path == '/api/admin/users' && req.method == 'GET') return _json(users);
    if (path == '/api/admin/changes') {
      return _json([
        {
          'id': 2,
          'at': '2026-11-05T16:40:00+00:00',
          'action': 'update',
          'kind': 'assessment',
          'record_id': 'a1',
          'student_id': 's1',
          'student_name': 'Valiyev Ali',
          'user_id': 'u2',
          'user_name': 'Aliyev Bobur',
          'fields': ['score'],
          'before': {'score': 7},
          'after': {'score': 9},
        },
        {
          'id': 1,
          'at': '2026-11-05T16:30:00+00:00',
          'action': 'create',
          'kind': 'student',
          'record_id': 's1',
          'student_id': 's1',
          'student_name': 'Valiyev Ali',
          'user_id': 'u2',
          'user_name': 'Aliyev Bobur',
          'fields': ['firstName', 'lastName'],
          'before': null,
          'after': {'firstName': 'Ali', 'lastName': 'Valiyev'},
        },
      ]);
    }
    if (path == '/api/admin/audit') {
      return _json([
        {
          'id': 5,
          'at': '2026-11-05T16:00:00+00:00',
          'action': 'ACCESS_DENIED',
          'severity': 'warning',
          'user_id': 'u2',
          'subject': 's9',
          'ip': '203.0.113.9',
          'detail': 'change student',
        },
      ]);
    }
    if (path == '/api/admin/institutions' && req.method == 'GET') {
      return _json(_institutions);
    }
    final approve = RegExp(r'^/api/admin/users/(\w+)/approve$').firstMatch(path);
    if (approve != null) {
      final u = users.firstWhere((u) => u['id'] == approve[1]);
      u['pending_approval'] = false;
      u['institution_id'] = (jsonDecode(req.body) as Map)['institution_id'];
      return _json(u);
    }
    return _json({'ok': true});
  });

  static http.Response _json(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// Shows the tab; returns a closer that must run at the end of the test
/// (it stops AuthProvider's session timer before the test framework checks).
Future<Future<void> Function()> _pump(
  WidgetTester tester,
  Widget tab, {
  double width = 390,
  double height = 1400,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = AuthProvider();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(theme: AppTheme.current, home: Scaffold(body: tab)),
    ),
  );
  await tester.pumpAndSettle();
  return () async {
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('pending sign-ups are listed first and approval sends the chosen school', (
    tester,
  ) async {
    final server = _FakeAdminServer();
    final api = AdminApi(ApiClient(client: server.client, baseUrl: 'https://individ.uz'));
    final done = await _pump(tester, ServerUsersTab(api: api));

    expect(find.text('Tasdiq kutayotganlar (1)'), findsOneWidget);
    expect(find.text('Karimova Dilnoza'), findsOneWidget);
    expect(find.text('Bloklangan'), findsOneWidget); // u3
    expect(find.textContaining('2 ta hisob'), findsOneWidget);

    await tester.tap(find.text('Tasdiqlash'));
    await tester.pumpAndSettle();
    expect(find.text('Hisobni tasdiqlash'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Tasdiqlash').last);
    await tester.pumpAndSettle();

    expect(server.writes, ['POST /api/admin/users/u1/approve {"institution_id":"i1"}']);
    expect(find.text('Tasdiq kutayotganlar (1)'), findsNothing);
    expect(find.textContaining('3 ta hisob'), findsOneWidget);
    await done();
  });

  testWidgets('search filters accounts by name or email', (tester) async {
    final server = _FakeAdminServer();
    final api = AdminApi(ApiClient(client: server.client, baseUrl: 'https://individ.uz'));
    final done = await _pump(tester, ServerUsersTab(api: api));
    await tester.enterText(find.byType(TextField).first, 'bobur');
    await tester.pump();
    expect(find.text('Aliyev Bobur'), findsOneWidget);
    expect(find.text('Qodirova Nodira'), findsNothing);
    await done();
  });

  testWidgets('a failed load shows the reason and a retry, not a blank screen', (tester) async {
    final api = AdminApi(
      ApiClient(
        client: MockClient((_) async => throw http.ClientException('offline')),
        baseUrl: 'https://individ.uz',
      ),
    );
    final done = await _pump(tester, ServerUsersTab(api: api));
    expect(find.textContaining('Ro‘yxat yuklanmadi'), findsOneWidget);
    expect(find.text('Qayta urinish'), findsOneWidget);
    await done();
  });

  testWidgets('history shows who changed what, with the old and new value', (
    tester,
  ) async {
    final api = AdminApi(
      ApiClient(client: _FakeAdminServer().client, baseUrl: 'https://individ.uz'),
    );
    final done = await _pump(tester, ServerHistoryTab(api: api));
    expect(find.text('Valiyev Ali · Baholash'), findsOneWidget);
    expect(find.text('O‘zgartirildi'), findsOneWidget);
    expect(find.text('Qo‘shildi'), findsOneWidget);
    await tester.tap(find.text('Valiyev Ali · Baholash'));
    await tester.pumpAndSettle();
    expect(find.text('score'), findsOneWidget);
    expect(find.textContaining('→'), findsOneWidget);

    await tester.tap(find.text('Xavfsizlik'));
    await tester.pumpAndSettle();
    expect(find.text('ACCESS_DENIED'), findsOneWidget);
    expect(find.text('Ogohlantirish'), findsWidgets);
    await done();
  });

  for (final width in [375.0, 1280.0]) {
    testWidgets('admin server tabs fit at ${width.toInt()}px', (tester) async {
      final server = _FakeAdminServer();
      final api = AdminApi(ApiClient(client: server.client, baseUrl: 'https://individ.uz'));
      var done = await _pump(tester, ServerUsersTab(api: api), width: width, height: 844);
      expect(tester.takeException(), isNull);
      await done();
      done = await _pump(tester, ServerInstitutionsTab(api: api, canAdd: true), width: width, height: 844);
      expect(tester.takeException(), isNull);
      expect(find.text('2 ta hisob'), findsOneWidget);
      await done();
      done = await _pump(tester, ServerHistoryTab(api: api), width: width, height: 844);
      expect(tester.takeException(), isNull);
      await done();
    });
  }
}
