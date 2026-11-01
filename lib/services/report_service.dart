import '../models/user_model.dart';
import '../models/work_record_model.dart';
import '../models/workspace_model.dart';
import 'access_control_service.dart';
import 'app_exceptions.dart';
import 'child_status_service.dart';
import 'dynamics_service.dart';
import 'local_db_service.dart';
import 'workspace_service.dart';

/// Mutaxassis faoliyati (hisobot davri bo'yicha)
class SpecialistActivity {
  final String userId;
  final String fullName;
  final String role;
  final int childrenAssigned;
  final int childrenWorkedWith;
  final Map<WorkKind, int> recordsByKind;
  final DateTime? lastActivity;

  const SpecialistActivity({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.childrenAssigned,
    required this.childrenWorkedWith,
    required this.recordsByKind,
    required this.lastActivity,
  });

  int get totalRecords => recordsByKind.values.fold(0, (a, b) => a + b);

  /// Biriktirilgan bolalarning qancha qismi bilan ishlangan (0..1)
  double get coverage =>
      childrenAssigned == 0 ? 0 : childrenWorkedWith / childrenAssigned;
}

/// Umumiy hisobot (talab #12). Faqat ko'ruvchi ko'ra oladigan bolalar bo'yicha.
class MonitoringReport {
  final DateTime from;
  final DateTime to;
  final int totalChildren;
  final int childrenWorkedWith;
  final List<String> notWorkedWithNames;
  final Map<StatusColor, int> statusCounts;
  final Map<WorkKind, int> workCounts;
  final Map<DynamicsStatus, int> dynamicsCounts;
  final int iepObjectivesTotal;
  final int iepObjectivesCompleted;
  final Map<String, int> referralsByStatus;
  final List<SpecialistActivity> specialists;

  const MonitoringReport({
    required this.from,
    required this.to,
    required this.totalChildren,
    required this.childrenWorkedWith,
    required this.notWorkedWithNames,
    required this.statusCounts,
    required this.workCounts,
    required this.dynamicsCounts,
    required this.iepObjectivesTotal,
    required this.iepObjectivesCompleted,
    required this.referralsByStatus,
    required this.specialists,
  });

  int get childrenNotWorkedWith => totalChildren - childrenWorkedWith;

  double get iepCompletionRate =>
      iepObjectivesTotal == 0 ? 0 : iepObjectivesCompleted / iepObjectivesTotal;
}

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final _db = LocalDbService();
  final _status = ChildStatusService();
  final _dynamics = DynamicsService();
  final _workspaces = WorkspaceService();

  /// Hisobot. Davr berilmasa — oxirgi 30 kun.
  /// Rahbariyat butun maktabni, mutaxassis faqat o'z bolalarini va o'z faoliyatini ko'radi.
  MonitoringReport build(UserModel viewer, {DateTime? from, DateTime? to}) {
    if (!_workspaces.canUse(viewer, WorkspaceModule.reports)) {
      throw const PermissionDeniedException('hisobotlarni ko‘rish huquqi yo‘q.');
    }
    final end = to ?? DateTime.now();
    final start = from ?? end.subtract(const Duration(days: 30));
    if (start.isAfter(end)) {
      throw const ValidationException('Hisobot davrining boshlanishi oxiridan keyin bo‘lmasligi kerak.');
    }
    bool inPeriod(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

    final children = _db.getStudents(forUser: viewer);
    final childIds = children.map((c) => c.id).toSet();

    // Ish yozuvlari (davr ichida)
    final recordsByChild = {
      for (final c in children)
        c.id: _db.getWorkRecords(c.id).where((r) => inPeriod(r.at)).toList(),
    };
    final workedWith = children.where((c) => recordsByChild[c.id]!.isNotEmpty).toList();
    final workCounts = <WorkKind, int>{};
    for (final records in recordsByChild.values) {
      for (final r in records) {
        workCounts[r.kind] = (workCounts[r.kind] ?? 0) + 1;
      }
    }

    // Holat ranglari
    final summary = _status.summaryFor(viewer, now: end);
    final statusCounts = {for (final c in StatusColor.values) c: summary.count(c)};

    // Dinamika: har bir bola va ko'rsatkich bo'yicha holat
    final dynamicsCounts = {for (final s in DynamicsStatus.values) s: 0};
    for (final c in children) {
      final measurements = _db.getMeasurements(forUser: viewer, studentId: c.id)
          .where((m) => !m.measuredAt.isAfter(end));
      for (final metricId in measurements.map((m) => m.metricId).toSet()) {
        final metric = _db.getProgressMetric(metricId);
        final points = measurements
            .where((m) => m.metricId == metricId)
            .map((m) => DataPoint(m.measuredAt, m.value))
            .toList();
        final r = _dynamics.evaluate(points, higherIsBetter: metric?.higherIsBetter ?? true);
        dynamicsCounts[r.status] = dynamicsCounts[r.status]! + 1;
      }
    }

    // ITR maqsadlari
    var objectivesTotal = 0;
    var objectivesDone = 0;
    for (final plan in _db.getIepPlans(forUser: viewer)) {
      objectivesTotal += plan.objectives.length;
      objectivesDone += plan.objectives.where((o) => o.isCompleted).length;
    }

    // Yo'naltirishlar
    final referralsByStatus = <String, int>{};
    for (final r in _db.getReferrals(forUser: viewer)) {
      if (!childIds.contains(r.studentId) || !inPeriod(r.createdAt)) continue;
      referralsByStatus[r.status] = (referralsByStatus[r.status] ?? 0) + 1;
    }

    // Mutaxassislar faoliyati: rahbariyat — barcha mutaxassislar, mutaxassis — faqat o'zi
    final staff = AccessControlService.childFacingRoles.contains(viewer.role)
        ? [viewer]
        : _db
              .getUsers(forUser: viewer)
              .where((u) => AccessControlService.childFacingRoles.contains(u.role))
              .toList();
    final specialists = staff.map((u) {
      final mine = [
        for (final records in recordsByChild.values)
          ...records.where((r) => r.userId == u.id),
      ];
      final byKind = <WorkKind, int>{};
      for (final r in mine) {
        byKind[r.kind] = (byKind[r.kind] ?? 0) + 1;
      }
      final workedChildren = {
        for (final e in recordsByChild.entries)
          if (e.value.any((r) => r.userId == u.id)) e.key,
      };
      final assigned = children
          .where((c) => c.assignedSpecialistIds.contains(u.id) || u.assignedStudentIds.contains(c.id))
          .length;
      return SpecialistActivity(
        userId: u.id,
        fullName: u.fullName,
        role: u.role.label,
        childrenAssigned: assigned,
        childrenWorkedWith: workedChildren.length,
        recordsByKind: byKind,
        lastActivity: mine.isEmpty
            ? null
            : mine.map((r) => r.at).reduce((a, b) => a.isAfter(b) ? a : b),
      );
    }).toList()
      ..sort((a, b) => b.totalRecords.compareTo(a.totalRecords));

    return MonitoringReport(
      from: start,
      to: end,
      totalChildren: children.length,
      childrenWorkedWith: workedWith.length,
      notWorkedWithNames: children
          .where((c) => recordsByChild[c.id]!.isEmpty)
          .map((c) => c.fullName)
          .toList(),
      statusCounts: statusCounts,
      workCounts: workCounts,
      dynamicsCounts: dynamicsCounts,
      iepObjectivesTotal: objectivesTotal,
      iepObjectivesCompleted: objectivesDone,
      referralsByStatus: referralsByStatus,
      specialists: specialists,
    );
  }
}
