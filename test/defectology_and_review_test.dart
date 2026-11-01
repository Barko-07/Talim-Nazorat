import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/defectology_methods_data.dart';
import 'package:talim_nazorat/core/constants/method_library.dart';
import 'package:talim_nazorat/core/constants/psychological_methods_data.dart';
import 'package:talim_nazorat/core/constants/specialist_workspaces.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/providers/app_provider.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/password_hasher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final db = LocalDbService();

  Future<void> freshDb([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    db.resetForTest();
    await db.init();
  }

  group('Defectologist methods library', () {
    const methods = DefectologyMethodsData.methods;

    test('six complete methods, all for defectology, none needing a licence', () {
      expect(methods, hasLength(6));
      for (final m in methods) {
        expect(m.profession, MethodProfession.defectology, reason: m.code);
        expect(m.requiresLicensedMaterials, false, reason: m.code);
        expect(m.title.isNotEmpty && m.instructions.isNotEmpty && m.purpose.isNotEmpty, true);
        expect(m.subscales, isNotEmpty, reason: m.code);
        expect(m.scoringGuide.isNotEmpty, true, reason: m.code);
        expect(m.maxScore, greaterThan(0), reason: m.code);
      }
    });

    test('method ids and codes are unique across the whole library', () {
      final ids = MethodLibrary.all.map((m) => m.id).toList();
      final codes = MethodLibrary.all.map((m) => m.code).toList();
      expect(ids.length, ids.toSet().length);
      expect(codes.length, codes.toSet().length);
    });

    test('every method belongs to one of the defectologist\'s assessment areas', () {
      final domains = SpecialistWorkspaces.forRole(UserRole.specialEducation).assessmentDomains;
      for (final m in methods) {
        expect(domains, contains(m.domain), reason: m.code);
      }
    });

    test('interpretation compares the child with themselves, not with labels', () {
      for (final m in methods) {
        expect(m.normCriteria, contains('o‘z oldingi natijasi'), reason: m.code);
      }
    });

    test('each specialist sees their own library; leadership sees all', () {
      expect(MethodLibrary.forRole(UserRole.specialEducation), DefectologyMethodsData.methods);
      expect(MethodLibrary.forRole(UserRole.psychologist), PsychologicalMethodsData.methods);
      expect(MethodLibrary.forRole(UserRole.coordinator).length, MethodLibrary.all.length);
      expect(MethodLibrary.forRole(UserRole.parent), isEmpty);
      expect(MethodLibrary.byId('method_seguin_board')?.code, 'SEGUIN_BOARD');
    });
  });

  group('Licensed psychological tests', () {
    test('exactly the copyrighted tests are flagged and carry no copied norms or labels', () {
      final flagged = PsychologicalMethodsData.methods
          .where((m) => m.requiresLicensedMaterials)
          .map((m) => m.code)
          .toSet();
      expect(flagged, {'RAVEN_CPM', 'WISC_COGNITIVE', 'CATTELL_CPQ', 'YASYUKOVA_PRIMARY'});
      for (final m in PsychologicalMethodsData.methods.where((m) => m.requiresLicensedMaterials)) {
        expect(m.licenseNote, isNotNull);
        expect(m.normCriteria, isNot(contains('Yuqori intellekt')));
        expect(m.normCriteria, contains('litsenziyalangan'));
      }
    });
  });

  group('Review fixes', () {
    test('one damaged student record no longer hides all other students', () async {
      await freshDb();
      final good = db.getStudents().map((s) => s.toJson()).toList();
      final damaged = [
        ...good,
        {'id': 'broken_row', 'firstName': 'Faqat ism'}, // majburiy maydonlar yo'q
      ];
      await freshDb({'app_db_seeded_v2': true, 'db_students': jsonEncode(damaged)});

      expect(db.getStudents().length, good.length);
      expect(db.loadErrors, isEmpty); // jadval yozish uchun ochiq
      expect(db.rejectedRowCounts['db_students'], 1);
      final prefs = await SharedPreferences.getInstance();
      final backup = jsonDecode(prefs.getString('db_students_rejected_rows')!) as List;
      expect((backup.single as Map)['id'], 'broken_row');
    });

    test('nothing is visible through the provider when nobody is logged in', () async {
      await freshDb();
      final app = AppProvider();
      app.setCurrentUser(null);
      expect(app.students, isEmpty);
      expect(app.allUsers, isEmpty);
      expect(app.auditLogs, isEmpty);
      expect(app.observations, isEmpty);
      expect(app.referrals, isEmpty);
      expect(app.alerts, isEmpty);
    });

    test('failed self-registration returns an error instead of a stuck loader', () async {
      await freshDb();
      final auth = AuthProvider();
      final result = await auth.register(
        firstName: 'X', lastName: 'Y', phone: '+998 99 555-55-55', email: 'x.y@talim.uz',
        role: UserRole.coordinator, // o'zi ro'yxatdan o'ta olmaydigan rol
        specialization: 'x', qualificationCategory: 'x', institutionName: 'x', password: 'Parol123',
      );
      expect(result['success'], false);
      expect(result['message'].toString(), contains('Ruxsat cheklangan'));
      expect(auth.isLoading, false);
      expect(auth.isAuthenticated, false);
    });

    test('the logged-in user never holds a plain-text password in memory', () async {
      await freshDb();
      final auth = AuthProvider();
      await auth.register(
        firstName: 'Test', lastName: 'Psixolog', phone: '+998 99 777-77-77', email: 'mem.psy@talim.uz',
        role: UserRole.psychologist, specialization: 'Psixolog', qualificationCategory: 'Oliy',
        institutionName: '5-sonli umumiy o‘rta ta’lim maktabi', password: 'FirstPass1',
      );
      expect(PasswordHasher.isHashed(auth.currentUser!.password), true);
      await auth.changePassword('FirstPass1', 'SecondPass2');
      expect(PasswordHasher.isHashed(auth.currentUser!.password), true);
      expect(auth.currentUser!.password, isNot('SecondPass2'));
    });

    test('audit entries are still saved after the write optimisation', () async {
      await freshDb();
      await db.addAuditLog(
        userFullName: 'Tekshiruv', userRole: 'x', action: 'TEST', entity: 'Test', details: 'saqlanishi kerak',
      );
      db.resetForTest();
      await db.init();
      expect(db.getAuditLogs().any((l) => l.details == 'saqlanishi kerak'), true);
    });
  });
}
