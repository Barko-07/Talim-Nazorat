import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/progress_metrics.dart';
import 'package:talim_nazorat/models/achievement_model.dart';
import 'package:talim_nazorat/models/curriculum_model.dart';
import 'package:talim_nazorat/models/progress_measurement_model.dart';
import 'package:talim_nazorat/models/subject_task_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/services/achievement_service.dart';
import 'package:talim_nazorat/services/app_exceptions.dart';
import 'package:talim_nazorat/services/local_db_service.dart';

/// Talab #11: "Mening yutuqlar pasportim"
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final db = LocalDbService();
  final service = AchievementService();
  const school = '5-sonli umumiy o‘rta ta’lim maktabi';
  const child = 'student_01';

  UserModel staff(String id, UserRole role, {List<String> students = const [child]}) => UserModel(
        id: id, email: '$id@talim.uz', fullName: id, role: role,
        institutionId: 'inst_chortoq_5', institutionName: school, assignedStudentIds: students,
      );
  final psy = staff('ach_psy', UserRole.psychologist);
  final sped = staff('ach_sped', UserRole.specialEdTeacher);
  final stranger = staff('ach_other', UserRole.psychologist, students: const []);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db.resetForTest();
    await db.init();
  });

  List<Achievement> auto(AchievementCategory c) => service
      .passportFor(child, psy)
      .entries
      .where((e) => e.isAutomatic && e.category == c)
      .toList();

  test('subject level going up becomes an achievement', () async {
    final math = db.getCurriculumStandards(subject: SchoolSubjects.matematika);
    Map<String, Mastery> upTo(int g) =>
        {for (final s in math) s.id: s.grade <= g ? Mastery.mastered : Mastery.notYet};
    await db.saveSubjectLevel(studentId: child, subject: SchoolSubjects.matematika, results: upTo(1), byUser: sped);
    await db.saveSubjectLevel(studentId: child, subject: SchoolSubjects.matematika, results: upTo(2), byUser: sped);
    final entries = auto(AchievementCategory.subject);
    expect(entries.single.title, contains('1-sinf darajasi → 2-sinf darajasi'));
  });

  test('only fully mastered tasks count', () async {
    Future<void> task(String id, Mastery result) async {
      await db.assignSubjectTask(
        SubjectTask(
          id: id, studentId: child, subject: SchoolSubjects.matematika, levelGrade: 2,
          title: 'Topshiriq $id', assignedById: '', assignedByName: '', assignedAt: DateTime.now(),
        ),
        byUser: sped,
      );
      await db.completeSubjectTask(id, result, byUser: sped);
    }
    await task('t_full', Mastery.mastered);
    await task('t_half', Mastery.partial);
    final titles = auto(AchievementCategory.task).map((e) => e.title);
    expect(titles, contains('${SchoolSubjects.matematika}: Topshiriq t_full'));
    expect(titles.any((t) => t.contains('t_half')), false);
  });

  test('personal best (2 → 5 minutes) is recognised; tiny changes are not', () async {
    Future<void> m(String metricId, double v, int day) => db.addMeasurement(
          ProgressMeasurement(
            id: '${metricId}_$day', studentId: child, metricId: metricId, value: v,
            measuredAt: DateTime(2026, 9, 1).add(Duration(days: day)),
            recordedById: '', recordedByName: '',
          ),
          byUser: psy,
        );
    await m(ProgressMetrics.attentionSpan.id, 2, 0);
    await m(ProgressMetrics.attentionSpan.id, 5, 30);
    await m(ProgressMetrics.attentionSpan.id, 4, 60); // rekord saqlanadi
    await m(ProgressMetrics.wordsRecalled.id, 10, 0);
    await m(ProgressMetrics.wordsRecalled.id, 10.5, 30); // 5% — sezilarli emas

    final titles = auto(AchievementCategory.progress).map((e) => e.title).toList();
    expect(titles, hasLength(1));
    expect(titles.single, contains('2 → 5 daqiqa'));
  });

  test('fewer meltdowns counts as progress for lower-is-better metrics', () async {
    for (final (day, v) in [(0, 6.0), (30, 2.0)]) {
      await db.addMeasurement(
        ProgressMeasurement(
          id: 'melt_$day', studentId: child, metricId: ProgressMetrics.meltdownsPerWeek.id,
          value: v, measuredAt: DateTime(2026, 9, 1).add(Duration(days: day)),
          recordedById: '', recordedByName: '',
        ),
        byUser: psy,
      );
    }
    expect(auto(AchievementCategory.progress).single.title, contains('6 → 2'));
  });

  test('completed individual-plan goals appear in the passport', () {
    final goals = auto(AchievementCategory.goal);
    final completedInSeed = db
        .getIepPlans(studentId: child)
        .expand((p) => p.objectives)
        .where((o) => o.isCompleted)
        .length;
    expect(goals.length, completedInSeed);
  });

  test('a specialist can add an achievement by hand; it is attributed to them', () async {
    await db.addAchievement(
      Achievement(
        id: 'manual_1', studentId: child, category: AchievementCategory.social,
        title: 'Maktab tadbirida she’r o‘qidi', achievedAt: DateTime(2026, 10, 20),
        recordedById: 'someone_else',
      ),
      byUser: psy,
    );
    final entry = service.passportFor(child, psy).entries.firstWhere((e) => e.id == 'manual_1');
    expect(entry.isAutomatic, false);
    expect(entry.recordedById, psy.id);

    db.resetForTest();
    await db.init();
    expect(db.getManualAchievements(child).map((a) => a.id), contains('manual_1'));
  });

  test('validation and permissions', () async {
    Achievement a(String id, {DateTime? at, String title = 'Yutuq'}) => Achievement(
          id: id, studentId: child, category: AchievementCategory.skill,
          title: title, achievedAt: at ?? DateTime.now(),
        );
    await expectLater(db.addAchievement(a('x1'), byUser: stranger),
        throwsA(isA<PermissionDeniedException>()));
    await expectLater(db.addAchievement(a('x2', title: '  '), byUser: psy),
        throwsA(isA<ValidationException>()));
    await expectLater(
        db.addAchievement(a('x3', at: DateTime.now().add(const Duration(days: 10))), byUser: psy),
        throwsA(isA<ValidationException>()));

    await db.addAchievement(a('x4'), byUser: psy);
    await expectLater(db.deleteAchievement('x4', byUser: sped),
        throwsA(isA<PermissionDeniedException>()));
    await db.deleteAchievement('x4', byUser: psy);
    expect(db.getManualAchievements(child).any((e) => e.id == 'x4'), false);
  });

  test('passport is shown only to people who can see the child', () {
    expect(() => service.passportFor(child, stranger), throwsA(isA<PermissionDeniedException>()));
  });

  test('entries are sorted newest first', () async {
    await db.addAchievement(
      Achievement(id: 'old', studentId: child, category: AchievementCategory.skill,
          title: 'Eski', achievedAt: DateTime(2025, 1, 1)),
      byUser: psy,
    );
    await db.addAchievement(
      Achievement(id: 'new', studentId: child, category: AchievementCategory.skill,
          title: 'Yangi', achievedAt: DateTime(2026, 10, 1)),
      byUser: psy,
    );
    final dates = service.passportFor(child, psy).entries.map((e) => e.achievedAt).toList();
    for (var i = 1; i < dates.length; i++) {
      expect(!dates[i].isAfter(dates[i - 1]), true);
    }
  });
}
