import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/models/assessment_model.dart';
import 'package:talim_nazorat/models/psychologist_observation_model.dart';
import 'package:talim_nazorat/models/referral_model.dart';
import 'package:talim_nazorat/models/session_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/services/app_exceptions.dart';
import 'package:talim_nazorat/services/local_db_service.dart';

/// Har bir yozish amali ruxsat bilan himoyalanganini tekshiradi (talab #13).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final db = LocalDbService();
  const school = '5-sonli umumiy o‘rta ta’lim maktabi';
  const otherSchool = '12-sonli inklyuziv maktab';

  UserModel staff(String id, UserRole role, {String inst = school, List<String> students = const []}) =>
      UserModel(
        id: id, email: '$id@talim.uz', fullName: id, role: role,
        institutionId: inst == school ? 'inst_chortoq_5' : 'inst_other',
        institutionName: inst, assignedStudentIds: students,
      );

  final superAdmin = staff('sa', UserRole.superAdmin);
  final coordinator = staff('coord', UserRole.coordinator);
  final otherDirector = staff('dir2', UserRole.institutionAdmin, inst: otherSchool);

  final permissionDenied = throwsA(isA<PermissionDeniedException>());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db.resetForTest();
    await db.init();
  });

  /// Bazadagi namunaviy psixolog (student_02, 03, 04 ga biriktirilgan)
  UserModel seededPsychologist() => db.getUserById('user_psychologist')!;

  group('Users', () {
    test('a user cannot change their own role (privilege escalation)', () async {
      final psy = seededPsychologist();
      await expectLater(
        db.updateUser(psy.copyWith(role: UserRole.superAdmin), byUser: psy),
        permissionDenied,
      );
      expect(db.getUserById(psy.id)!.role, UserRole.psychologist);
    });

    test('a user can still edit their own normal profile fields', () async {
      final psy = seededPsychologist();
      await db.updateUser(psy.copyWith(phone: '+998 90 000-00-00'), byUser: psy);
      expect(db.getUserById(psy.id)!.phone, '+998 90 000-00-00');
    });

    test('a user cannot edit someone else', () async {
      final psy = seededPsychologist();
      final teacher = db.getUserById('user_teacher')!;
      await expectLater(
        db.updateUser(teacher.copyWith(phone: '1'), byUser: psy),
        permissionDenied,
      );
    });

    test('a school director cannot manage users of another school', () async {
      await expectLater(
        db.toggleUserActive('user_teacher', false, byUser: otherDirector),
        permissionDenied,
      );
    });

    test('nobody can block or delete themselves', () async {
      final admin = db.getUserById('user_admin')!;
      await expectLater(
        db.toggleUserActive(admin.id, false, byUser: admin),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Children are visible only to assigned specialists', () {
    test('psychologist sees only assigned children; coordinator sees the school', () {
      final psy = seededPsychologist();
      final visible = db.getStudents(forUser: psy).map((s) => s.id).toSet();
      expect(visible, contains('student_02'));
      expect(visible, isNot(contains('student_04')));
      expect(db.getStudents(forUser: coordinator).length, db.getStudents().length);
    });

    test('unassigned specialist cannot record anything for the child', () async {
      final psy = seededPsychologist();
      await expectLater(
        db.addObservation(
          PsychologicalObservationModel(
            id: 'o1', studentId: 'student_04', studentName: 'x', studentGrade: '3-A',
            psychologistId: psy.id, psychologistName: psy.fullName, date: DateTime.now(),
            category: 'Hissiy holat (Affektiv)', observationText: 'Matn', createdAt: DateTime.now(),
          ),
          byUser: psy,
        ),
        permissionDenied,
      );
      await expectLater(
        db.addSession(
          SessionModel(
            id: 's1', studentId: 'student_04', studentName: 'x', specialistId: psy.id,
            specialistName: psy.fullName, specialistRole: psy.role.label,
            scheduledAt: DateTime.now(), status: 'Rejalashtirilgan', topic: 't',
          ),
          byUser: psy,
        ),
        permissionDenied,
      );
    });

    test('records cannot be written in someone else\'s name', () async {
      final psy = seededPsychologist();
      await expectLater(
        db.addAssessment(
          AssessmentModel(
            id: 'a1', studentId: 'student_02', studentName: 'x',
            specialistId: 'user_speech', specialistName: 'Logoped', specialistRole: 'Logoped',
            assessmentDate: DateTime.now(), type: 'Diagnostik', category: 'Nutq',
            title: 't', totalScore: 1, maxScore: 2, notes: '', recommendations: '',
          ),
          byUser: psy,
        ),
        permissionDenied,
      );
    });

    test('records for a non-existent child are refused', () async {
      await expectLater(
        db.addReferral(
          ReferralModel(
            id: 'r0', studentId: 'no_such_child', studentName: 'x', fromSpecialistName: 'x',
            toSpecialistType: UserRole.psychologist.label, reason: 'x', priority: 'O‘rta',
            status: 'Yuborildi', createdAt: DateTime.now(),
          ),
          byUser: superAdmin,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('Assignment', () {
    test('only coordinator or director assigns specialists', () async {
      final psy = seededPsychologist();
      await expectLater(
        db.assignSpecialistToStudent('student_04', psy.id, byUser: psy),
        permissionDenied,
      );
      await db.assignSpecialistToStudent('student_04', psy.id, byUser: coordinator);
      final updated = db.getUserById(psy.id)!;
      expect(db.getStudents(forUser: updated).map((s) => s.id), contains('student_04'));
      // Mutaxassisga bildirishnoma yuborildi
      expect(db.getNotifications(psy.id).any((n) => n.type == 'ASSIGNMENT'), true);
    });

    test('unassigning removes access', () async {
      await db.unassignSpecialistFromStudent('student_02', 'user_psychologist', byUser: coordinator);
      final psy = db.getUserById('user_psychologist')!;
      expect(db.getStudents(forUser: psy).map((s) => s.id), isNot(contains('student_02')));
    });

    test('admins and reviewers cannot be assigned as specialists', () async {
      await expectLater(
        db.assignSpecialistToStudent('student_04', 'user_admin', byUser: coordinator),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepting a referral assigns the specialist to the child', () async {
      final psy = seededPsychologist();
      await db.addReferral(
        ReferralModel(
          id: 'r1', studentId: 'student_04', studentName: 'Aliyev Jasur', fromSpecialistName: 'x',
          toSpecialistType: UserRole.psychologist.label, reason: 'Xavotir belgilari',
          priority: 'O‘rta', status: 'Yuborildi', createdAt: DateTime.now(),
        ),
        byUser: coordinator,
      );
      // Psixolog yo'naltirishni ko'radi, lekin bolani hali ko'rmaydi
      expect(db.getReferrals(forUser: psy).map((r) => r.id), contains('r1'));
      expect(db.getStudents(forUser: psy).map((s) => s.id), isNot(contains('student_04')));

      await db.updateReferralStatus('r1', 'Qabul qilindi', byUser: psy);
      final updated = db.getUserById(psy.id)!;
      expect(db.getStudents(forUser: updated).map((s) => s.id), contains('student_04'));
      expect(db.getReferrals().firstWhere((r) => r.id == 'r1').toSpecialistId, psy.id);
    });
  });

  group('Other protections', () {
    test('standard questions can be changed only by the system admin', () async {
      final psy = seededPsychologist();
      final standard = db.getQuestionById('q_kog_01')!;
      await expectLater(
        db.updateQuestion(standard.copyWith(text: 'o‘zgartirildi'), byUser: psy),
        permissionDenied,
      );
      await expectLater(db.deleteQuestion('q_kog_01', byUser: psy), permissionDenied);
      await db.updateQuestion(standard.copyWith(text: 'yangi matn'), byUser: superAdmin);
      expect(db.getQuestionById('q_kog_01')!.text, 'yangi matn');
    });

    test('questions added by specialists are never marked as standard', () async {
      final psy = seededPsychologist();
      await db.addQuestion(
        db.getQuestionById('q_kog_01')!.copyWith(id: 'my_q', authorId: psy.id),
        byUser: psy,
      );
      expect(db.getQuestionById('my_q')!.isStandard, false);
    });

    test('only the recipient can mark a notification as read', () async {
      await db.assignSpecialistToStudent('student_04', 'user_psychologist', byUser: coordinator);
      final n = db.getNotifications('user_psychologist').first;
      await expectLater(
        db.markNotificationAsRead(n.id, byUser: coordinator),
        permissionDenied,
      );
      await db.markNotificationAsRead(n.id, byUser: seededPsychologist());
      expect(db.getNotifications('user_psychologist').first.isRead, true);
    });

    test('invalid statuses are rejected', () async {
      await db.addReferral(
        ReferralModel(
          id: 'r2', studentId: 'student_04', studentName: 'x', fromSpecialistName: 'x',
          toSpecialistType: UserRole.psychologist.label, reason: 'x', priority: 'O‘rta',
          status: 'Yuborildi', createdAt: DateTime.now(),
        ),
        byUser: coordinator,
      );
      await expectLater(
        db.updateReferralStatus('r2', 'Noto‘g‘ri holat', byUser: coordinator),
        throwsA(isA<ValidationException>()),
      );
    });

    test('error messages are readable text, not "Exception: ..."', () {
      expect(const PermissionDeniedException('x').toString(), 'Ruxsat cheklangan: x');
      expect(const NotFoundException('Topilmadi').toString(), 'Topilmadi');
    });
  });

  test('self-registration cannot create privileged accounts', () async {
    for (final role in [UserRole.superAdmin, UserRole.institutionAdmin, UserRole.coordinator]) {
      await expectLater(
        db.registerUser(UserModel(
          id: 'reg_${role.name}', email: 'reg.${role.name}@talim.uz', fullName: 'x', role: role,
        )),
        throwsA(isA<PermissionDeniedException>()),
      );
    }
    await db.registerUser(UserModel(
      id: 'reg_ok', email: 'reg.ok@talim.uz', fullName: 'Yangi Psixolog',
      role: UserRole.psychologist, assignedStudentIds: const ['student_02'],
    ));
    // Oldindan to'ldirilgan biriktirish olib tashlanadi
    expect(db.getUserById('reg_ok')!.assignedStudentIds, isEmpty);
  });

  test('the referral sender is always recorded as the real user', () async {
    await db.addReferral(
      ReferralModel(
        id: 'r3', studentId: 'student_04', studentName: 'x',
        fromSpecialistId: 'someone_else', fromSpecialistName: 'Soxta ism',
        toSpecialistType: UserRole.psychologist.label, reason: 'x', priority: 'O‘rta',
        status: 'Yuborildi', createdAt: DateTime.now(),
      ),
      byUser: coordinator,
    );
    final r = db.getReferrals().firstWhere((r) => r.id == 'r3');
    expect(r.fromSpecialistId, coordinator.id);
    expect(r.fromSpecialistName, coordinator.fullName);
  });

  test('student profile edits do not overwrite assignments', () async {
    final s = db.getStudentById('student_02')!;
    final stale = StudentModel.fromJson(s.toJson()).copyWith(
      assignedSpecialistIds: const [],
      grade: '3-B',
    );
    await db.updateStudent(stale, byUser: coordinator);
    final after = db.getStudentById('student_02')!;
    expect(after.grade, '3-B');
    expect(after.assignedSpecialistIds, s.assignedSpecialistIds);
  });
}
