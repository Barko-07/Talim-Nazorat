import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/config/app_config.dart';
import 'package:talim_nazorat/models/psychologist_observation_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/providers/app_provider.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/services/app_exceptions.dart';
import 'package:talim_nazorat/services/auth_session.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/login_guard.dart';
import 'package:talim_nazorat/services/password_hasher.dart';

/// Kirish xavfsizligi: bir xil xato xabari, bloklash, sessiya muddati, jurnal, administrator.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = LocalDbService();

  Future<void> fresh([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    db.resetForTest();
    await db.init();
  }

  Future<AuthProvider> auth() async {
    final a = AuthProvider();
    // Konstruktor sessiyani asinxron tekshiradi — tugashini kutamiz
    while (a.isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return a;
  }

  Future<UserModel> registeredUser() async {
    final a = await auth();
    await a.register(
      firstName: 'Xavfsiz', lastName: 'Psixolog', phone: '+998 99 321-00-00',
      email: 'safe.psy@talim.uz', role: UserRole.psychologist,
      specialization: 'Psixolog', qualificationCategory: 'Oliy',
      institutionName: '5-sonli umumiy o‘rta ta’lim maktabi', password: 'Correct123',
    );
    await a.logout();
    return db.findUserByEmailOrPhone('safe.psy@talim.uz')!;
  }

  List<String> securityActions() =>
      db.getAuditLogs().where((l) => l.entity == 'Security').map((l) => l.action).toList();

  group('Login', () {
    setUp(() => fresh());

    test('unknown account and wrong password give the same message', () async {
      await registeredUser();
      final a = await auth();
      final unknown = await a.login('nobody@talim.uz', 'Whatever1');
      final wrong = await a.login('safe.psy@talim.uz', 'Wrong999');
      expect(unknown['success'], false);
      expect(unknown['message'], wrong['message']);
      expect(unknown['message'], 'Login yoki parol noto‘g‘ri.');
    });

    test('5 wrong attempts lock the login, even for the right password, and survive a restart', () async {
      await registeredUser();
      var a = await auth();
      for (var i = 0; i < LoginGuard.maxFailures; i++) {
        await a.login('safe.psy@talim.uz', 'Wrong$i');
      }
      a = await auth(); // "ilovani qayta ochish"
      final result = await a.login('safe.psy@talim.uz', 'Correct123');
      expect(result['success'], false);
      expect(result['message'].toString(), contains('daqiqadan keyin'));
      expect(a.isAuthenticated, false);
      expect(securityActions(), contains('SECURITY_LOCKOUT'));
      expect(securityActions(), contains('SECURITY_LOCKED_ATTEMPT'));
    });

    test('lock expires after the lock period', () async {
      final guard = LoginGuard();
      final t0 = DateTime(2026, 11, 2, 9);
      for (var i = 0; i < LoginGuard.maxFailures; i++) {
        await guard.registerFailure('x@talim.uz', now: t0);
      }
      expect(await guard.lockRemaining('x@talim.uz', now: t0), isNotNull);
      expect(await guard.lockRemaining('x@talim.uz', now: t0.add(LoginGuard.lockDuration)), isNull);
    });

    test('a successful login resets the counter', () async {
      await registeredUser();
      final a = await auth();
      for (var i = 0; i < LoginGuard.maxFailures - 1; i++) {
        await a.login('safe.psy@talim.uz', 'Wrong$i');
      }
      expect((await a.login('safe.psy@talim.uz', 'Correct123'))['success'], true);
      await a.logout();
      await a.login('safe.psy@talim.uz', 'WrongAgain');
      expect((await a.login('safe.psy@talim.uz', 'Correct123'))['success'], true);
    });

    test('failed logins are logged with a masked login, never the password', () async {
      final a = await auth();
      await a.login('someone.secret@talim.uz', 'MyTypedPassword');
      final log = db.getAuditLogs().firstWhere((l) => l.action == 'SECURITY_LOGIN_FAILED');
      expect(log.details, contains('so***@talim.uz'));
      expect(log.details, isNot(contains('someone.secret')));
      expect(log.details, isNot(contains('MyTypedPassword')));
    });

    test('blocked account login is refused and logged', () async {
      final user = await registeredUser();
      final admin = UserModel(id: 'sa', email: 'sa@x.uz', fullName: 'Admin', role: UserRole.superAdmin);
      await db.toggleUserActive(user.id, false, byUser: admin);
      final a = await auth();
      final r = await a.login('safe.psy@talim.uz', 'Correct123');
      expect(r['success'], false);
      expect(securityActions(), contains('SECURITY_BLOCKED_LOGIN'));
    });

    test('identifier helpers', () {
      expect(LoginGuard.normalize(' Psy@Talim.UZ '), 'psy@talim.uz');
      expect(LoginGuard.normalize('+998 (90) 123-45-67'), '901234567');
      expect(LoginGuard.mask('+998 90 123 45 67'), '***4567');
    });
  });

  group('Session', () {
    test('an idle session expires; a fresh one is restored', () async {
      final user = await () async {
        await fresh();
        return registeredUser();
      }();
      final prefs = await SharedPreferences.getInstance();

      final stale = AuthSession(
        userId: user.id,
        issuedAt: DateTime.now().subtract(const Duration(hours: 3)),
        lastActive: DateTime.now().subtract(const Duration(hours: 3)),
      );
      await prefs.setString(AuthSession.prefsKey, stale.encode());
      expect((await auth()).isAuthenticated, false);
      expect(prefs.getString(AuthSession.prefsKey), isNull);

      await prefs.setString(AuthSession.prefsKey, AuthSession.start(user.id).encode());
      expect((await auth()).isAuthenticated, true);
    });

    test('a session older than the maximum age expires even if active', () {
      final now = DateTime(2026, 11, 2, 20);
      final s = AuthSession(
        userId: 'u',
        issuedAt: now.subtract(AuthSession.maxAge),
        lastActive: now.subtract(const Duration(minutes: 1)),
      );
      expect(s.isValid(now: now), false);
    });

    test('the old never-expiring session key is ignored', () async {
      await fresh();
      final user = await registeredUser();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user_id', user.id);
      expect((await auth()).isAuthenticated, false);
      expect(prefs.getString('auth_user_id'), isNull);
    });

    test('logout clears the session', () async {
      await fresh();
      await registeredUser();
      final a = await auth();
      await a.login('safe.psy@talim.uz', 'Correct123');
      await a.logout();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AuthSession.prefsKey), isNull);
    });
  });

  group('Monitoring and lock-down', () {
    setUp(() => fresh());

    test('refused actions are logged as security events', () async {
      final psy = db.getUserById('user_psychologist')!;
      await expectLater(
        db.assignSpecialistToStudent('student_04', psy.id, byUser: psy),
        throwsA(isA<PermissionDeniedException>()),
      );
      await Future<void>.delayed(Duration.zero);
      final log = db.getAuditLogs().firstWhere((l) => l.action == 'SECURITY_ACCESS_DENIED');
      expect(log.userFullName, psy.fullName);
      // Tizim bo'ylab hodisalar — faqat tizim administratoriga
      expect(db.getSecurityEvents(forUser: db.getUserById('user_admin')!), isNotEmpty);
      expect(db.getSecurityEvents(forUser: db.getUserById('user_coordinator')!), isEmpty);
      expect(db.getSecurityEvents(forUser: psy), isEmpty);
    });

    test('a user blocked during their session loses access immediately', () async {
      final app = AppProvider();
      final teacher = db.getUserById('user_teacher')!;
      app.setCurrentUser(teacher); // eski nusxa xotirada
      final admin = db.getUserById('user_admin')!;
      await db.toggleUserActive(teacher.id, false, byUser: admin);
      expect(app.students, isEmpty);
      expect(() => app.childStatus(db.getStudentById('student_02')!),
          throwsA(isA<PermissionDeniedException>()));
    });

    test('the last active system admin cannot lose the admin role', () async {
      final admin = db.getUserById('user_admin')!;
      await expectLater(
        db.updateUser(admin.copyWith(role: UserRole.coordinator), byUser: admin),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Admin bootstrap from build configuration', () {
    test('creates the first admin from a hash when no admin exists', () async {
      await fresh({'app_db_seeded_v2': true, 'db_users': jsonEncode([])});
      final hash = PasswordHasher.hash('StrongAdmin2026');
      expect(await db.bootstrapAdmin(email: 'Boss@Maktab.uz', passwordHash: hash), true);
      final admin = db.findUserByEmailOrPhone('boss@maktab.uz')!;
      expect(admin.role, UserRole.superAdmin);
      expect(db.verifyPassword(admin, 'StrongAdmin2026'), true);
      expect(db.getAuditLogs().any((l) => l.action == 'SECURITY_ADMIN_BOOTSTRAP'), true);
    });

    test('never overwrites, promotes, or accepts a plain password', () async {
      await fresh(); // namunaviy administrator bor
      final hash = PasswordHasher.hash('StrongAdmin2026');
      expect(await db.bootstrapAdmin(email: 'new@maktab.uz', passwordHash: hash), false);

      await fresh({'app_db_seeded_v2': true, 'db_users': jsonEncode([
        UserModel(id: 'p', email: 'teacher@maktab.uz', fullName: 'O‘qituvchi', role: UserRole.teacher).toJson(),
      ])});
      expect(await db.bootstrapAdmin(email: 'teacher@maktab.uz', passwordHash: hash), false);
      expect(db.findUserByEmailOrPhone('teacher@maktab.uz')!.role, UserRole.teacher);

      expect(await db.bootstrapAdmin(email: 'x@maktab.uz', passwordHash: 'PlainPassword1'), false);
    });

    test('configuration check reports a release build without an admin', () {
      expect(AppConfig.problems(isRelease: true).join(), contains('ADMIN_EMAIL'));
      expect(AppConfig.problems(isRelease: false), isEmpty);
    });
  });

  group('Independent review fixes', () {
    setUp(() => fresh());

    test('a stale user object passed by a screen is not trusted', () async {
      final app = AppProvider();
      final psy = db.getUserById('user_psychologist')!;
      app.setCurrentUser(psy);
      await db.toggleUserActive(psy.id, false, byUser: db.getUserById('user_admin')!);
      final staleCopy = psy; // ekran saqlab qolgan eski nusxa (isActive: true)
      await expectLater(
        app.addObservation(
          PsychologicalObservationModel(
            id: 'o_stale', studentId: 'student_02', studentName: 'x', studentGrade: '2-B',
            psychologistId: psy.id, psychologistName: psy.fullName, date: DateTime.now(),
            category: 'Hissiy holat (Affektiv)', observationText: 'Matn', createdAt: DateTime.now(),
          ),
          byUser: staleCopy,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(app.measurementsFor('student_02'), isEmpty);
      expect(app.speechProfile('student_02').sounds, isEmpty);
    });

    test('an open session ends when the account is blocked or the role changes', () async {
      await registeredUser();
      final a = await auth();
      await a.login('safe.psy@talim.uz', 'Correct123');
      final admin = db.getUserById('user_admin')!;
      final me = db.findUserByEmailOrPhone('safe.psy@talim.uz')!;
      await db.updateUser(me.copyWith(role: UserRole.teacher), byUser: admin);
      await a.validateSession();
      expect(a.isAuthenticated, false);
    });

    test('phone and email share one counter for the same account', () async {
      await registeredUser();
      final a = await auth();
      for (var i = 0; i < LoginGuard.maxFailures; i++) {
        await a.login(i.isEven ? 'safe.psy@talim.uz' : '+998 99 321-00-00', 'Wrong$i');
      }
      final r = await a.login('+998 99 321-00-00', 'Correct123');
      expect(r['success'], false);
      expect(r['message'].toString(), contains('daqiqadan keyin'));
    });

    test('repeated lockouts last longer, capped at 24 hours', () {
      expect(LoginGuard.lockFor(1), const Duration(minutes: 15));
      expect(LoginGuard.lockFor(2), const Duration(minutes: 30));
      expect(LoginGuard.lockFor(3), const Duration(minutes: 60));
      expect(LoginGuard.lockFor(20), LoginGuard.maxLock);
    });

    test('the second lockout in a row is twice as long', () async {
      final guard = LoginGuard();
      var t = DateTime(2026, 11, 2, 9);
      for (var i = 0; i < LoginGuard.maxFailures; i++) {
        await guard.registerFailure('y@talim.uz', now: t);
      }
      t = t.add(LoginGuard.lockDuration + const Duration(minutes: 1));
      for (var i = 0; i < LoginGuard.maxFailures; i++) {
        await guard.registerFailure('y@talim.uz', now: t);
      }
      final left = await guard.lockRemaining('y@talim.uz', now: t);
      expect(left, const Duration(minutes: 30));
    });

    test('moving the clock back does not unlock a locked login', () async {
      final guard = LoginGuard();
      final t = DateTime(2026, 11, 2, 9);
      for (var i = 0; i < LoginGuard.maxFailures; i++) {
        await guard.registerFailure('z@talim.uz', now: t);
      }
      expect(await guard.lockRemaining('z@talim.uz', now: t.subtract(const Duration(days: 2))), isNotNull);
    });

    test('the last active admin cannot be deactivated through a profile update', () async {
      final admin = db.getUserById('user_admin')!;
      await expectLater(
        db.updateUser(admin.copyWith(isActive: false), byUser: admin),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
