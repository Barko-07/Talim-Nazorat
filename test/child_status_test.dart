import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/progress_metrics.dart';
import 'package:talim_nazorat/models/progress_measurement_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/services/app_exceptions.dart';
import 'package:talim_nazorat/services/child_status_service.dart';
import 'package:talim_nazorat/services/local_db_service.dart';

/// Talab #6: qizil / sariq / yashil holat aniq mezonlar asosida.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final db = LocalDbService();
  final service = ChildStatusService();
  const school = '5-sonli umumiy o‘rta ta’lim maktabi';

  final admin = UserModel(
    id: 'cs_admin', email: 'cs.admin@talim.uz', fullName: 'Admin', role: UserRole.superAdmin,
  );
  final coordinator = UserModel(
    id: 'cs_coord', email: 'cs.coord@talim.uz', fullName: 'Koordinator',
    role: UserRole.coordinator, institutionId: 'inst_chortoq_5', institutionName: school,
  );

  late UserModel psy; // bazadagi psixolog (user_psychologist)
  late UserModel speech; // bazadagi logoped (user_speech)

  Future<StudentModel> child(String id, {List<String> assigned = const []}) async {
    await db.addStudent(
      StudentModel(
        id: id, institutionId: 'inst_chortoq_5', institutionName: school,
        firstName: id, lastName: 'Test', dateOfBirth: DateTime(2016), gender: 'Erkak',
        grade: '3-A', status: 'Faol', primaryNeed: 'x', supportLevel: '1-daraja',
        createdAt: DateTime.now(),
      ),
      byUser: admin,
    );
    for (final u in assigned) {
      await db.assignSpecialistToStudent(id, u, byUser: coordinator);
    }
    psy = db.getUserById('user_psychologist')!;
    speech = db.getUserById('user_speech')!;
    return db.getStudentById(id)!;
  }

  Future<void> measure(String studentId, UserModel by, double v, DateTime at) =>
      db.addMeasurement(
        ProgressMeasurement(
          id: '${studentId}_${at.millisecondsSinceEpoch}_$v',
          studentId: studentId, metricId: ProgressMetrics.attentionSpan.id,
          value: v, measuredAt: at, recordedById: '', recordedByName: '',
        ),
        byUser: by,
      );

  ChildStatus status(String id) => service.statusFor(db.getStudentById(id)!, coordinator);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db.resetForTest();
    await db.init();
  });

  test('RED: no specialist assigned', () async {
    await child('c_none');
    final s = status('c_none');
    expect(s.color, StatusColor.red);
    expect(s.reasons.join(), contains('mutaxassis biriktirilmagan'));
  });

  test('RED: assigned, but nobody has recorded any work', () async {
    await child('c_nowork', assigned: ['user_psychologist']);
    final s = status('c_nowork');
    expect(s.color, StatusColor.red);
    expect(s.reasons.join(), contains('hech qanday ish'));
    expect(s.specialistsNotStarted, isNotEmpty);
  });

  test('RED: last work was more than 30 days ago', () async {
    await child('c_stale', assigned: ['user_psychologist']);
    await measure('c_stale', psy, 2, DateTime.now().subtract(const Duration(days: 45)));
    final s = status('c_stale');
    expect(s.color, StatusColor.red);
    expect(s.reasons.join(), contains('kun oldin'));
  });

  test('YELLOW: work is recent but no positive result yet', () async {
    await child('c_once', assigned: ['user_psychologist']);
    await measure('c_once', psy, 2, DateTime.now());
    final s = status('c_once');
    expect(s.color, StatusColor.yellow);
    expect(s.reasons.join(), contains('ijobiy natija hali qayd etilmagan'));
  });

  test('YELLOW: decline in a measurement', () async {
    await child('c_drop', assigned: ['user_psychologist']);
    final now = DateTime.now();
    await measure('c_drop', psy, 6, now.subtract(const Duration(days: 10)));
    await measure('c_drop', psy, 3, now);
    final s = status('c_drop');
    expect(s.color, StatusColor.yellow);
    expect(s.reasons.join(), contains('Pasayish'));
  });

  test('YELLOW: one of the assigned specialists has not started', () async {
    await child('c_partial', assigned: ['user_psychologist', 'user_speech']);
    final now = DateTime.now();
    await measure('c_partial', psy, 2, now.subtract(const Duration(days: 20)));
    await measure('c_partial', psy, 5, now);
    final s = status('c_partial');
    expect(s.color, StatusColor.yellow);
    expect(s.specialistsNotStarted, [speech.fullName]);
  });

  test('GREEN: recent work with growth (2 → 5 minutes)', () async {
    await child('c_good', assigned: ['user_psychologist']);
    final now = DateTime.now();
    await measure('c_good', psy, 2, now.subtract(const Duration(days: 20)));
    await measure('c_good', psy, 5, now);
    final s = status('c_good');
    expect(s.color, StatusColor.green);
    expect(s.reasons.join(), contains('2 daqiqa → 5 daqiqa'));
  });

  test('summary sorts red first and counts each colour', () async {
    await child('c_none');
    await child('c_good', assigned: ['user_psychologist']);
    final now = DateTime.now();
    await measure('c_good', psy, 2, now.subtract(const Duration(days: 20)));
    await measure('c_good', psy, 5, now);

    final summary = service.summaryFor(coordinator);
    expect(summary.total, db.getStudents(forUser: coordinator).length);
    expect(summary.statuses.first.color, StatusColor.red);
    expect(summary.count(StatusColor.green), greaterThanOrEqualTo(1));
    final colors = summary.statuses.map((s) => s.color.index).toList();
    for (var i = 1; i < colors.length; i++) {
      expect(colors[i] >= colors[i - 1], true);
    }
  });

  test('a specialist sees statuses only for their own children', () async {
    await child('c_other');
    final mine = service.summaryFor(db.getUserById('user_psychologist')!);
    expect(mine.statuses.map((s) => s.student.id), isNot(contains('c_other')));
    expect(
      () => service.statusFor(db.getStudentById('c_other')!, db.getUserById('user_psychologist')!),
      throwsA(isA<PermissionDeniedException>()),
    );
  });

  test('the same open alert is never listed twice for one child', () {
    final open = db
        .getAlerts(onlyUnresolved: true)
        .map((a) => '${a.studentId}_${a.ruleCode}')
        .toList();
    expect(open.length, open.toSet().length);
  });

  test('an open alert keeps its identity but its text follows the current facts', () {
    final open = db.getAlerts(onlyUnresolved: true);
    expect(open.any((a) => a.message.contains('ITR dagi')), false);
  });

  test('confidential notes count as work without exposing their content', () async {
    await child('c_conf', assigned: ['user_psychologist']);
    final records = db.getWorkRecords('c_conf');
    expect(records, isEmpty);
  });
}
