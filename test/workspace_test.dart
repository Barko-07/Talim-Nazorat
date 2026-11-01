import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/progress_metrics.dart';
import 'package:talim_nazorat/core/constants/psychological_questions_seed.dart';
import 'package:talim_nazorat/core/constants/specialist_workspaces.dart';
import 'package:talim_nazorat/models/curriculum_model.dart';
import 'package:talim_nazorat/models/progress_measurement_model.dart';
import 'package:talim_nazorat/models/referral_model.dart';
import 'package:talim_nazorat/models/session_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/subject_task_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/models/workspace_model.dart';
import 'package:talim_nazorat/services/access_control_service.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/workspace_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const school = '5-sonli umumiy o‘rta ta’lim maktabi';
  UserModel user(String id, UserRole role) => UserModel(
        id: id, email: '$id@talim.uz', fullName: id, role: role,
        institutionId: 'inst_chortoq_5', institutionName: school,
      );

  group('Workspace definitions', () {
    test('every role has a workspace', () {
      for (final r in UserRole.values) {
        expect(SpecialistWorkspaces.forRole(r).role, r);
      }
    });

    test('each specialist has their own functions', () {
      final psy = SpecialistWorkspaces.forRole(UserRole.psychologist);
      expect(psy.canEdit(WorkspaceModule.psychAssessment), true);
      expect(psy.canEdit(WorkspaceModule.observationJournal), true);
      expect(psy.canEdit(WorkspaceModule.subjectLevel), false);
      expect(psy.has(WorkspaceModule.subjectLevel), true); // ko'radi

      final speech = SpecialistWorkspaces.forRole(UserRole.speechTherapist);
      expect(speech.canEdit(WorkspaceModule.speechAssessment), true);
      expect(speech.has(WorkspaceModule.psychAssessment), false);

      final defect = SpecialistWorkspaces.forRole(UserRole.specialEducation);
      expect(defect.canEdit(WorkspaceModule.developmentAssessment), true);

      final sped = SpecialistWorkspaces.forRole(UserRole.specialEdTeacher);
      expect(sped.canEdit(WorkspaceModule.subjectLevel), true);
      expect(sped.canEdit(WorkspaceModule.subjectTasks), true);
      expect(sped.canEdit(WorkspaceModule.iep), true);
      expect(sped.has(WorkspaceModule.observationJournal), false);

      final admin = SpecialistWorkspaces.forRole(UserRole.institutionAdmin);
      expect(admin.canEdit(WorkspaceModule.userManagement), true);
      expect(admin.has(WorkspaceModule.caseload), false);

      expect(SpecialistWorkspaces.forRole(UserRole.superAdmin)
          .canEdit(WorkspaceModule.curriculumAdmin), true);
      final reviewer = SpecialistWorkspaces.forRole(UserRole.reviewer);
      expect(reviewer.modules.values.every((a) => a == ModuleAccess.view), true);
      expect(SpecialistWorkspaces.forRole(UserRole.parent).modules, isEmpty);
    });

    test('every child-facing workspace has standard questions in its own areas', () {
      final bank = PsychologicalQuestionsSeed.initialQuestions;
      for (final r in [UserRole.psychologist, UserRole.speechTherapist,
          UserRole.specialEducation, UserRole.specialEdTeacher]) {
        final ws = SpecialistWorkspaces.forRole(r);
        for (final d in ws.assessmentDomains) {
          expect(bank.where((q) => q.domain == d && q.isStandard), isNotEmpty,
              reason: '${r.label}: $d');
        }
      }
    });

    test('workspace metrics and referral targets are valid', () {
      final metricIds = ProgressMetrics.all.map((m) => m.id).toSet();
      for (final r in UserRole.values) {
        final ws = SpecialistWorkspaces.forRole(r);
        expect(metricIds.containsAll(ws.metricIds), true, reason: r.label);
        expect(ws.referralTargets.contains(r.label), false,
            reason: '${r.label} o‘ziga yo‘naltirmaydi');
      }
      expect(SpecialistWorkspaces.forRole(UserRole.psychologist).referralTargets,
          contains(ReferralTargets.medical));
    });

    test('special-education teacher role is stored and loaded correctly', () {
      expect(UserRole.specialEdTeacher.code, 'SPECIAL_ED_TEACHER');
      expect(UserRoleExtension.fromCode('SPECIAL_ED_TEACHER'), UserRole.specialEdTeacher);
      expect(UserRole.specialEdTeacher.label, 'Maxsus ta’lim o‘qituvchisi');
    });

    test('special-education teacher can record subject levels and write plans', () {
      final access = AccessControlService();
      final sped = user('sped', UserRole.specialEdTeacher)
          .copyWith(assignedStudentIds: ['s']);
      final student = StudentModel(
        id: 's', institutionId: 'inst_chortoq_5', institutionName: school,
        firstName: 'A', lastName: 'B', dateOfBirth: DateTime(2016), gender: 'Erkak',
        grade: '3-A', status: 'Faol', primaryNeed: 'x', supportLevel: '1-daraja',
        createdAt: DateTime.now(),
      );
      expect(access.canAssessSubjectLevel(sped, student), true);
      expect(access.canManageIep(sped, null), true);
      expect(access.canEditDevelopmentProfile(sped, student), false);
    });
  });

  group('Personal dashboard', () {
    final db = LocalDbService();
    final ws = WorkspaceService();
    final psy = user('psy_ws', UserRole.psychologist);
    final sped = user('sped_ws', UserRole.specialEdTeacher);
    final admin = UserModel(
      id: 'adm_ws_super', email: 'adm.super@talim.uz', fullName: 'Admin', role: UserRole.superAdmin,
    );

    Future<StudentModel> student(String id, {String grade = '3-A', List<String> assigned = const []}) async {
      final s = StudentModel(
        id: id, institutionId: 'inst_chortoq_5', institutionName: school,
        firstName: id, lastName: 'Test', dateOfBirth: DateTime(2016), gender: 'Erkak',
        grade: grade, status: 'Faol', primaryNeed: 'x', supportLevel: '1-daraja',
        createdAt: DateTime.now(), assignedSpecialistIds: assigned,
      );
      await db.addStudent(s, byUser: admin);
      return s;
    }

    Future<void> measure(String studentId, String metricId, double v, DateTime at) =>
        db.addMeasurement(
          ProgressMeasurement(
            id: '${studentId}_${metricId}_${at.millisecondsSinceEpoch}',
            studentId: studentId, metricId: metricId, value: v, measuredAt: at,
            recordedById: '', recordedByName: '',
          ),
          byUser: psy,
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db.resetForTest();
      await db.init();
    });

    test('caseload is only the children assigned to the specialist', () async {
      await student('mine', assigned: [psy.id]);
      await student('not_mine');
      final ids = ws.caseloadFor(psy).map((s) => s.id).toSet();
      expect(ids, contains('mine'));
      expect(ids, isNot(contains('not_mine')));
    });

    test('a child nobody has worked with is flagged, and the flag clears after work', () async {
      await student('fresh', assigned: [psy.id]);
      var d = ws.dashboardFor(psy);
      expect(d.notWorkedWith.map((s) => s.id), contains('fresh'));

      await measure('fresh', ProgressMetrics.attentionSpan.id, 2, DateTime.now());
      d = ws.dashboardFor(psy);
      expect(d.notWorkedWith.map((s) => s.id), isNot(contains('fresh')));
    });

    test('decline in the specialist\'s own metric shows up', () async {
      await student('drop', assigned: [psy.id]);
      final now = DateTime.now();
      await measure('drop', ProgressMetrics.attentionSpan.id, 6, now.subtract(const Duration(days: 20)));
      await measure('drop', ProgressMetrics.attentionSpan.id, 3, now);
      final kinds = ws.dashboardFor(psy).attention
          .where((a) => a.student.id == 'drop').map((a) => a.kind);
      expect(kinds, contains(AttentionKind.decline));
    });

    test('psychologist is reminded to fill in the access profile', () async {
      await student('noprofile', assigned: [psy.id]);
      final kinds = ws.dashboardFor(psy).attention
          .where((a) => a.student.id == 'noprofile').map((a) => a.kind);
      expect(kinds, contains(AttentionKind.missingProfile));
    });

    test('referral sent to the role arrives in that specialist\'s dashboard', () async {
      await student('ref', assigned: [psy.id]);
      await db.addReferral(byUser: admin, ReferralModel(
        id: 'r1', studentId: 'ref', studentName: 'ref', fromSpecialistName: 'Logoped',
        toSpecialistType: UserRole.psychologist.label, reason: 'Xavotir belgilari',
        priority: 'O‘rta', status: 'Yuborildi', createdAt: DateTime.now(),
      ));
      expect(ws.dashboardFor(psy).incomingReferrals.map((r) => r.id), contains('r1'));
      expect(ws.dashboardFor(sped).incomingReferrals.map((r) => r.id), isNot(contains('r1')));
    });

    test('upcoming sessions for the next 7 days are listed', () async {
      final s = await student('sess', assigned: [psy.id]);
      await db.addSession(byUser: psy, SessionModel(
        id: 'sess1', studentId: s.id, studentName: s.fullName, specialistId: psy.id,
        specialistName: psy.fullName, specialistRole: psy.role.label,
        scheduledAt: DateTime.now().add(const Duration(days: 2)),
        status: 'Rejalashtirilgan', topic: 'Individual psixokorreksion mashg‘ulot',
      ));
      expect(ws.dashboardFor(psy).upcomingSessions.map((x) => x.id), contains('sess1'));
    });

    test('special-ed teacher sees missing subject levels, then the grade gap', () async {
      await student('g7', grade: '7-A', assigned: [sped.id]);
      var kinds = ws.dashboardFor(sped).attention
          .where((a) => a.student.id == 'g7').map((a) => a.kind);
      expect(kinds, contains(AttentionKind.subjectLevelMissing));

      final math = db.getCurriculumStandards(subject: SchoolSubjects.matematika);
      await db.saveSubjectLevel(
        studentId: 'g7',
        subject: SchoolSubjects.matematika,
        results: {
          for (final s in math)
            s.id: s.grade <= 3 ? Mastery.mastered : Mastery.notYet,
        },
        byUser: sped,
      );
      final items = ws.dashboardFor(sped).attention.where((a) => a.student.id == 'g7');
      expect(items.map((a) => a.kind), contains(AttentionKind.largeGap));
      expect(items.firstWhere((a) => a.kind == AttentionKind.largeGap).reason,
          contains('3-sinf darajasida'));
    });

    test('special-ed teacher gives a task at the child\'s real level and records the result', () async {
      await student('task_child', grade: '7-A', assigned: [sped.id]);
      final task = await db.assignSubjectTask(
        SubjectTask(
          id: 't1', studentId: 'task_child', subject: SchoolSubjects.matematika,
          levelGrade: 3, title: 'Ko‘paytirish jadvali: 6 va 7',
          assignedById: '', assignedByName: '', assignedAt: DateTime.now(),
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        byUser: sped,
      );
      expect(task.assignedById, sped.id);

      // Muddati o'tgan, natija kiritilmagan
      var kinds = ws.dashboardFor(sped).attention
          .where((a) => a.student.id == 'task_child').map((a) => a.kind);
      expect(kinds, contains(AttentionKind.overdueTasks));

      await db.completeSubjectTask('t1', Mastery.partial, note: '6 ga yaxshi', byUser: sped);
      final tasks = db.getSubjectTasks(forUser: sped, studentId: 'task_child');
      expect(tasks.single.result, Mastery.partial);
      kinds = ws.dashboardFor(sped).attention
          .where((a) => a.student.id == 'task_child').map((a) => a.kind);
      expect(kinds, isNot(contains(AttentionKind.overdueTasks)));
    });

    test('psychologist cannot give subject tasks', () async {
      await student('task_child2', assigned: [psy.id]);
      expect(
        () => db.assignSubjectTask(
          SubjectTask(
            id: 't2', studentId: 'task_child2', subject: SchoolSubjects.matematika,
            levelGrade: 2, title: 'x', assignedById: '', assignedByName: '',
            assignedAt: DateTime.now(),
          ),
          byUser: psy,
        ),
        throwsException,
      );
    });

    test('leadership has no personal caseload, specialists do', () {
      final admin = user('adm_ws', UserRole.institutionAdmin);
      expect(ws.dashboardFor(admin).caseload, isEmpty);
      expect(ws.canUse(admin, WorkspaceModule.userManagement, edit: true), true);
      expect(ws.canUse(psy, WorkspaceModule.userManagement), false);
    });
  });
}
