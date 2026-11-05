// Server rejimi: ma'lumot faqat serverda. Bu fayl alohida ishga tushiriladi:
//   flutter test --dart-define=SERVER_MODE=true test/server_sync_test.dart
// (oddiy `flutter test` da o'tkazib yuboriladi).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talim_nazorat/core/config/app_config.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/services/api_client.dart';
import 'package:talim_nazorat/services/app_exceptions.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/records_api.dart';

final _inst = 'a' * 32;
final _adminId = 'b' * 32;

/// Soxta server: /api/records, /api/records/batch, /api/directory.
class _FakeServer {
  final Map<String, Map<String, Map<String, dynamic>>> store = {};
  final batches = <List<Map<String, dynamic>>>[];
  bool refuse = false;

  http.Client get client => MockClient((req) async {
    final path = req.url.path;
    if (path == '/api/records') {
      return _json({
        'items': {
          for (final e in store.entries) e.key: e.value.values.toList(),
        },
      });
    }
    if (path == '/api/directory') {
      return _json([
        {
          'id': _adminId,
          'full_name': 'Direktor',
          'role': 'INSTITUTION_ADMIN',
          'institution_id': _inst,
        },
      ]);
    }
    if (path == '/api/records/batch') {
      if (refuse) {
        return _json({
          'code': 'forbidden',
          'message': 'Bu amal uchun ruxsatingiz yo‘q',
        }, 403);
      }
      final ops =
          ((jsonDecode(req.body) as Map)['ops'] as List)
              .cast<Map<String, dynamic>>();
      batches.add(ops);
      final out = [];
      for (final op in ops) {
        final kind = op['kind'] as String;
        final id = op['id'] as String;
        if (op['op'] == 'delete') {
          store[kind]?.remove(id);
          continue;
        }
        final data = Map<String, dynamic>.from(op['data'] as Map)..['id'] = id;
        if (kind == 'student') {
          data['institutionId'] = _inst; // the server decides the school
        }
        store.putIfAbsent(kind, () => {})[id] = data;
        out.add({'kind': kind, 'data': data});
      }
      return _json({'items': out});
    }
    return _json({'code': 'not_found', 'message': 'Topilmadi'}, 404);
  });

  static http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

StudentModel _child(String id) => StudentModel(
  id: id,
  institutionId: _inst,
  institutionName: '1-maktab',
  firstName: 'Ali',
  lastName: 'Valiyev',
  dateOfBirth: DateTime(2016),
  gender: 'Erkak',
  grade: '3-A',
  status: 'Faol',
  primaryNeed: 'x',
  supportLevel: '1-daraja',
  createdAt: DateTime(2026, 11, 5),
);

final _admin = UserModel(
  id: _adminId,
  email: 'dir@maktab.uz',
  fullName: 'Direktor',
  role: UserRole.institutionAdmin,
  institutionId: _inst,
);

void main() {
  if (!AppConfig.serverMode) {
    test(
      'server mode tests',
      () {},
      skip: 'run with --dart-define=SERVER_MODE=true',
    );
    return;
  }

  late _FakeServer server;
  late LocalDbService db;

  Future<void> start([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    server = _FakeServer();
    db =
        LocalDbService()
          ..recordsApi = RecordsApi(
            ApiClient(client: server.client, baseUrl: 'https://individ.uz'),
          )
          ..resetForTest();
    await db.init();
  }

  test('nothing from earlier versions stays on the device', () async {
    await start({
      'db_students': jsonEncode([_child('old').toJson()]),
      'app_db_seeded_v2': true,
    });
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('db_')), isEmpty);
    expect(db.getStudents(), isEmpty);
  });

  test('a new child goes to the server, never to the device', () async {
    await start();
    await db.loadFromServer();
    db.cacheSignedInUser(_admin);
    await db.addStudent(_child('s1'), byUser: _admin);

    expect(server.batches.single.single['kind'], 'student');
    expect(server.store['student']!.keys, ['s1']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('db_')), isEmpty);
    // Built-in methodology content is never uploaded.
    expect(server.store.keys, ['student']);
  });

  test('a refused save is undone on screen and reported', () async {
    await start();
    await db.loadFromServer();
    db.cacheSignedInUser(_admin);
    server.refuse = true;
    await expectLater(
      db.addStudent(_child('s2'), byUser: _admin),
      throwsA(isA<StorageWriteException>()),
    );
    expect(db.getStudents(), isEmpty);
  });

  test('sign-out wipes everything that was loaded', () async {
    await start();
    server.store['student'] = {'s1': _child('s1').toJson()};
    await db.loadFromServer();
    expect(db.getStudents().map((s) => s.id), ['s1']);
    db.clearServerData();
    expect(db.getStudents(), isEmpty);
    expect(db.isServerDataLoaded, isFalse);
  });

  test('nothing is sent before sign-in', () async {
    await start();
    // Not loaded yet: a save attempt must not reach the server.
    db.cacheSignedInUser(_admin);
    await db.addStudent(_child('s3'), byUser: _admin);
    expect(server.batches, isEmpty);
  });
}
