import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talim_nazorat/core/constants/progress_metrics.dart';
import 'package:talim_nazorat/models/assessment_model.dart';
import 'package:talim_nazorat/models/curriculum_model.dart';
import 'package:talim_nazorat/models/iep_model.dart';
import 'package:talim_nazorat/models/progress_measurement_model.dart';
import 'package:talim_nazorat/models/psychologist_observation_model.dart';
import 'package:talim_nazorat/models/referral_model.dart';
import 'package:talim_nazorat/models/speech_sound_model.dart';
import 'package:talim_nazorat/models/student_model.dart';
import 'package:talim_nazorat/models/subject_task_model.dart';
import 'package:talim_nazorat/models/user_model.dart';
import 'package:talim_nazorat/providers/app_provider.dart';
import 'package:talim_nazorat/providers/auth_provider.dart';
import 'package:talim_nazorat/services/child_status_service.dart';
import 'package:talim_nazorat/services/dynamics_service.dart';
import 'package:talim_nazorat/services/local_db_service.dart';
import 'package:talim_nazorat/services/seed_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Master Prompt Section 29: Complete 24-Step End-to-End Platform Workflow', () async {
    SharedPreferences.setMockInitialValues({});
    final db = LocalDbService();
    db.resetForTest();
    await db.init();

    final auth = AuthProvider();
    final app = AppProvider();

    // 1. Administrator logs in
    final loginRes = await auth.login('admin@talim.uz', SeedData.demoPassword);
    expect(loginRes['success'], isTrue);
    final superAdmin = auth.currentUser!;
    app.setCurrentUser(superAdmin);

    // 2-4. Administrator creates a specialist account & assigns role
    const schoolName = '5-sonli umumiy o‘rta ta’lim maktabi';
    const schoolId = 'inst_chortoq_5';
    final newSpec = UserModel(
      id: 'usr_e2e_spec_teacher',
      fullName: 'Tursunova Mohira Karimovna',
      email: 'mohira.e2e@talim.uz',
      phone: '+998 90 700-80-90',
      role: UserRole.specialEdTeacher,
      institutionId: schoolId,
      institutionName: schoolName,
      region: 'Namangan viloyati',
      district: 'Chortoq tumani',
      specialization: 'Maxsus ta’lim o‘qituvchisi (Matematika)',
      password: 'TempPassword2026!',
    );
    await app.addUser(newSpec, byUser: superAdmin);
    expect(db.getUserById('usr_e2e_spec_teacher')?.role, UserRole.specialEdTeacher);

    // 5. Administrator registers a 7th-grade child + an unworked child
    final grade7Student = StudentModel(
      id: 'student_e2e_7th',
      institutionId: schoolId,
      institutionName: schoolName,
      firstName: 'Sardor',
      lastName: 'Normatov',
      dateOfBirth: DateTime(2013, 4, 12),
      gender: 'Erkak',
      grade: '7-A',
      status: 'Faol',
      primaryNeed: 'Uyda yakka tartibda ta’lim (Kognitiv sur’at sekinlashuvi)',
      supportLevel: '2-daraja (O‘rta yordam)',
      createdAt: DateTime.now(),
    );
    final unworkedStudent = StudentModel(
      id: 'student_e2e_unworked',
      institutionId: schoolId,
      institutionName: schoolName,
      firstName: 'Aziza',
      lastName: 'Salimova',
      dateOfBirth: DateTime(2016, 8, 20),
      gender: 'Ayol',
      grade: '3-A',
      status: 'Faol',
      primaryNeed: 'Nutqiy rivojlanishdan orqada qolish',
      supportLevel: '2-daraja (O‘rta yordam)',
      createdAt: DateTime.now(),
    );
    await app.addStudent(grade7Student, byUser: superAdmin);
    await app.addStudent(unworkedStudent, byUser: superAdmin);

    // 6. Assign specialists to the child
    final coordinator = db.getUserById('user_coordinator')!;
    app.setCurrentUser(coordinator);
    await app.assignSpecialistToStudent('student_e2e_7th', 'user_psychologist', byUser: coordinator);
    await app.assignSpecialistToStudent('student_e2e_7th', 'usr_e2e_spec_teacher', byUser: coordinator);
    await app.assignSpecialistToStudent('student_e2e_7th', 'user_speech', byUser: coordinator);

    // Before work is recorded, both new children are RED in Svetofor
    expect(app.childStatus(db.getStudentById('student_e2e_7th')!).color, StatusColor.red);
    expect(app.childStatus(db.getStudentById('student_e2e_unworked')!).color, StatusColor.red);

    // 7-13. Psychologist logs in, selects methodology & questions, conducts assessment & observation
    final psychologist = db.getUserById('user_psychologist')!;
    app.setCurrentUser(psychologist);
    final selectedQuestions = app.workspaceQuestionsFor(
      db.getStudentById('student_e2e_7th')!,
    );
    expect(selectedQuestions, isNotEmpty);

    await app.addAssessment(
      AssessmentModel(
        id: 'ass_e2e_1',
        studentId: 'student_e2e_7th',
        studentName: 'Normatov Sardor',
        specialistId: psychologist.id,
        specialistName: psychologist.fullName,
        specialistRole: psychologist.role.label,
        assessmentDate: DateTime.now().subtract(const Duration(days: 2)),
        type: 'Psixologik metodika',
        category: 'Ixtiyoriy diqqat va aqliy ishchanlik',
        title: 'Korrektura sinovi (Burdon — harfli variant)',
        totalScore: 76,
        maxScore: 100,
        previousScore: 60,
        notes: 'Diqqat konsentratsiyasi 2 daqiqadan 7 daqiqagacha oshdi.',
        recommendations: 'Matematikadan vizual kartochkalar va bosqichli tushuntirish qo‘llansin.',
      ),
      byUser: psychologist,
    );

    await app.addObservation(
      PsychologicalObservationModel(
        id: 'obs_e2e_1',
        studentId: 'student_e2e_7th',
        studentName: 'Normatov Sardor',
        studentGrade: '7-A',
        psychologistId: psychologist.id,
        psychologistName: psychologist.fullName,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Kognitiv faollik va diqqat',
        emotionalState: 'Barqaror / Ijobiy',
        triggerOrContext: 'Individual topshiriq bajarishda',
        observationText: 'Vizual taymer bilan chalg‘imasdan 7 daqiqa ishladi.',
        recommendationOrAction: '3-sinf darajasidagi amaliy misollarni davom ettirish.',
        isConfidential: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      byUser: psychologist,
    );

    // 14. Record comparable measurements (2 min -> 7 min) and verify Dynamics = Growth
    await app.addMeasurement(
      ProgressMeasurement(
        id: 'm_e2e_1',
        studentId: 'student_e2e_7th',
        metricId: ProgressMetrics.attentionSpan.id,
        value: 2,
        measuredAt: DateTime.now().subtract(const Duration(days: 20)),
        recordedById: psychologist.id,
        recordedByName: psychologist.fullName,
      ),
    );
    await app.addMeasurement(
      ProgressMeasurement(
        id: 'm_e2e_2',
        studentId: 'student_e2e_7th',
        metricId: ProgressMetrics.attentionSpan.id,
        value: 7,
        measuredAt: DateTime.now().subtract(const Duration(days: 1)),
        recordedById: psychologist.id,
        recordedByName: psychologist.fullName,
      ),
    );
    final dyn = app.measurementDynamics(
      'student_e2e_7th',
      ProgressMetrics.attentionSpan.id,
    );
    expect(dyn.status, DynamicsStatus.growth);

    // 15-17. Special Education Teacher assesses DTS level (7th-grade enrolled -> 3rd-grade actual math)
    final specTeacher = db.getUserById('usr_e2e_spec_teacher')!;
    app.setCurrentUser(specTeacher);
    final savedLevel = await app.saveSubjectLevel(
      studentId: 'student_e2e_7th',
      subject: SchoolSubjects.matematika,
      results: const {
        'dts_mat_1_1': Mastery.mastered,
        'dts_mat_1_2': Mastery.mastered,
        'dts_mat_1_3': Mastery.mastered,
        'dts_mat_2_1': Mastery.mastered,
        'dts_mat_2_2': Mastery.mastered,
        'dts_mat_2_3': Mastery.mastered,
        'dts_mat_3_1': Mastery.mastered,
        'dts_mat_3_2': Mastery.mastered,
        'dts_mat_3_3': Mastery.partial,
        'dts_mat_4_1': Mastery.notYet,
      },
      confirmedGrade: 3,
      notes: '7-sinf o‘quvchisi, biroq DTS bo‘yicha 3-sinf matematika darajasida o‘qitiladi.',
    );
    expect(savedLevel.classGrade, 7);
    expect(savedLevel.confirmedGrade, 3);
    expect(savedLevel.gap, 4);
    // Official school grade remains 7-A
    expect(db.getStudentById('student_e2e_7th')!.grade, '7-A');

    // Assign & complete an individualized 3rd-grade Mathematics task
    final task = await app.assignSubjectTask(
      SubjectTask(
        id: 'task_e2e_math3',
        studentId: 'student_e2e_7th',
        subject: SchoolSubjects.matematika,
        levelGrade: 3,
        standardId: 'dts_mat_3_1',
        title: 'Ko‘paytirish va bo‘lish jadvali bo‘yicha 5 ta amaliy masala',
        assignedById: specTeacher.id,
        assignedByName: specTeacher.fullName,
        assignedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    );
    await app.completeSubjectTask(task.id, Mastery.mastered, note: 'Mustaqil to‘liq yechdi');

    // Achievement passport automatically includes the personal best & mastered task
    final passport = app.achievementPassport('student_e2e_7th');
    expect(passport.entries.length, greaterThanOrEqualTo(2));

    // 18-20. Specialist creates a referral & recipient updates it
    await app.addReferral(
      ReferralModel(
        id: 'ref_e2e_1',
        studentId: 'student_e2e_7th',
        studentName: 'Normatov Sardor',
        fromSpecialistId: specTeacher.id,
        fromSpecialistName: specTeacher.fullName,
        fromSpecialistRole: specTeacher.role.label,
        toSpecialistType: 'Logoped-defektolog',
        toSpecialistId: 'user_speech',
        toSpecialistName: 'Sodiqov Bobur Mirzayevich',
        reason: 'Matematik atamalarni talaffuz qilishda logopedik ko‘mak zarur.',
        priority: 'Rejali',
        status: 'Ko‘rib chiqilmoqda',
        createdAt: DateTime.now(),
      ),
      byUser: specTeacher,
    );
    final speechUser = db.getUserById('user_speech')!;
    expect(db.getNotifications(speechUser.id).any((n) => n.relatedRecordId == 'ref_e2e_1'), isTrue);
    app.setCurrentUser(speechUser);
    await app.updateReferralStatus('ref_e2e_1', 'Qabul qilindi', byUser: speechUser);
    await app.recordSoundEntry(
      SoundEntry(
        id: 'snd_e2e_1',
        studentId: 'student_e2e_7th',
        soundId: 'r',
        stage: SoundStage.staging,
        disorder: SoundDisorder.distortion,
        note: 'Matematik atamalar uchun "R" tovushi ustida mashg‘ulot boshlandi.',
        recordedById: speechUser.id,
        recordedByName: speechUser.fullName,
        recordedAt: DateTime.now(),
      ),
    );

    // 21. Individual Development Plan (ITR) is created and updated
    app.setCurrentUser(coordinator);
    await app.addIepPlan(
      IndividualEducationPlanModel(
        id: 'iep_e2e_7th',
        studentId: 'student_e2e_7th',
        studentName: 'Normatov Sardor',
        studentGrade: '7-A',
        institutionName: schoolName,
        title: 'Normatov Sardor uchun individual moslashtirilgan ITR (Matematika 3-sinf darajasi)',
        academicYear: '2026-2027',
        startDate: DateTime(2026, 9, 1),
        reviewDate: DateTime(2026, 12, 25),
        responsibleTeacherId: specTeacher.id,
        responsibleTeacherName: specTeacher.fullName,
        coordinatorId: coordinator.id,
        coordinatorName: coordinator.fullName,
        status: 'Faol',
        baselineSummary: 'Matematikadan 3-sinf DTS darajasi, diqqat davomiyligi 7 daqiqa.',
        longTermGoals: '3-sinf DTS talablarini to‘liq yakunlab, 4-sinf dasturiga o‘tish.',
        supportStrategies: 'Vizual kartochkalar, bosqichli masalalar, logoped va psixolog hamkorligi.',
        objectives: [
          PlanObjectiveModel(
            id: 'obj_e2e_1',
            title: '1000 ichida qo‘shish va ayirishni mustaqil bajarish',
            domain: 'O‘quv va dars faoliyati',
            targetDate: DateTime(2026, 12, 1),
            status: 'Bajarildi',
            progressPercent: 100,
            successCriteria: '10 tadan 9 ta misolni to‘g‘ri ishlash',
          ),
        ],
      ),
      byUser: coordinator,
    );

    // 22-24. Management reviews child progress, identifies unworked children, and generates reports
    final adminUser = db.getUserById('user_admin')!;
    app.setCurrentUser(adminUser);

    final workedStatus = app.childStatus(db.getStudentById('student_e2e_7th')!);
    final unworkedStatus = app.childStatus(db.getStudentById('student_e2e_unworked')!);
    expect(workedStatus.color, StatusColor.green);
    expect(unworkedStatus.color, StatusColor.red);

    final report = app.buildReport();
    expect(report.totalChildren, greaterThanOrEqualTo(8));
    expect(report.notWorkedWithNames, contains('Salimova Aziza'));

    final csv = app.exportMonitoringReportCsv();
    expect(csv, contains('Salimova Aziza'));

    final backupJson = app.exportDatabaseBackupJson();
    final decoded = jsonDecode(backupJson) as Map<String, dynamic>;
    expect((decoded['tables'] as Map<String, dynamic>)['subjectLevels'], isNotEmpty);

    auth.dispose();
  });
}

