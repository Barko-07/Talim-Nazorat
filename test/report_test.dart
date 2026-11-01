import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/progress_metrics.dart';
import 'package:talim_nazorat/models/progress_measurement_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/models/work_record_model.dart';
import 'package:talim_nazorat/services/app_exceptions.dart';
import 'package:talim_nazorat/services/child_status_service.dart';
import 'package:talim_nazorat/services/dynamics_service.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/report_export_service.dart';
import 'package:talim_nazorat/services/report_service.dart';

/// Talab #12: hisobotlar va umumiy monitoring
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final db = LocalDbService();
  final reports = ReportService();
  final export = ReportExportService();
  const school = '5-sonli umumiy o‘rta ta’lim maktabi';

  final director = UserModel(
    id: 'rep_dir', email: 'rep.dir@talim.uz', fullName: 'Direktor',
    role: UserRole.institutionAdmin, institutionId: 'inst_chortoq_5', institutionName: school,
  );
  final parent = UserModel(id: 'rep_parent', email: 'p@talim.uz', fullName: 'Ota-ona', role: UserRole.parent);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db.resetForTest();
    await db.init();
  });

  Future<void> measure(String child, double v, DateTime at) => db.addMeasurement(
        ProgressMeasurement(
          id: '${child}_${at.millisecondsSinceEpoch}', studentId: child,
          metricId: ProgressMetrics.attentionSpan.id, value: v, measuredAt: at,
          recordedById: '', recordedByName: '',
        ),
        byUser: db.getUserById('user_psychologist')!,
      );

  test('totals: children, worked with, not yet worked with', () async {
    final now = DateTime.now();
    await measure('student_02', 2, now.subtract(const Duration(days: 5)));
    final r = reports.build(director, to: now);

    final visible = db.getStudents(forUser: director).length;
    expect(r.totalChildren, visible);
    expect(r.childrenWorkedWith + r.childrenNotWorkedWith, visible);
    expect(r.childrenWorkedWith, greaterThanOrEqualTo(1));
    expect(r.workCounts[WorkKind.measurement], greaterThanOrEqualTo(1));
    expect(r.notWorkedWithNames.length, r.childrenNotWorkedWith);
    final colours = r.statusCounts.values.fold(0, (a, b) => a + b);
    expect(colours, visible);
  });

  test('period filter: work outside the period is not counted', () async {
    await measure('student_02', 2, DateTime(2026, 1, 10));
    final r = reports.build(director, from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 31));
    expect(r.workCounts[WorkKind.measurement] ?? 0, 0);
  });

  test('dynamics distribution counts growth', () async {
    final now = DateTime.now();
    await measure('student_02', 2, now.subtract(const Duration(days: 20)));
    await measure('student_02', 5, now.subtract(const Duration(days: 1)));
    final r = reports.build(director, to: now);
    expect(r.dynamicsCounts[DynamicsStatus.growth], 1);
  });

  test('specialist activity: who worked with how many of their children', () async {
    final now = DateTime.now();
    await measure('student_02', 2, now.subtract(const Duration(days: 3)));
    final r = reports.build(director, to: now);
    final psy = r.specialists.firstWhere((s) => s.userId == 'user_psychologist');
    expect(psy.childrenWorkedWith, greaterThanOrEqualTo(1));
    expect(psy.childrenAssigned, greaterThanOrEqualTo(1));
    expect(psy.recordsByKind[WorkKind.measurement], 1);
    expect(psy.lastActivity, isNotNull);
  });

  test('a specialist sees only their own activity and their own children', () {
    final psy = db.getUserById('user_psychologist')!;
    final r = reports.build(psy);
    expect(r.specialists.map((s) => s.userId), [psy.id]);
    expect(r.totalChildren, db.getStudents(forUser: psy).length);
  });

  test('roles without the reports module cannot build reports', () {
    expect(() => reports.build(parent), throwsA(isA<PermissionDeniedException>()));
  });

  test('invalid period is rejected', () {
    expect(
      () => reports.build(director, from: DateTime(2026, 5, 1), to: DateTime(2026, 4, 1)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('CSV exports contain the key figures and open correctly in Excel', () async {
    final r = reports.build(director);
    final summary = export.generateMonitoringReportCsv(r);
    expect(summary.startsWith(ReportExportService.utf8Bom), true);
    expect(summary, contains('Jami bolalar'));
    expect(summary, contains('Hali ishlanmagan'));
    expect(summary, contains('Holat: ${StatusColor.red.label}'));

    final activity = export.generateSpecialistActivityCsv(r);
    expect(activity, contains('Qamrov (%)'));
    expect(activity.split('\n').where((l) => l.trim().isNotEmpty).length, r.specialists.length + 1);
  });

  test('CSV formula injection is neutralised', () async {
    final s = db.getStudentById('student_01')!;
    final csv = export.generateStudentsCsv([
      StudentModel.fromJson(s.toJson()).copyWith(lastName: '=HYPERLINK("http://evil")'),
    ]);
    expect(csv, isNot(contains(',"=HYPERLINK')));
    expect(csv, contains("'=HYPERLINK"));
  });
}
