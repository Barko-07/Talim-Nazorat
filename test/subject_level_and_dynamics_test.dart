import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/curriculum_standards_seed.dart';
import 'package:talim_nazorat/core/constants/progress_metrics.dart';
import 'package:talim_nazorat/models/curriculum_model.dart';
import 'package:talim_nazorat/models/progress_measurement_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/services/dynamics_service.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/subject_level_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final levels = SubjectLevelService();
  final dynamics = DynamicsService();
  final math =
      CurriculumStandardsSeed.standards
          .where((s) => s.subject == SchoolSubjects.matematika)
          .toList();

  /// [mastered] sinflar talablari o'zlashtirilgan, [failed] sinflarniki — yo'q
  Map<String, Mastery> results({
    List<int> mastered = const [],
    List<int> failed = const [],
  }) => {
    for (final s in math)
      if (mastered.contains(s.grade))
        s.id: Mastery.mastered
      else if (failed.contains(s.grade))
        s.id: Mastery.notYet,
  };

  group('Subject level vs grade (state standards)', () {
    test(
      'sample standards exist for core subjects and are marked as not official',
      () {
        final all = CurriculumStandardsSeed.standards;
        expect(
          all.map((s) => s.subject).toSet(),
          containsAll(SchoolSubjects.core),
        );
        expect(all.every((s) => !s.isOfficial), true);
        expect(
          all.map((s) => s.id).toSet().length,
          all.length,
        ); // id takrorlanmaydi
      },
    );

    test(
      'grade 7 student who masters grades 1–3 but not 4 is at grade 3 level',
      () {
        final r = results(mastered: [1, 2, 3], failed: [4, 5]);
        expect(levels.suggestGrade(r, math), 3);
        final a = SubjectLevelAssessment(
          id: 'x',
          studentId: 's',
          subject: SchoolSubjects.matematika,
          classGrade: 7,
          results: r,
          suggestedGrade: 3,
          confirmedGrade: 3,
          assessedById: 't',
          assessedByName: 't',
          assessedAt: DateTime.now(),
        );
        expect(a.gap, 4);
        expect(levels.describe(a), contains('3-sinf darajasi'));
        expect(levels.describe(a), contains('4 sinf past'));
      },
    );

    test(
      'partial mastery counts half; below 80% the grade is not mastered',
      () {
        final grade2 = math.where((s) => s.grade == 2).toList();
        final r = {
          for (final s in math.where((s) => s.grade == 1))
            s.id: Mastery.mastered,
          grade2[0].id: Mastery.mastered,
          grade2[1].id: Mastery.mastered,
          grade2[2].id:
              Mastery.partial, // (1+1+0.5)/3 = 0.83 -> o'zlashtirilgan
          for (final s in math.where((s) => s.grade == 3)) s.id: Mastery.notYet,
        };
        expect(levels.suggestGrade(r, math), 2);
        r[grade2[1].id] = Mastery.partial; // (1+0.5+0.5)/3 = 0.67 -> yo'q
        expect(levels.suggestGrade(r, math), 1);
      },
    );

    test('nothing mastered at grade 1 gives level 0', () {
      expect(levels.suggestGrade(results(failed: [1]), math), 0);
    });

    test(
      'mastering all currently loaded standards does not invent an upper level',
      () {
        final allLoadedGrades =
            math.map((standard) => standard.grade).toSet().toList();
        expect(
          levels.suggestGrade(results(mastered: allLoadedGrades), math),
          isNull,
        );
      },
    );

    test('failing only the class grade asks to check lower grades', () {
      final r = results(failed: [7]);
      expect(levels.suggestGrade(r, math), isNull);
      expect(levels.needsLowerGradeCheck(r, math), true);
      expect(
        levels.needsLowerGradeCheck(
          results(mastered: [1, 2], failed: [3]),
          math,
        ),
        false,
      );
    });

    test(
      'a gap in lower-grade evidence cannot produce a level recommendation',
      () {
        final r = results(mastered: [1, 3], failed: [4]);
        expect(levels.suggestGrade(r, math), isNull);
        expect(levels.needsLowerGradeCheck(r, math), true);
      },
    );

    test(
      'next standards are the unmastered ones at the current and next grade',
      () {
        final r = results(mastered: [1, 2, 3], failed: [4]);
        final next = levels.nextStandards(3, r, math);
        expect(next, isNotEmpty);
        expect(next.every((s) => s.grade == 4), true);
      },
    );
  });

  group('Dynamics', () {
    final d0 = DateTime(2026, 1, 10);
    DataPoint p(int day, double v) => DataPoint(d0.add(Duration(days: day)), v);

    test(
      'attention span 2 → 5 minutes is growth, with units in the reason',
      () {
        final r = dynamics.evaluate([p(0, 2), p(30, 5)], unit: 'daqiqa');
        expect(r.status, DynamicsStatus.growth);
        expect(r.change, 3);
        expect(r.changePercent, 150);
        expect(r.reason, contains('2 daqiqa → 5 daqiqa'));
      },
    );

    test('decline when the latest result is clearly worse', () {
      expect(
        dynamics.evaluate([p(0, 5), p(14, 3)]).status,
        DynamicsStatus.decline,
      );
    });

    test('stable when the change is small', () {
      expect(
        dynamics.evaluate([p(0, 10), p(14, 10.5)]).status,
        DynamicsStatus.stable,
      );
    });

    test(
      'ineffective when 3+ results over 30+ days show no real improvement',
      () {
        final r = dynamics.evaluate([p(0, 4), p(20, 4.2), p(45, 4.1)]);
        expect(r.status, DynamicsStatus.ineffective);
      },
    );

    test(
      'not ineffective if the same flat results are within a short period',
      () {
        final r = dynamics.evaluate([p(0, 4), p(5, 4.2), p(10, 4.1)]);
        expect(r.status, DynamicsStatus.stable);
      },
    );

    test('lower-is-better metrics: fewer meltdowns is growth', () {
      final r = dynamics.evaluate([p(0, 6), p(30, 2)], higherIsBetter: false);
      expect(r.status, DynamicsStatus.growth);
    });

    test('monthly view keeps the last result of each month', () {
      final pts = [
        DataPoint(DateTime(2026, 1, 5), 2),
        DataPoint(DateTime(2026, 1, 25), 3),
        DataPoint(DateTime(2026, 2, 20), 5),
      ];
      final monthly = dynamics.aggregate(pts, DynamicsPeriod.month);
      expect(monthly.length, 2);
      expect(monthly.first.value, 3);
      final r = dynamics.evaluate(pts, period: DynamicsPeriod.month);
      expect(r.status, DynamicsStatus.growth);
      expect(r.previous!.value, 3);
      expect(r.latest!.value, 5);
    });

    test('one result is not enough to compare', () {
      expect(
        dynamics.evaluate([p(0, 3)]).status,
        DynamicsStatus.insufficientData,
      );
    });
  });

  group('Storage and permissions', () {
    final db = LocalDbService();
    const school = '5-sonli umumiy o‘rta ta’lim maktabi';
    // Mutaxassislar o'zlariga biriktirilgan bolalar bilan ishlaydi
    UserModel user(String id, UserRole role) => UserModel(
      id: id,
      email: '$id@talim.uz',
      fullName: id,
      role: role,
      institutionId: 'inst_chortoq_5',
      institutionName: school,
      assignedStudentIds: const ['student_01', 'stud_g7'],
    );
    final specialTeacher = user('sped', UserRole.specialEducation);
    final psychologist = user('psy', UserRole.psychologist);
    final reviewer = user('rev', UserRole.reviewer);
    final admin = UserModel(
      id: 'adm',
      email: 'adm@talim.uz',
      fullName: 'Admin',
      role: UserRole.superAdmin,
    );

    Future<StudentModel> grade7Student() async {
      final s = StudentModel(
        id: 'stud_g7',
        institutionId: 'inst_chortoq_5',
        institutionName: school,
        firstName: 'Yetti',
        lastName: 'Sinf',
        dateOfBirth: DateTime(2013, 1, 1),
        gender: 'Erkak',
        grade: '7-A',
        status: 'Faol',
        primaryNeed: 'Test',
        supportLevel: '2-daraja',
        createdAt: DateTime.now(),
      );
      await db.addStudent(s, byUser: admin);
      return s;
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db.resetForTest();
      await db.init();
    });

    test('sample standards are loaded into the database', () {
      expect(db.getCurriculumSubjects(), containsAll(SchoolSubjects.core));
      expect(
        db.getCurriculumStandards(subject: SchoolSubjects.matematika, grade: 3),
        hasLength(3),
      );
    });

    test(
      'special-ed teacher records grade 7 student at grade 3 maths level; history kept',
      () async {
        final s = await grade7Student();
        final saved = await db.saveSubjectLevel(
          studentId: s.id,
          subject: SchoolSubjects.matematika,
          results: results(mastered: [1, 2, 3], failed: [4]),
          byUser: specialTeacher,
        );
        expect(saved.classGrade, 7);
        expect(saved.suggestedGrade, 3);
        expect(saved.confirmedGrade, 3);
        expect(saved.gap, 4);

        // Keyinroq: 4-sinf talablari o'zlashtirildi
        await db.saveSubjectLevel(
          studentId: s.id,
          subject: SchoolSubjects.matematika,
          results: results(mastered: [1, 2, 3, 4], failed: [5]),
          byUser: specialTeacher,
        );
        final history = db.getSubjectLevels(
          forUser: specialTeacher,
          studentId: s.id,
          subject: SchoolSubjects.matematika,
        );
        expect(history.map((h) => h.confirmedGrade).toList(), [3, 4]);
        expect(
          db
              .latestSubjectLevel(
                forUser: psychologist,
                studentId: s.id,
                subject: SchoolSubjects.matematika,
              )!
              .confirmedGrade,
          4,
        );
      },
    );

    test('teacher can confirm a different level than suggested', () async {
      final s = await grade7Student();
      final saved = await db.saveSubjectLevel(
        studentId: s.id,
        subject: SchoolSubjects.matematika,
        results: results(mastered: [1, 2, 3], failed: [4]),
        confirmedGrade: 2,
        byUser: specialTeacher,
      );
      expect(saved.suggestedGrade, 3);
      expect(saved.confirmedGrade, 2);
    });

    test('psychologist and reviewer cannot record subject levels', () async {
      final s = await grade7Student();
      for (final u in [psychologist, reviewer]) {
        expect(
          () => db.saveSubjectLevel(
            studentId: s.id,
            subject: SchoolSubjects.matematika,
            results: results(mastered: [1]),
            byUser: u,
          ),
          throwsException,
        );
      }
    });

    test(
      'importing official standards replaces samples for that subject only',
      () async {
        await db.importCurriculumStandards([
          const CurriculumStandard(
            id: 'dts_official_mat_1_1',
            subject: SchoolSubjects.matematika,
            grade: 1,
            description: 'Rasmiy talab',
            source: 'DTS',
            isOfficial: true,
          ),
        ], byUser: admin);
        final mathNow = db.getCurriculumStandards(
          subject: SchoolSubjects.matematika,
        );
        expect(mathNow, hasLength(1));
        expect(mathNow.single.isOfficial, true);
        expect(
          db.getCurriculumStandards(subject: SchoolSubjects.onaTili),
          isNotEmpty,
        );

        // Qayta ishga tushganda namunalar qaytib kelmaydi
        db.resetForTest();
        await db.init();
        expect(
          db.getCurriculumStandards(subject: SchoolSubjects.matematika),
          hasLength(1),
        );
      },
    );

    test('only the system admin can import standards', () async {
      expect(
        () => db.importCurriculumStandards(const [], byUser: specialTeacher),
        throwsException,
      );
    });

    test('measurements are stored with units and support dynamics', () async {
      Future<void> add(String id, double v, DateTime at) => db.addMeasurement(
        ProgressMeasurement(
          id: id,
          studentId: 'student_01',
          metricId: ProgressMetrics.attentionSpan.id,
          value: v,
          measuredAt: at,
          recordedById: '',
          recordedByName: '',
        ),
        byUser: psychologist,
      );
      await add('m1', 2, DateTime(2026, 9, 1));
      await add('m2', 5, DateTime(2026, 10, 1));
      final list = db.getMeasurements(
        forUser: psychologist,
        studentId: 'student_01',
      );
      expect(list.map((m) => m.value).toList(), [2, 5]);
      expect(list.first.recordedById, psychologist.id);

      final r = dynamics.evaluate(
        list.map((m) => DataPoint(m.measuredAt, m.value)).toList(),
        unit: ProgressMetrics.attentionSpan.unit,
      );
      expect(r.status, DynamicsStatus.growth);
    });

    test('negative values and unknown metrics are refused', () async {
      ProgressMeasurement m(String metric, double v) => ProgressMeasurement(
        id: 'bad',
        studentId: 'student_01',
        metricId: metric,
        value: v,
        measuredAt: DateTime.now(),
        recordedById: '',
        recordedByName: '',
      );
      expect(
        () => db.addMeasurement(
          m(ProgressMetrics.attentionSpan.id, -1),
          byUser: psychologist,
        ),
        throwsException,
      );
      expect(
        () => db.addMeasurement(m('no_such_metric', 1), byUser: psychologist),
        throwsException,
      );
      expect(
        () => db.addMeasurement(
          m(ProgressMetrics.attentionSpan.id, 1),
          byUser: reviewer,
        ),
        throwsException,
      );
    });

    test('custom metric can be added and used', () async {
      await db.addCustomMetric(
        const ProgressMetric(
          id: 'metric_custom_1',
          name: 'Navbat kutish',
          unit: 'soniya',
          domain: 'Xulq-atvor va iroda',
        ),
        byUser: psychologist,
      );
      expect(db.getProgressMetric('metric_custom_1'), isNotNull);
      db.resetForTest();
      await db.init();
      expect(db.getProgressMetric('metric_custom_1')?.unit, 'soniya');
    });
  });
}
