import '../models/monitoring_alert_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import 'access_control_service.dart';
import 'app_exceptions.dart';
import 'dynamics_service.dart';
import 'local_db_service.dart';
import 'sound_tracker_service.dart';

/// Bolaning monitoring holati (talab #6)
enum StatusColor {
  red('Qizil', 'Ish bajarilmagan yoki natijalar kiritilmagan'),
  yellow('Sariq', 'E’tibor yoki qo‘shimcha kuzatuv talab qilinadi'),
  green('Yashil', 'Ish bajarilgan va ijobiy natijalar kuzatilgan');

  final String label;
  final String meaning;
  const StatusColor(this.label, this.meaning);
}

class ChildStatus {
  final StudentModel student;
  final StatusColor color;

  /// Holat sabablari — har biri aniq mezon bo'yicha (foydalanuvchiga ko'rsatiladi)
  final List<String> reasons;
  final DateTime? lastWorkAt;
  final int assignedCount;

  /// Biriktirilgan, lekin bola bilan hali ish qayd etmagan mutaxassislar (ismlari)
  final List<String> specialistsNotStarted;

  const ChildStatus({
    required this.student,
    required this.color,
    required this.reasons,
    required this.lastWorkAt,
    required this.assignedCount,
    required this.specialistsNotStarted,
  });
}

class MonitoringSummary {
  final List<ChildStatus> statuses; // qizil -> sariq -> yashil tartibida
  const MonitoringSummary(this.statuses);

  int count(StatusColor c) => statuses.where((s) => s.color == c).length;
  int get total => statuses.length;
  List<ChildStatus> byColor(StatusColor c) =>
      statuses.where((s) => s.color == c).toList();
}

/// Holat ranglarini aniq mezonlar asosida belgilaydi:
///
/// QIZIL — quyidagilardan biri:
///   - bolaga hech qanday mutaxassis biriktirilmagan;
///   - bola bilan hech kim ish qayd etmagan;
///   - oxirgi ish [staleDays] kundan oldin bo'lgan.
/// SARIQ — qizil emas va quyidagilardan biri:
///   - biror ko'rsatkich bo'yicha "Pasayish" yoki "Samarasiz natija";
///   - hal qilinmagan monitoring signali;
///   - biriktirilgan mutaxassis bola bilan hali ishlamagan;
///   - ish olib borilmoqda, lekin ijobiy natija hali qayd etilmagan.
/// YASHIL — yaqinda ish qilingan, ijobiy natija bor (o'sish yoki bajarilgan ITR maqsadi)
///   va sariq belgilar yo'q.
class ChildStatusService {
  static final ChildStatusService _instance = ChildStatusService._internal();
  factory ChildStatusService() => _instance;
  ChildStatusService._internal();

  final _db = LocalDbService();
  final _dynamics = DynamicsService();
  final _access = AccessControlService();
  final _sounds = SoundTrackerService();

  static const int staleDays = 30;

  /// Ijobiy natija sifatida hisobga olinadigan davr
  static const int positiveWindowDays = 90;

