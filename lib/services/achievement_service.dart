import '../models/achievement_model.dart';
import '../models/curriculum_model.dart';
import '../models/user_model.dart';
import 'access_control_service.dart';
import 'app_exceptions.dart';
import 'dynamics_service.dart';
import 'local_db_service.dart';

/// Yutuqlar pasportini shakllantiradi: qo'lda kiritilgan yutuqlar + mavjud natijalardan
/// avtomatik aniqlanganlar. Avtomatik yozuvlar saqlanmaydi — har safar natijalardan
/// hisoblanadi, shuning uchun natija o'zgarsa pasport ham to'g'ri bo'lib qoladi.
class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final _db = LocalDbService();
  final _access = AccessControlService();

  /// Shaxsiy rekord yutuq deb hisoblanishi uchun birinchi natijaga nisbatan yaxshilanish
  static const double personalBestThreshold = DynamicsService.defaultRelativeThreshold;

  AchievementPassport passportFor(String studentId, UserModel viewer) {
    final student = _db.getStudentById(studentId);
    if (student == null) throw const NotFoundException('O‘quvchi topilmadi.');
    if (!_access.canViewStudent(viewer, student)) {
      throw const PermissionDeniedException('bu o‘quvchi ma’lumotlarini ko‘rish huquqi yo‘q.');
    }

    final entries = <Achievement>[
      ..._db.getManualAchievements(studentId),
      ..._subjectLevelUps(studentId),
      ..._masteredTasks(studentId),
      ..._completedGoals(studentId),
      ..._personalBests(studentId),
    ]..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    return AchievementPassport(
      studentId: studentId,
      studentName: student.fullName,
      entries: entries,
    );
  }

  /// Fan bo'yicha daraja ko'tarilishi
  List<Achievement> _subjectLevelUps(String studentId) {
    final levels = _db.getSubjectLevels(forUser: _system, studentId: studentId);
    final result = <Achievement>[];
    for (final subject in levels.map((l) => l.subject).toSet()) {
      final series = levels.where((l) => l.subject == subject).toList();
      for (var i = 1; i < series.length; i++) {
        final prev = series[i - 1].confirmedGrade;
        final cur = series[i].confirmedGrade;
        if (cur > prev) {
          result.add(Achievement(
            id: 'auto_level_${series[i].id}',
            studentId: studentId,
            category: AchievementCategory.subject,
            title: '$subject: ${_gradeText(prev)} → ${_gradeText(cur)}',
            description: 'Bilim darajasi davlat ta’lim standarti talablari bo‘yicha ko‘tarildi.',
            achievedAt: series[i].assessedAt,
            isAutomatic: true,
            recordedById: series[i].assessedById,
            recordedByName: series[i].assessedByName,
          ));
        }
      }
    }
    return result;
  }

  /// To'liq o'zlashtirilgan fan topshiriqlari
  List<Achievement> _masteredTasks(String studentId) => [
    for (final t in _db.getSubjectTasks(forUser: _system, studentId: studentId))
      if (t.result == Mastery.mastered)
        Achievement(
          id: 'auto_task_${t.id}',
          studentId: studentId,
          category: AchievementCategory.task,
          title: '${t.subject}: ${t.title}',
          description: '${t.levelGrade}-sinf darajasidagi topshiriq to‘liq o‘zlashtirildi.',
          achievedAt: t.completedAt ?? t.assignedAt,
          isAutomatic: true,
          recordedById: t.assignedById,
          recordedByName: t.assignedByName,
        ),
  ];

  /// Bajarilgan ITR maqsadlari
  List<Achievement> _completedGoals(String studentId) => [
    for (final plan in _db.getIepPlans(forUser: _system, studentId: studentId))
      for (final o in plan.objectives)
        if (o.isCompleted)
          Achievement(
            id: 'auto_goal_${o.id}',
            studentId: studentId,
            category: AchievementCategory.goal,
            title: o.title,
            description: o.evidenceNotes ?? o.successCriteria,
            achievedAt: o.targetDate,
            isAutomatic: true,
            recordedById: o.responsibleSpecialistId,
            recordedByName: o.responsibleSpecialistName,
          ),
  ];

  /// Har bir ko'rsatkich bo'yicha shaxsiy rekord (birinchi natijaga nisbatan sezilarli yaxshilanish)
  List<Achievement> _personalBests(String studentId) {
    final result = <Achievement>[];
    final measurements = _db.getMeasurements(forUser: _system, studentId: studentId);
    for (final metricId in measurements.map((m) => m.metricId).toSet()) {
      final metric = _db.getProgressMetric(metricId);
      if (metric == null) continue;
      final series = measurements.where((m) => m.metricId == metricId).toList();
      if (series.length < 2) continue;
      final first = series.first;
      final best = series.reduce((a, b) {
        final better = metric.higherIsBetter ? b.value > a.value : b.value < a.value;
        return better ? b : a;
      });
      final gain = metric.higherIsBetter ? best.value - first.value : first.value - best.value;
      final base = first.value.abs() > 0 ? first.value.abs() : 1;
      if (best.id == first.id || gain / base < personalBestThreshold) continue;
      result.add(Achievement(
        id: 'auto_best_${best.id}',
        studentId: studentId,
        category: AchievementCategory.progress,
        title: '${metric.name}: ${_num(first.value)} → ${_num(best.value)} ${metric.unit}',
        description: 'Shaxsiy eng yaxshi natija.',
        achievedAt: best.measuredAt,
        isAutomatic: true,
        recordedById: best.recordedById,
        recordedByName: best.recordedByName,
      ));
    }
    return result;
  }

  String _gradeText(int g) => g == 0 ? '1-sinfgacha' : '$g-sinf darajasi';

  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// Hisob uchun ichki o'quvchi: chaqiruvchi bolani ko'rish huquqini oldin tekshiradi
  static final _system = UserModel(
    id: '__achievements__',
    email: 'achievements@system',
    fullName: 'Yutuqlar',
    role: UserRole.superAdmin,
  );
}
