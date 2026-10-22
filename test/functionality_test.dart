import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/assessment_model.dart';
import 'package:talim_nazorat/models/session_model.dart';
import 'package:talim_nazorat/models/iep_model.dart';
import 'package:talim_nazorat/models/monitoring_alert_model.dart';
import 'package:talim_nazorat/models/referral_model.dart';
import 'package:talim_nazorat/services/access_control_service.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/monitoring_rule_engine.dart';
import 'package:talim_nazorat/services/report_export_service.dart';
import 'package:talim_nazorat/core/constants/assessment_templates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Access Control & School Isolation & Least Privilege', () {
    final access = AccessControlService();

    final superAdmin = UserModel(
      id: 'admin_1',
      email: 'admin@talim.uz',
      fullName: 'Bosh Administrator',
      role: UserRole.superAdmin,
    );

    final chortoqTeacher = UserModel(
      id: 'teacher_1',
      email: 'oqituvchi@talim.uz',
      fullName: 'Madina Karimova',
      role: UserRole.teacher,
      institutionId: 'inst_chortoq_1',
      institutionName: '1-sonli umumiy o‘rta ta’lim maktabi',
    );

    final chustPsychologist = UserModel(
      id: 'psych_1',
      email: 'psixolog@talim.uz',
      fullName: 'Shahnoza Qodirova',
      role: UserRole.psychologist,
      institutionId: 'inst_chust_12',
      institutionName: '12-sonli inklyuziv maktab',
    );

    final studentChortoq = StudentModel(
      id: 'stud_chortoq',
      institutionId: 'inst_chortoq_1',
      institutionName: '1-sonli umumiy o‘rta ta’lim maktabi',
      firstName: 'Alisher',
      lastName: 'Valiyev',
      dateOfBirth: DateTime(2015, 4, 10),
      gender: 'Erkak',
      grade: '4-B',
      status: 'Faol',
      primaryNeed: 'Diqqat yetishmasligi',
      supportLevel: '1-daraja',
      medicalNotes: 'Nevropatolog xulosasi: astenik sindrom',
      createdAt: DateTime.now(),
    );

    test('SuperAdmin has global access across all schools', () {
      expect(access.isSameInstitution(superAdmin, studentChortoq.institutionId, studentChortoq.institutionName), true);
      expect(access.canViewStudent(superAdmin, studentChortoq), true);
      expect(access.canEditStudent(superAdmin, studentChortoq), true);
    });

    test('Staff is strictly isolated to their own institution', () {
      // Teacher in same school can view student
      expect(access.isSameInstitution(chortoqTeacher, studentChortoq.institutionId, studentChortoq.institutionName), true);
      expect(access.canViewStudent(chortoqTeacher, studentChortoq), true);

      // Psychologist from another school cannot view or edit student
      expect(access.isSameInstitution(chustPsychologist, studentChortoq.institutionId, studentChortoq.institutionName), false);
      expect(access.canViewStudent(chustPsychologist, studentChortoq), false);
      expect(access.canEditStudent(chustPsychologist, studentChortoq), false);
    });

    test('Least-privilege: Sensitive medical info is restricted to authorized roles only', () {
      expect(access.canViewSensitiveMedical(superAdmin), true);
      expect(access.canViewSensitiveMedical(chustPsychologist), true);

      // Regular subject teacher cannot view sensitive medical records
      expect(access.canViewSensitiveMedical(chortoqTeacher), false);

      final parent = UserModel(
        id: 'parent_1',
        email: 'otaona@talim.uz',
        fullName: 'Zokir Valiyev',
        role: UserRole.parent,
      );
      expect(access.canViewSensitiveMedical(parent), false);
    });
  });

  group('2. Student Management, Assignment and Historical Archiving', () {
    test('Student creation, assignment and archiving preserves history', () async {
      final db = LocalDbService();
      await db.init();

      final existingSpecialist = db.getUsers().first;

      final student = StudentModel(
        id: 'stud_test_archive',
        institutionId: 'inst_chortoq_1',
        institutionName: '1-sonli maktab',
        firstName: 'Farrux',
        lastName: 'Sobirov',
        dateOfBirth: DateTime(2016, 8, 20),
        gender: 'Erkak',
        grade: '2-B',
        status: 'Faol',
        primaryNeed: 'Nutq rivojlanishi',
        supportLevel: '2-daraja',
        assignedSpecialistIds: [],
        createdAt: DateTime.now(),
      );

      // 1. Add student
      await db.addStudent(student);
      var fetched = db.getStudents(includeArchived: true).firstWhere((s) => s.id == student.id);
      expect(fetched.status, 'Faol');
      expect(fetched.assignedSpecialistIds.isEmpty, true);

      // 2. Assign specialist
      await db.assignSpecialistToStudent(student.id, existingSpecialist.id);
      fetched = db.getStudents(includeArchived: true).firstWhere((s) => s.id == student.id);
      expect(fetched.assignedSpecialistIds.contains(existingSpecialist.id), true);

      // 3. Deactivate / Archive with documented reason
      await db.deactivateStudent(student.id, 'Boshqa ixtisoslashtirilgan maktabga o‘tkazildi');
      fetched = db.getStudents(includeArchived: true).firstWhere((s) => s.id == student.id);
      expect(fetched.status, 'Arxivlangan');
      expect(fetched.deactivationReason, 'Boshqa ixtisoslashtirilgan maktabga o‘tkazildi');
      expect(fetched.deactivatedAt, isNotNull);

      // By default, active query excludes archived students
      final activeList = db.getStudents(includeArchived: false);
      expect(activeList.any((s) => s.id == student.id), false);
    });
  });

  group('3. Assessment Scoring, Non-Medical Notice & Database Baseline Lookup', () {
    test('Assessment templates provide professional disclaimer and structured criteria', () {
      expect(AssessmentTemplates.disclaimerNotice.contains('tibbiy yoki psixiatrik tashxis hisoblanmaydi'), true);
      expect(AssessmentTemplates.all.isNotEmpty, true);

      final logopedTemplate = AssessmentTemplates.getTemplateForRole(UserRole.speechTherapist);
      expect(logopedTemplate.fields.length, greaterThanOrEqualTo(3));
      expect(logopedTemplate.title.contains('Logopedik'), true);
    });

    test('Real baseline score lookup from database without fabricated numbers', () async {
      final db = LocalDbService();
      await db.init();

      final ass1 = AssessmentModel(
        id: 'ass_test_1',
        studentId: 'stud_lookup_test',
        studentName: 'Temur Oripov',
        specialistId: 'spec_1',
        specialistName: 'Dilnoza Psixolog',
        specialistRole: 'Psixolog',
        type: 'Diagnostik',
        category: 'Kognitiv soha',
        title: 'Boshlang‘ich kognitiv diagnostika',
        totalScore: 40.0,
        maxScore: 100.0,
        notes: 'Dastlabki tekshiruv',
        recommendations: 'Mashg‘ulotlar boshlash',
        assessmentDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      await db.addAssessment(ass1);

      // Look up previous assessment for same student and category from database
      final matching = db.getAssessments(studentId: 'stud_lookup_test', category: 'Kognitiv soha');
      expect(matching.isNotEmpty, true);
      final previous = matching.first;
      expect(previous.totalScore, 40.0);

      // Add second assessment referencing real previous score
      final ass2 = AssessmentModel(
        id: 'ass_test_2',
        studentId: 'stud_lookup_test',
        studentName: 'Temur Oripov',
        specialistId: 'spec_1',
        specialistName: 'Dilnoza Psixolog',
        specialistRole: 'Psixolog',
        type: 'Davriy',
        category: 'Kognitiv soha',
        title: 'Oraliq diagnostika',
        totalScore: 55.0,
        maxScore: 100.0,
        previousScore: previous.totalScore,
        notes: 'O‘sish kuzatilmoqda',
        recommendations: 'Davom ettirish',
        assessmentDate: DateTime.now(),
      );

      await db.addAssessment(ass2);
      expect(ass2.trend, 'O‘sish');
    });
  });

  group('4. Sessions: Duplicate Prevention & Confirmed Attendance', () {
    test('Prevents duplicate sessions at the same date and time for the same student and specialist', () async {
      final db = LocalDbService();
      await db.init();

      final sessionTime = DateTime(2026, 11, 10, 10, 0);

      final session1 = SessionModel(
        id: 'sess_dup_1',
        studentId: 'stud_dup_test',
        studentName: 'Sardor',
        specialistId: 'spec_dup_test',
        specialistName: 'Nodira Logoped',
        specialistRole: 'Logoped',
        scheduledAt: sessionTime,
        durationMinutes: 45,
        topic: 'Tovush talaffuzi',
        sessionType: 'Yakka tartibda',
        status: 'Rejalashtirilgan',
      );

      final res1 = await db.addSession(session1);
      expect(res1['success'], true);

      // Attempt duplicate session
      final sessionDuplicate = SessionModel(
        id: 'sess_dup_2',
        studentId: 'stud_dup_test',
        studentName: 'Sardor',
        specialistId: 'spec_dup_test',
        specialistName: 'Nodira Logoped',
        specialistRole: 'Logoped',
        scheduledAt: sessionTime,
        durationMinutes: 45,
        topic: 'Takroriy dars',
        sessionType: 'Yakka tartibda',
        status: 'Rejalashtirilgan',
      );

      final res2 = await db.addSession(sessionDuplicate);
      expect(res2['success'], false);
      expect(res2['message'].toString().contains('allaqachon mashg‘ulot rejalashtirilgan'), true);
    });

    test('Completing session requires observations and sets confirmed attendance', () async {
      final db = LocalDbService();
      await db.init();

      final session = SessionModel(
        id: 'sess_complete_test',
        studentId: 'stud_c_test',
        studentName: 'Aziza',
        specialistId: 'spec_c_test',
        specialistName: 'Karima Defektolog',
        specialistRole: 'Defektolog',
        scheduledAt: DateTime(2026, 11, 12, 14, 0),
        durationMinutes: 45,
        topic: 'Mayda motorika mashqlari',
        sessionType: 'Yakka tartibda',
        status: 'Rejalashtirilgan',
      );

      await db.addSession(session);
      await db.completeSession(
        session.id,
        observations: 'O‘quvchi topshiriqlarni faol bajardi va mustaqil yozishga harakat qildi.',
        nextSteps: 'Keyingi darsda applikatsiya mashg‘ulotini o‘tkazish.',
      );

      final updated = db.getSessions().firstWhere((s) => s.id == session.id);
      expect(updated.status, 'Bajarildi');
      expect(updated.attendanceConfirmed, true);
      expect(updated.observations, isNotNull);
      expect(updated.observations!.contains('faol bajardi'), true);
    });
  });

  group('5. IEP Mathematical Goal Calculation & Multi-Specialist Objectives', () {
    test('Calculates IEP average progress mathematically without fabricated percentages', () {
      final plan = IndividualEducationPlanModel(
        id: 'iep_calc_1',
        studentId: 'stud_iep',
        studentName: 'Botir Usmonov',
        studentGrade: '3-A',
        institutionName: '14-sonli maktab',
        title: '2026-2027 ITR',
        academicYear: '2026-2027',
        startDate: DateTime(2026, 9, 1),
        reviewDate: DateTime(2027, 1, 15),
        responsibleTeacherId: 'teacher_1',
        responsibleTeacherName: 'Malika O‘qituvchi',
        status: 'Faol',
        baselineSummary: 'Dastlabki test',
        longTermGoals: 'Yillik natija',
        objectives: [
          PlanObjectiveModel(
            id: 'obj_1',
            title: 'Nutq tovushlari',
            domain: 'Nutq',
            targetDate: DateTime(2026, 12, 1),
            status: 'Jarayonda',
            progressPercent: 60,
          ),
          PlanObjectiveModel(
            id: 'obj_2',
            title: 'Diqqat barqarorligi',
            domain: 'Kognitiv',
            targetDate: DateTime(2026, 12, 1),
            status: 'Jarayonda',
            progressPercent: 40,
          ),
          PlanObjectiveModel(
            id: 'obj_3',
            title: 'Yozish ko‘nikmalari',
            domain: 'O‘quv',
            targetDate: DateTime(2026, 12, 1),
            status: 'Bajarildi',
            progressPercent: 100,
          ),
        ],
      );

      // (60 + 40 + 100) / 3 = 66.6666...
      expect(plan.averageProgress, closeTo(66.67, 0.1));
      expect(plan.completedObjectivesCount, 1);
      expect(plan.totalObjectivesCount, 3);
    });
  });

  group('6. Automated Monitoring Rule Engine (6 Official Rules)', () {
    final engine = MonitoringRuleEngine();

    test('Rule 1: Detects 2+ missed or cancelled sessions', () {
      final student = StudentModel(
        id: 's_missed',
        institutionId: 'inst_1',
        institutionName: '1-sonli maktab',
        firstName: 'Ali',
        lastName: 'Karimov',
        dateOfBirth: DateTime(2016, 1, 1),
        gender: 'Erkak',
        grade: '2-A',
        status: 'Faol',
        primaryNeed: 'Nutq',
        supportLevel: '1-daraja',
        createdAt: DateTime.now(),
      );

      final missedSessions = [
        SessionModel(
          id: 'sess_m1',
          studentId: 's_missed',
          studentName: 'Ali Karimov',
          specialistId: 'spec_1',
          specialistName: 'Logoped',
          specialistRole: 'Logoped',
          scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
          durationMinutes: 40,
          topic: 'Dars 1',
          status: 'Qatnashmadi',
        ),
        SessionModel(
          id: 'sess_m2',
          studentId: 's_missed',
          studentName: 'Ali Karimov',
          specialistId: 'spec_1',
          specialistName: 'Logoped',
          specialistRole: 'Logoped',
          scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
          durationMinutes: 40,
          topic: 'Dars 2',
          status: 'Qatnashmadi',
        ),
      ];

      final alerts = engine.evaluateRules(
        students: [student],
        assessments: [],
        sessions: missedSessions,
        iepPlans: [],
        existingAlerts: [],
      );

      expect(alerts.any((a) => a.ruleCode == 'MISSED_SESSIONS'), true);
      final alert = alerts.firstWhere((a) => a.ruleCode == 'MISSED_SESSIONS');
      expect(alert.severity, 'DIQQAT');
      expect(alert.studentId, 's_missed');
    });

    test('Rule 2: Detects overdue periodic assessment (>60 days)', () {
      final student = StudentModel(
        id: 's_overdue_ass',
        institutionId: 'inst_1',
        institutionName: '1-sonli maktab',
        firstName: 'Vali',
        lastName: 'Rasulov',
        dateOfBirth: DateTime(2015, 5, 5),
        gender: 'Erkak',
        grade: '3-B',
        status: 'Faol',
        primaryNeed: 'Kognitiv',
        supportLevel: '2-daraja',
        createdAt: DateTime.now(),
      );

      final oldAssessment = AssessmentModel(
        id: 'ass_old',
        studentId: 's_overdue_ass',
        studentName: 'Vali Rasulov',
        specialistId: 'spec_1',
        specialistName: 'Psixolog',
        specialistRole: 'Psixolog',
        type: 'Diagnostik',
        category: 'Kognitiv',
        title: 'Eski diagnostika',
        totalScore: 50.0,
        maxScore: 100.0,
        notes: '',
        recommendations: '',
        reviewDate: DateTime.now().subtract(const Duration(days: 5)),
        assessmentDate: DateTime.now().subtract(const Duration(days: 75)),
      );

      final alerts = engine.evaluateRules(
        students: [student],
        assessments: [oldAssessment],
        sessions: [],
        iepPlans: [],
        existingAlerts: [],
      );

      expect(alerts.any((a) => a.ruleCode == 'OVERDUE_ASSESSMENT'), true);
    });

    test('Rule 3: Detects stagnation across consecutive comparable assessments', () {
      final student = StudentModel(
        id: 's_stagnant',
        institutionId: 'inst_1',
        institutionName: '1-sonli maktab',
        firstName: 'Anvar',
        lastName: 'Saidov',
        dateOfBirth: DateTime(2016, 2, 2),
        gender: 'Erkak',
        grade: '2-B',
        status: 'Faol',
        primaryNeed: 'Nutq',
        supportLevel: '2-daraja',
        createdAt: DateTime.now(),
      );

      final assessments = [
        AssessmentModel(
          id: 'ass_st1',
          studentId: 's_stagnant',
          studentName: 'Anvar Saidov',
          specialistId: 'spec_1',
          specialistName: 'Logoped',
          specialistRole: 'Logoped',
          type: 'Diagnostik',
          category: 'Nutq sohasini baholash',
          title: 'Baholash 1',
          totalScore: 40.0,
          maxScore: 100.0,
          notes: '',
          recommendations: '',
          assessmentDate: DateTime.now().subtract(const Duration(days: 40)),
        ),
        AssessmentModel(
          id: 'ass_st2',
          studentId: 's_stagnant',
          studentName: 'Anvar Saidov',
          specialistId: 'spec_1',
          specialistName: 'Logoped',
          specialistRole: 'Logoped',
          type: 'Davriy',
          category: 'Nutq sohasini baholash',
          title: 'Baholash 2',
          totalScore: 40.0,
          maxScore: 100.0,
          notes: '',
          recommendations: '',
          assessmentDate: DateTime.now(),
        ),
      ];

      final alerts = engine.evaluateRules(
        students: [student],
        assessments: assessments,
        sessions: [],
        iepPlans: [],
        existingAlerts: [],
      );

      expect(alerts.any((a) => a.ruleCode == 'NO_PROGRESS_ASSESSMENT'), true);
    });

    test('Rule 4: Detects significant regression drop (>15%) in comparable assessments', () {
      final student = StudentModel(
        id: 's_regression',
        institutionId: 'inst_1',
        institutionName: '1-sonli maktab',
        firstName: 'Nodir',
        lastName: 'Eshonov',
        dateOfBirth: DateTime(2015, 3, 3),
        gender: 'Erkak',
        grade: '3-A',
        status: 'Faol',
        primaryNeed: 'Kognitiv',
        supportLevel: '1-daraja',
        createdAt: DateTime.now(),
      );

      final assessments = [
        AssessmentModel(
          id: 'ass_reg1',
          studentId: 's_regression',
          studentName: 'Nodir Eshonov',
          specialistId: 'spec_1',
          specialistName: 'Psixolog',
          specialistRole: 'Psixolog',
          type: 'Diagnostik',
          category: 'Diqqat va xotira',
          title: 'Baholash 1',
          totalScore: 70.0,
          maxScore: 100.0,
          notes: '',
          recommendations: '',
          assessmentDate: DateTime.now().subtract(const Duration(days: 15)),
        ),
        AssessmentModel(
          id: 'ass_reg2',
          studentId: 's_regression',
          studentName: 'Nodir Eshonov',
          specialistId: 'spec_1',
          specialistName: 'Psixolog',
          specialistRole: 'Psixolog',
          type: 'Davriy',
          category: 'Diqqat va xotira',
          title: 'Baholash 2',
          totalScore: 45.0, // 25 ball pasayish
          maxScore: 100.0,
          notes: '',
          recommendations: '',
          assessmentDate: DateTime.now(),
        ),
      ];

      final alerts = engine.evaluateRules(
        students: [student],
        assessments: assessments,
        sessions: [],
        iepPlans: [],
        existingAlerts: [],
      );

      expect(alerts.any((a) => a.ruleCode == 'REGRESSION_ALERT'), true);
      final regAlert = alerts.firstWhere((a) => a.ruleCode == 'REGRESSION_ALERT');
      expect(regAlert.severity, 'XAVF');
    });

    test('Rule 5: Detects overdue IEP objectives past target date', () {
      final student = StudentModel(
        id: 's_iep_overdue',
        institutionId: 'inst_1',
        institutionName: '1-sonli maktab',
        firstName: 'Kamola',
        lastName: 'Toshmatova',
        dateOfBirth: DateTime(2015, 7, 7),
        gender: 'Ayol',
        grade: '3-B',
        status: 'Faol',
        primaryNeed: 'O‘quv',
        supportLevel: '1-daraja',
        createdAt: DateTime.now(),
      );

      final overdueIep = IndividualEducationPlanModel(
        id: 'iep_overdue_1',
        studentId: 's_iep_overdue',
        studentName: 'Kamola Toshmatova',
        studentGrade: '3-B',
        institutionName: '1-sonli maktab',
        title: 'ITR 2026',
        academicYear: '2026-2027',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        reviewDate: DateTime.now().add(const Duration(days: 30)),
        responsibleTeacherId: 'teacher_1',
        responsibleTeacherName: 'O‘qituvchi',
        status: 'Faol',
        baselineSummary: '',
        longTermGoals: '',
        objectives: [
          PlanObjectiveModel(
            id: 'obj_past_due',
            title: 'Lug‘at boyitish',
            domain: 'Nutq',
            targetDate: DateTime.now().subtract(const Duration(days: 10)), // 10 kun oldin o'tgan
            status: 'Jarayonda',
            progressPercent: 40,
          ),
        ],
      );

      final alerts = engine.evaluateRules(
        students: [student],
        assessments: [],
        sessions: [],
        iepPlans: [overdueIep],
        existingAlerts: [],
      );

      expect(alerts.any((a) => a.ruleCode == 'OVERDUE_IEP_OBJECTIVE'), true);
    });

    test('Rule 6: Detects completed session missing professional observations', () {
      final student = StudentModel(
        id: 's_obs_missing',
        institutionId: 'inst_1',
        institutionName: '1-sonli maktab',
        firstName: 'Bobur',
        lastName: 'Yusupov',
        dateOfBirth: DateTime(2016, 9, 9),
        gender: 'Erkak',
        grade: '2-A',
        status: 'Faol',
        primaryNeed: 'Nutq',
        supportLevel: '1-daraja',
        createdAt: DateTime.now(),
      );

      final completedSessionNoObs = SessionModel(
        id: 'sess_no_obs',
        studentId: 's_obs_missing',
        studentName: 'Bobur Yusupov',
        specialistId: 'spec_1',
        specialistName: 'Defektolog',
        specialistRole: 'Defektolog',
        scheduledAt: DateTime.now().subtract(const Duration(days: 2)),
        durationMinutes: 45,
        topic: 'Dars',
        status: 'Bajarildi',
        observations: '', // Bo'sh kuzatuv
      );

      final alerts = engine.evaluateRules(
        students: [student],
        assessments: [],
        sessions: [completedSessionNoObs],
        iepPlans: [],
        existingAlerts: [],
      );

      expect(alerts.any((a) => a.ruleCode == 'MISSING_OBSERVATION'), true);
    });
  });

  group('7. Interdisciplinary Referrals Lifecycle Workflow', () {
    test('Referral advances correctly through all workflow states with outcomes', () async {
      final db = LocalDbService();
      await db.init();

      final referral = ReferralModel(
        id: 'ref_test_flow',
        studentId: 's_ref_test',
        studentName: 'Sarvar Akramov',
        fromSpecialistId: 'user_teacher',
        fromSpecialistName: 'Sinf rahbari',
        toSpecialistType: 'Defektolog',
        reason: 'O‘quvchida yozuv va harflarni taniy olmaslik belgilari kuzatilmoqda',
        priority: 'YUQORI',
        status: 'Yuborildi',
        createdAt: DateTime.now(),
      );

      // 1. Submit referral
      await db.addReferral(referral);
      var fetched = db.getReferrals().firstWhere((r) => r.id == referral.id);
      expect(fetched.status, 'Yuborildi');

      // 2. Accept referral
      await db.updateReferralStatus(referral.id, 'Qabul qilindi');
      fetched = db.getReferrals().firstWhere((r) => r.id == referral.id);
      expect(fetched.status, 'Qabul qilindi');

      // 3. Mark in progress
      await db.updateReferralStatus(referral.id, 'Jarayonda');
      fetched = db.getReferrals().firstWhere((r) => r.id == referral.id);
      expect(fetched.status, 'Jarayonda');

      // 4. Complete with professional outcome notes and follow-up date
      final followUp = DateTime(2026, 12, 1);
      await db.updateReferralStatus(
        referral.id,
        'Yakunlandi',
        outcomeNotes: 'Disgrafiya tashxisi dastlabki belgilari tasdiqlandi. Haftasiga 2 marta maxsus mashg‘ulot tayinlandi.',
        followUpAction: 'Oraliq nazorat tekshiruvi o‘tkazish',
        followUpDate: followUp,
      );

      fetched = db.getReferrals().firstWhere((r) => r.id == referral.id);
      expect(fetched.status, 'Yakunlandi');
      expect(fetched.outcomeNotes!.contains('Disgrafiya tashxisi'), true);
      expect(fetched.followUpDate, followUp);
    });
  });

  group('8. RFC 4180 CSV Reports Export with UTF-8 BOM', () {
    final exportService = ReportExportService();

    test('Exports Students CSV formatted properly with UTF-8 BOM for Excel', () {
      final students = [
        StudentModel(
          id: 's_csv_1',
          institutionId: 'inst_1',
          institutionName: '14-sonli maktab',
          firstName: 'G‘ayrat',
          lastName: 'O‘ktamov',
          dateOfBirth: DateTime(2015, 5, 10),
          gender: 'Erkak',
          grade: '3-B',
          status: 'Faol',
          primaryNeed: 'Nutqiy rivojlanish',
          supportLevel: '2-daraja',
          createdAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateStudentsCsv(students);
      expect(csv.startsWith('\uFEFF'), true, reason: 'Excel Cyrillic/Uzbek uchun UTF-8 BOM prefix bo‘lishi lozim');
      expect(csv.contains('F.I.SH'), true);
      expect(csv.contains('O‘ktamov G‘ayrat'), true);
      expect(csv.contains('14-sonli maktab'), true);
    });

    test('Exports Assessments CSV', () {
      final assessments = <AssessmentModel>[
        AssessmentModel(
          id: 'ass_csv_1',
          studentId: 's_csv_1',
          studentName: 'O‘ktamov G‘ayrat',
          specialistId: 'spec_1',
          specialistName: 'Dilnoza Logoped',
          specialistRole: 'Logoped',
          type: 'Diagnostik',
          category: 'Nutq rivojlanishi',
          title: 'Dastlabki baholash',
          totalScore: 78.0,
          maxScore: 100.0,
          notes: 'Natijalar ijobiy',
          recommendations: 'Mashg‘ulotlar davom etsin',
          assessmentDate: DateTime(2026, 10, 15),
        ),
      ];

      final csv = exportService.generateAssessmentsCsv(assessments);
      expect(csv.startsWith('\uFEFF'), true);
      expect(csv.contains('O‘ktamov G‘ayrat'), true);
      expect(csv.contains('Dilnoza Logoped'), true);
      expect(csv.contains('78'), true);
    });
  });
}
