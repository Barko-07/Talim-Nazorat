import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/models/psychologist_observation_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/services/access_control_service.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/password_hasher.dart';
import 'package:talim_nazorat/services/seed_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final db = LocalDbService();

  Future<void> freshDb([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    db.resetForTest();
    await db.init();
  }

  group('PasswordHasher', () {
    test('hash verifies only the original password', () {
      final hash = PasswordHasher.hash('Maxfiy123');
      expect(PasswordHasher.isHashed(hash), true);
      expect(hash.contains('Maxfiy123'), false);
      expect(PasswordHasher.verify('Maxfiy123', hash), true);
      expect(PasswordHasher.verify('maxfiy123', hash), false);
    });

    test('plain-text stored value never verifies', () {
      expect(PasswordHasher.verify('abc', 'abc'), false);
      expect(PasswordHasher.verify('abc', null), false);
    });
  });

  group('Authentication', () {
    setUp(() => freshDb());

    Future<AuthProvider> registeredAuth() async {
      final auth = AuthProvider();
      await auth.register(
        firstName: 'Test',
        lastName: 'Psixolog',
        phone: '+998 99 111-22-33',
        email: 'test.psy@talim.uz',
        role: UserRole.psychologist,
        specialization: 'Psixolog',
        qualificationCategory: 'Oliy',
        institutionName: '5-sonli umumiy o‘rta ta’lim maktabi',
        password: 'OwnPass99',
      );
      await auth.logout();
      return auth;
    }

    test('registered password is stored hashed', () async {
      await registeredAuth();
      final user = db.findUserByEmailOrPhone('test.psy@talim.uz')!;
      expect(PasswordHasher.isHashed(user.password), true);
    });

    test('old master password no longer opens a real account', () async {
      final auth = await registeredAuth();
      final bad = await auth.login('test.psy@talim.uz', SeedData.demoPassword);
      expect(bad['success'], false);
      final good = await auth.login('test.psy@talim.uz', 'OwnPass99');
      expect(good['success'], true);
    });

    test('blocked user cannot log in', () async {
      final auth = await registeredAuth();
      final user = db.findUserByEmailOrPhone('test.psy@talim.uz')!;
      await db.updateUser(user.copyWith(isActive: false));
      final res = await auth.login('test.psy@talim.uz', 'OwnPass99');
      expect(res['success'], false);
      expect(auth.isAuthenticated, false);
    });

    test('phone login requires the full number', () async {
      await registeredAuth();
      expect(db.findUserByEmailOrPhone('3'), isNull);
      expect(db.findUserByEmailOrPhone('22-33'), isNull);
      expect(db.findUserByEmailOrPhone('991112233'), isNotNull);
      expect(db.findUserByEmailOrPhone('+998991112233'), isNotNull);
    });

    test('changing password requires the current one', () async {
      final auth = await registeredAuth();
      await auth.login('test.psy@talim.uz', 'OwnPass99');
      final bad = await auth.changePassword(SeedData.demoPassword, 'NewPass77');
      expect(bad['success'], false);
      final good = await auth.changePassword('OwnPass99', 'NewPass77');
      expect(good['success'], true);
      await auth.logout();
      final relogin = await auth.login('test.psy@talim.uz', 'NewPass77');
      expect(relogin['success'], true);
    });
  });

  group('Storage safety', () {
    test('corrupted table is preserved, not replaced by demo data', () async {
      await freshDb({'app_db_seeded_v2': true, 'db_students': 'not valid json'});
      expect(db.loadErrors, contains('db_students'));
      // Namunaviy bolalar qo'shilmagan
      expect(db.getStudents(), isEmpty);

      // Keyingi yozish asl qiymatni ustidan yozmasligi kerak
      await db.addAuditLog(
        userFullName: 'x',
        userRole: 'x',
        action: 'TEST',
        entity: 'Test',
        details: 'x',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('db_students'), 'not valid json');
      expect(prefs.getString('db_students_corrupt_backup'), 'not valid json');
    });

    test('plain-text passwords from old versions are migrated to hashes',
        () async {
      final legacy = UserModel(
        id: 'legacy_1',
        email: 'legacy@talim.uz',
        fullName: 'Eski Foydalanuvchi',
        role: UserRole.psychologist,
        password: 'legacyPass',
      );
      await freshDb({
        'app_db_seeded_v2': true,
        'db_users': jsonEncode([legacy.toJson()]),
      });
      final user = db.getUserById('legacy_1')!;
      expect(PasswordHasher.isHashed(user.password), true);
      expect(db.verifyPassword(user, 'legacyPass'), true);
    });
  });

  group('Access control', () {
    final access = AccessControlService();

    test('partial school name does not grant access', () {
      final intruder = UserModel(
        id: 'u_x',
        email: 'x@talim.uz',
        fullName: 'X',
        role: UserRole.psychologist,
        institutionName: '1',
      );
      final student = StudentModel(
        id: 's_1',
        institutionId: 'inst_14',
        institutionName: '14-sonli inklyuziv maktab',
        firstName: 'A',
        lastName: 'B',
        dateOfBirth: DateTime(2015, 1, 1),
        gender: 'Erkak',
        grade: '3-A',
        status: 'Faol',
        primaryNeed: 'Nutq',
        supportLevel: '1-daraja',
        createdAt: DateTime.now(),
      );
      expect(access.canViewStudent(intruder, student), false);
    });

    test('confidential observations are hidden from teachers', () async {
      await freshDb();
      final student = db.getStudents().first;
      final author = UserModel(
        id: 'psy_author',
        email: 'a@talim.uz',
        fullName: 'Muallif',
        role: UserRole.psychologist,
        institutionId: student.institutionId,
        institutionName: student.institutionName,
      );
      final teacher = UserModel(
        id: 'teacher_x',
        email: 't@talim.uz',
        fullName: 'O‘qituvchi',
        role: UserRole.teacher,
        institutionId: student.institutionId,
        institutionName: student.institutionName,
      );
      await db.addObservation(
        PsychologicalObservationModel(
          id: 'obs_secret',
          studentId: student.id,
          studentName: student.fullName,
          studentGrade: student.grade,
          psychologistId: author.id,
          psychologistName: author.fullName,
          date: DateTime.now(),
          category: 'Hissiy holat (Affektiv)',
          observationText: 'Maxfiy qayd',
          isConfidential: true,
          createdAt: DateTime.now(),
        ),
      );

      bool sees(UserModel u) =>
          db.getObservations(forUser: u).any((o) => o.id == 'obs_secret');
      expect(sees(author), true);
      expect(sees(teacher), false);
    });
  });
}
