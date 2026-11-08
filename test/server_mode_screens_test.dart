// Screens in server mode (the build that runs on individ.uz), against a fake
// server. Run with:  flutter test --dart-define=SERVER_MODE=true test/server_mode_screens_test.dart
//
// These guard against screens that look like they work but only change the
// browser's memory - e.g. the "Mutaxassislar" page once "added" staff that
// never reached the server and showed a temporary password that did not work.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talim_nazorat/core/config/app_config.dart';
import 'package:talim_nazorat/core/theme/app_theme.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/providers/app_provider.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/providers/theme_provider.dart';
import 'package:talim_nazorat/screens/specialists/specialists_screen.dart';
import 'package:talim_nazorat/services/api_client.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/records_api.dart';

Map<String, dynamic> _admin() => {
  'id': 'a1',
  'email': 'dir@maktab.uz',
  'full_name': 'Direktor Ali',
  'role': 'INSTITUTION_ADMIN',
  'institution_id': 'i1',
  'phone': null,
  'profile': {'institution_name': '14-sonli maktab'},
  'can_stay_signed_in': false,
};

/// A fake individ.uz: answers sign-in, the work data and the directory, and
/// records every write.
class _FakeServer {
  final writes = <String>[];
  final people = <Map<String, dynamic>>[
    {'id': 'a1', 'full_name': 'Direktor Ali', 'role': 'INSTITUTION_ADMIN', 'institution_id': 'i1'},
  ];

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Client get client => MockClient((req) async {
    final path = req.url.path;
    if (req.method != 'GET') writes.add('${req.method} $path ${req.body}');
    switch (path) {
      case '/api/auth/login':
        return _json({'state': 'ok', 'user': _admin(), 'csrf_token': 't'});
      case '/api/records':
        return _json({'items': <String, dynamic>{}, 'versions': <String, dynamic>{}, 'count': 0});
      case '/api/directory':
        return _json(people);
      case '/api/admin/users':
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        people.add({
          'id': 'n1',
          'full_name': body['full_name'],
          'role': body['role'],
          'institution_id': 'i1',
        });
        return _json({
          'id': 'n1',
          'email': body['email'],
          'full_name': body['full_name'],
          'role': body['role'],
          'institution_id': 'i1',
          'is_active': true,
          'mfa_enabled': false,
          'locked': false,
          'must_change_password': true,
          'pending_approval': false,
          'phone': body['phone'],
          'profile': <String, dynamic>{},
        }, 201);
    }
    return _json({'code': 'not_found', 'message': 'Topilmadi'}, 404);
  });
}

void main() {
  if (!AppConfig.serverMode) {
    test(
      'server mode screen tests',
      () {},
      skip: 'run with --dart-define=SERVER_MODE=true',
    );
    return;
  }

  testWidgets('adding staff on "Mutaxassislar" creates the account on the server', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    SharedPreferences.setMockInitialValues({});
    final server = _FakeServer();
    final api = ApiClient(client: server.client, baseUrl: 'https://individ.uz');
    ApiClient.instance = api;
    LocalDbService()
      ..recordsApi = RecordsApi(api)
      ..resetForTest();

    final auth = AuthProvider();
    final app = AppProvider();
    await tester.runAsync(() async {
      await auth.retryInitialization();
      await auth.login('dir@maktab.uz', 'Parol-2026-Kuchli');
    });
    expect(auth.currentUser?.id, 'a1');
    app.setCurrentUser(auth.currentUser); // main.dart does this on sign-in

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: app),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.current,
          home: const Scaffold(body: SpecialistsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yangi xodim'));
    await tester.pumpAndSettle();
    // School administrators cannot create administrators: not offered.
    await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(DropdownMenuItem<UserRole>, UserRole.institutionAdmin.label),
      findsNothing,
    );
    expect(find.widgetWithText(DropdownMenuItem<UserRole>, UserRole.teacher.label), findsWidgets);
    await tester.tap(find.text(UserRole.teacher.label).last);
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Karimova Dilnoza');
    // Without an email the account is not created (the password goes there).
    await tester.tap(find.text('Qo‘shish'));
    await tester.pumpAndSettle();
    expect(server.writes.where((w) => w.contains('/api/admin/users')), isEmpty);

    await tester.enterText(fields.at(3), 'dilnoza@maktab.uz');
    await tester.runAsync(() async {
      await tester.tap(find.text('Qo‘shish'));
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pumpAndSettle();

    final created = server.writes.where((w) => w.startsWith('POST /api/admin/users')).toList();
    expect(created, hasLength(1));
    expect(created.single, contains('"email":"dilnoza@maktab.uz"'));
    // The password is never shown on screen; it went to the staff member's mailbox.
    expect(find.textContaining('Vaqtinchalik parol:'), findsNothing);
    expect(find.textContaining('dilnoza@maktab.uz manziliga yuborildi'), findsOneWidget);
    // The list now comes from the server and includes the new person.
    expect(find.text('Karimova Dilnoza'), findsWidgets);

    // Let the message expire, then stop the session timer the app runs.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
    ApiClient.instance = ApiClient();
  });
}
