import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/psychological_questions_seed.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/seed_data.dart';

/// Namunaviy ma'lumotlar yaxlitligi: har bir havola mavjud yozuvga ishora qilishi kerak.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = LocalDbService();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    db.resetForTest();
    await db.init();
  });

  Set<String> userIds() => db.getUsers().map((u) => u.id).toSet();
  Set<String> studentIds() =>
      db.getStudents(includeArchived: true).map((s) => s.id).toSet();

  test(
    'assignments point to existing users and students (both directions)',
    () {
      final users = userIds();
      final students = studentIds();
      for (final s in db.getStudents(includeArchived: true)) {
        for (final id in s.assignedSpecialistIds) {
          expect(users, contains(id), reason: '${s.id} -> $id');
        }
      }
      for (final u in db.getUsers()) {
        for (final id in u.assignedStudentIds) {
          expect(students, contains(id), reason: '${u.id} -> $id');
        }
      }
    },
  );

  test(
    'assessments, sessions, observations and plans point to existing children and staff',
    () {
      final users = userIds();
      final students = studentIds();
      for (final a in db.getAssessments()) {
        expect(students, contains(a.studentId), reason: 'assessment ${a.id}');
        expect(users, contains(a.specialistId), reason: 'assessment ${a.id}');
      }
      for (final s in db.getSessions()) {
        expect(students, contains(s.studentId), reason: 'session ${s.id}');
        expect(users, contains(s.specialistId), reason: 'session ${s.id}');
      }
      for (final o in db.getObservations()) {
        expect(students, contains(o.studentId), reason: 'observation ${o.id}');
        expect(
          users,
          contains(o.psychologistId),
          reason: 'observation ${o.id}',
        );
      }
      for (final p in db.getIepPlans()) {
        expect(students, contains(p.studentId), reason: 'plan ${p.id}');
        expect(users, contains(p.responsibleTeacherId), reason: 'plan ${p.id}');
      }
    },
  );

  test('referrals and alerts point to existing children', () {
    final students = studentIds();
    for (final r in db.getReferrals()) {
      expect(students, contains(r.studentId), reason: 'referral ${r.id}');
    }
    for (final a in db.getAlerts()) {
      expect(students, contains(a.studentId), reason: 'alert ${a.id}');
    }
  });

  test('every student has the required profile values', () {
    for (final s in db.getStudents(includeArchived: true)) {
      expect(s.firstName.trim(), isNotEmpty, reason: s.id);
      expect(s.lastName.trim(), isNotEmpty, reason: s.id);
      expect(s.grade.trim(), isNotEmpty, reason: s.id);
      expect(s.institutionName.trim(), isNotEmpty, reason: s.id);
      expect(s.dateOfBirth.isBefore(DateTime.now()), true, reason: s.id);
    }
  });

  test('standard questions are complete and have valid scores', () {
    for (final q in PsychologicalQuestionsSeed.initialQuestions) {
      expect(q.text.trim(), isNotEmpty, reason: q.id);
      expect(
        q.requirements,
        isNotNull,
        reason: '${q.id}: talablari ko‘rsatilmagan',
      );
      if (q.questionType != 'open_text') {
        expect(q.options, isNotEmpty, reason: q.id);
        expect(q.maxScore, greaterThan(0), reason: q.id);
      }
      final ids = q.options.map((o) => o.id).toList();
      expect(
        ids.length,
        ids.toSet().length,
        reason: '${q.id}: variant id takrorlangan',
      );
    }
  });

  test('extended seed tables and full JSON database backup are valid', () {
    final users = userIds();
    final students = studentIds();

    for (final sl in SeedData.subjectLevels) {
      expect(students, contains(sl.studentId), reason: 'subjectLevel ${sl.id}');
      expect(users, contains(sl.assessedById), reason: 'subjectLevel ${sl.id}');
    }
    for (final t in SeedData.subjectTasks) {
      expect(students, contains(t.studentId), reason: 'subjectTask ${t.id}');
      expect(users, contains(t.assignedById), reason: 'subjectTask ${t.id}');
    }
    for (final m in SeedData.measurements) {
      expect(students, contains(m.studentId), reason: 'measurement ${m.id}');
      expect(users, contains(m.recordedById), reason: 'measurement ${m.id}');
    }
    for (final se in SeedData.soundEntries) {
      expect(students, contains(se.studentId), reason: 'soundEntry ${se.id}');
      expect(users, contains(se.recordedById), reason: 'soundEntry ${se.id}');
    }

    final backupJson = db.exportFullSeedBackupJson(
      exportedAt: DateTime.utc(2026, 11, 2, 13, 50, 0),
    );
    final decoded = jsonDecode(backupJson) as Map<String, dynamic>;
    final tables = decoded['tables'] as Map<String, dynamic>;
    expect((tables['users'] as List).length, greaterThanOrEqualTo(7));
    expect((tables['students'] as List).length, greaterThanOrEqualTo(6));
    expect((tables['questions'] as List).isNotEmpty, true);
    expect((tables['curriculumStandards'] as List).isNotEmpty, true);
    expect((tables['subjectLevels'] as List).isNotEmpty, true);
    expect((tables['subjectTasks'] as List).isNotEmpty, true);
    expect((tables['measurements'] as List).isNotEmpty, true);
    expect((tables['soundEntries'] as List).isNotEmpty, true);

    final backupFile = File('backups/database_backup.json');
    backupFile.parent.createSync(recursive: true);
    backupFile.writeAsStringSync(backupJson);
    expect(backupFile.existsSync(), true);
  });
}