  /// [unresolvedAlerts] — oldindan olingan ochiq signallar (ko'p bola uchun hisoblaganda
  /// har safar barcha qoidalarni qayta hisoblamaslik uchun). Berilmasa — o'zi oladi.
  ChildStatus statusFor(
    StudentModel student,
    UserModel viewer, {
    DateTime? now,
    List<MonitoringAlertModel>? unresolvedAlerts,
  }) {
    if (!_access.canViewStudent(viewer, student)) {
      throw const PermissionDeniedException('bu o‘quvchi ma’lumotlarini ko‘rish huquqi yo‘q.');
    }
    final today = now ?? DateTime.now();
    final red = <String>[];
    final yellow = <String>[];
    final positives = <String>[];

    // ---------- Ish yozuvlari ----------
    final records = _db.getWorkRecords(student.id);
    final lastWork = records.isEmpty ? null : records.last.at;
    final workedBy = records.map((r) => r.userId).toSet();

    final assigned = student.assignedSpecialistIds
        .map(_db.getUserById)
        .whereType<UserModel>()
        .where((u) => u.isActive && AccessControlService.childFacingRoles.contains(u.role))
        .toList();
    final notStarted =
        assigned.where((u) => !workedBy.contains(u.id)).map((u) => u.fullName).toList();

    if (assigned.isEmpty) {
      red.add('Bolaga hech qanday mutaxassis biriktirilmagan.');
    }
    if (lastWork == null) {
      red.add('Bola bilan hali hech qanday ish (baholash, mashg‘ulot, kuzatuv, o‘lchov) qayd etilmagan.');
    } else {
      final days = today.difference(lastWork).inDays;
      if (days > staleDays) {
        red.add('Oxirgi ish $days kun oldin qayd etilgan ($staleDays kundan ortiq).');
      }
    }

    // ---------- Dinamika ----------
    final measurements = _db.getMeasurements(forUser: _systemViewer, studentId: student.id);
    final byMetric = <String, List<DataPoint>>{};
    for (final m in measurements) {
      byMetric.putIfAbsent(m.metricId, () => []).add(DataPoint(m.measuredAt, m.value));
    }
    for (final entry in byMetric.entries) {
      final metric = _db.getProgressMetric(entry.key);
      if (metric == null) continue;
      final r = _dynamics.evaluate(
        entry.value,
        higherIsBetter: metric.higherIsBetter,
        unit: metric.unit,
      );
      _classify(r, metric.name, today, yellow, positives);
    }

    final levels = _db.getSubjectLevels(forUser: _systemViewer, studentId: student.id);
    for (final subject in levels.map((l) => l.subject).toSet()) {
      final points = levels
          .where((l) => l.subject == subject)
          .map((l) => DataPoint(l.assessedAt, l.confirmedGrade.toDouble()))
          .toList();
      final r = _dynamics.evaluate(points, absoluteThreshold: 0.5, unit: 'sinf darajasi');
      _classify(r, '$subject (bilim darajasi)', today, yellow, positives);
    }

    // ---------- Logopedik tovushlar ----------
    final soundProfile = _sounds.buildProfile(
      student.id,
      _db.getSoundEntries(forUser: _systemViewer, studentId: student.id),
    );
    for (final p in soundProfile.sounds) {
      _classify(p.dynamics, '"${p.sound.display}" tovushi', today, yellow, positives);
    }

    // ---------- ITR maqsadlari ----------
    for (final plan in _db.getIepPlans(forUser: _systemViewer, studentId: student.id)) {
      for (final o in plan.objectives) {
        if (o.isCompleted) positives.add('ITR maqsadi bajarildi: ${o.title}.');
      }
    }

    // ---------- Monitoring signallari ----------
    final alerts = (unresolvedAlerts ??
            _db.getAlerts(forUser: _systemViewer, onlyUnresolved: true))
        .where((a) => a.studentId == student.id);
    for (final title in alerts.map((a) => a.ruleTitle).toSet()) {
      yellow.add('Hal qilinmagan signal: $title.');
    }

    if (notStarted.isNotEmpty && assigned.length > notStarted.length) {
      yellow.add('Biriktirilgan, lekin hali ishlamagan: ${notStarted.join(', ')}.');
    }

    // ---------- Yakuniy rang ----------
    final StatusColor color;
    final List<String> reasons;
    if (red.isNotEmpty) {
      color = StatusColor.red;
      reasons = [...red, ...yellow];
    } else if (yellow.isNotEmpty || positives.isEmpty) {
      color = StatusColor.yellow;
      reasons = [
        ...yellow,
        if (positives.isEmpty)
          'Ish olib borilmoqda, lekin ijobiy natija hali qayd etilmagan (taqqoslash uchun natijalar yetarli emas).',
      ];
    } else {
      color = StatusColor.green;
      reasons = positives;
    }

    return ChildStatus(
      student: student,
      color: color,
      reasons: reasons,
      lastWorkAt: lastWork,
      assignedCount: assigned.length,
      specialistsNotStarted: notStarted,
    );
  }

  /// Foydalanuvchi ko'ra oladigan barcha bolalar holati (qizil -> sariq -> yashil)
  MonitoringSummary summaryFor(UserModel viewer, {DateTime? now}) {
    final alerts = _db.getAlerts(forUser: _systemViewer, onlyUnresolved: true);
    final statuses = _db
        .getStudents(forUser: viewer)
        .map((s) => statusFor(s, viewer, now: now, unresolvedAlerts: alerts))
        .toList()
      ..sort((a, b) {
        final c = a.color.index.compareTo(b.color.index);
        return c != 0 ? c : a.student.fullName.compareTo(b.student.fullName);
      });
    return MonitoringSummary(statuses);
  }

  void _classify(
    DynamicsResult r,
    String name,
    DateTime today,
    List<String> yellow,
    List<String> positives,
  ) {
    switch (r.status) {
      case DynamicsStatus.decline:
      case DynamicsStatus.ineffective:
        yellow.add('$name — ${r.status.label}: ${r.reason}');
      case DynamicsStatus.growth:
        final recent = r.latest != null &&
            today.difference(r.latest!.at).inDays <= positiveWindowDays;
        if (recent) positives.add('$name — ${r.status.label}: ${r.reason}');
      case DynamicsStatus.stable:
      case DynamicsStatus.insufficientData:
        break;
    }
  }

  /// Holatni hisoblash uchun ichki "ko'ruvchi": ma'lumotlar faqat hisob uchun o'qiladi,
  /// foydalanuvchiga ko'rsatilmaydi (statusFor chaqiruvchisi bolani ko'rish huquqini tekshiradi).
  static final _systemViewer = UserModel(
    id: '__monitoring__',
    email: 'monitoring@system',
    fullName: 'Monitoring',
    role: UserRole.superAdmin,
  );
}
