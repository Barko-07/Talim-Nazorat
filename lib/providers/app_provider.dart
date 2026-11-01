import 'package:flutter/material.dart';

import '../models/student_model.dart';
import '../models/assessment_model.dart';
import '../models/session_model.dart';
import '../models/iep_model.dart';
import '../models/monitoring_alert_model.dart';
import '../models/referral_model.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/psychologist_observation_model.dart';
import '../models/assessment_question_model.dart';
import '../services/local_db_service.dart';
import '../services/report_export_service.dart';
import '../services/question_selection_service.dart';
import '../services/subject_level_service.dart';
import '../services/dynamics_service.dart';
import '../services/workspace_service.dart';
import '../services/child_status_service.dart';
import '../services/achievement_service.dart';
import '../services/report_service.dart';
import '../models/achievement_model.dart';
import '../models/case_conference_model.dart';
import '../models/speech_sound_model.dart';
import '../core/constants/uzbek_speech_sounds.dart';
import '../core/constants/method_library.dart';
import '../core/constants/psychological_methods_data.dart';
import '../services/sound_tracker_service.dart';
import '../models/workspace_model.dart';
import '../models/subject_task_model.dart';
import '../models/curriculum_model.dart';
import '../models/progress_measurement_model.dart';
import '../models/assessment_plan_model.dart';
import '../models/development_profile_model.dart';

class AppProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService();
  final ReportExportService _exportService = ReportExportService();
  final QuestionSelectionService _selection = QuestionSelectionService();
  final SubjectLevelService _subjectLevels = SubjectLevelService();
  final DynamicsService _dynamics = DynamicsService();
  final WorkspaceService _workspaces = WorkspaceService();
  final ChildStatusService _childStatus = ChildStatusService();
  final AchievementService _achievementService = AchievementService();
  final ReportService _reports = ReportService();
  final SoundTrackerService _soundTracker = SoundTrackerService();

  UserModel? _currentUser;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;

  String _searchQuery = '';
  String? _selectedGrade;
  String? _selectedStatus;

  String get searchQuery => _searchQuery;
  String? get selectedGrade => _selectedGrade;
  String? get selectedStatus => _selectedStatus;

  /// O'qish uchun ko'ruvchi. Hech kim kirmagan bo'lsa — faolsiz anonim foydalanuvchi:
  /// ruxsat qoidalari unga hech narsa ko'rsatmaydi ("forUser: null" esa filtrsiz
  /// barcha ma'lumotni qaytarardi).
  UserModel get _viewer => _currentUser ?? _anonymous;

  static final _anonymous = UserModel(
    id: '__anonymous__',
    email: 'anonymous@system',
    fullName: 'Anonim',
    role: UserRole.reviewer,
    isActive: false,
  );

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setFilterGrade(String? grade) {
    _selectedGrade = grade;
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedGrade = null;
    _selectedStatus = null;
    notifyListeners();
  }

  // ==================== GETTERS ====================
  List<StudentModel> get students => _db.getStudents(
    forUser: _viewer,
    query: _searchQuery,
    grade: _selectedGrade,
    status: _selectedStatus,
  );

  List<StudentModel> get allStudentsIncludingArchived =>
      _db.getStudents(forUser: _viewer, includeArchived: true);

  List<AssessmentModel> get assessments =>
      _db.getAssessments(forUser: _viewer);
  List<SessionModel> get sessions => _db.getSessions(forUser: _viewer);
  List<IndividualEducationPlanModel> get iepPlans =>
      _db.getIepPlans(forUser: _viewer);
  List<MonitoringAlertModel> get alerts => _db.getAlerts(forUser: _viewer);
  List<MonitoringAlertModel> get unresolvedAlerts =>
      _db.getAlerts(forUser: _viewer, onlyUnresolved: true);
  List<MonitoringAlertModel> getAlerts({bool onlyUnresolved = false}) =>
      onlyUnresolved ? unresolvedAlerts : alerts;
  List<ReferralModel> get referrals => _db.getReferrals(forUser: _viewer);
  List<AuditLogModel> get auditLogs => _db.getAuditLogs(forUser: _viewer);
  List<PsychologicalObservationModel> get observations =>
      _db.getObservations(forUser: _viewer);
  List<AssessmentQuestionModel> get questions =>
      _db.getQuestions(forUser: _viewer);
  List<AssessmentQuestionModel> get myQuestions =>
      _db.getQuestions(forUser: _viewer, myQuestionsOnly: true);

  List<AssessmentQuestionModel> getQuestionsFiltered({
    String? domain,
    String? query,
    bool? myQuestionsOnly,
    String? status,
    String? questionType,
  }) {
    return _db.getQuestions(
      forUser: _viewer,
      domain: domain,
      query: query,
      myQuestionsOnly: myQuestionsOnly,
      status: status,
      questionType: questionType,
    );
  }

  AssessmentQuestionModel? getQuestionById(String id) =>
      _db.getQuestionById(id);

  List<UserModel> get specialists => _db
      .getUsers(forUser: _viewer)
      .where((u) => u.role != UserRole.superAdmin)
      .toList();
  List<UserModel> get allUsers => _db.getUsers(forUser: _viewer);

  List<NotificationModel> get myNotifications {
    if (_currentUser == null) return [];
    return _db.getNotifications(_currentUser!.id);
  }

  int get myUnreadNotificationCount {
    if (_currentUser == null) return 0;
    return _db.getUnreadNotificationCount(_currentUser!.id);
  }

  // ==================== DASHBOARD METRICS ====================
  int get totalStudentsCount => students.length;
  int get activeIepCount => iepPlans.where((p) => p.status == 'Faol').length;
  int get thisMonthSessionsCount => sessions.length;
  int get attentionNeededCount => unresolvedAlerts.length;

  /// Haqiqiy saqlangan oraliq baholashlar bo'yicha hisoblangan o'rtacha o'sish
  double get averageDevelopmentGrowth {
    final ass = assessments;
    if (ass.isEmpty) return 0.0;
    double sum = 0;
    int count = 0;
    for (var a in ass) {
      if (a.previousScore != null) {
        sum += (a.totalScore - a.previousScore!);
        count++;
      }
    }
    return count > 0 ? (sum / count) : 0.0;
  }

  // ==================== ACTIONS ====================
  Future<void> addStudent(StudentModel student, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.addStudent(student, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStudent(StudentModel student, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.updateStudent(student, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deactivateStudent(
    String studentId,
    String reason, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.deactivateStudent(
        studentId,
        reason,
        byUser: byUser ?? _requireUser(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Biriktirishni bekor qilish (koordinator yoki muassasa rahbari)
  Future<void> unassignSpecialistFromStudent(
    String studentId,
    String specialistId, {
    String? reason,
  }) async {
    await _db.unassignSpecialistFromStudent(
      studentId,
      specialistId,
      reason: reason,
      byUser: _requireUser(),
    );
    notifyListeners();
  }

  Future<void> assignSpecialistToStudent(
    String studentId,
    String specialistId, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.assignSpecialistToStudent(
        studentId,
        specialistId,
        byUser: byUser ?? _requireUser(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAssessment(
    AssessmentModel assessment, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.addAssessment(assessment, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAssessment(
    AssessmentModel assessment, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.updateAssessment(assessment, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAssessment(
    String id, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.deleteAssessment(id, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuestion(
    AssessmentQuestionModel question, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.addQuestion(question, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuestion(
    AssessmentQuestionModel question, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.updateQuestion(question, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteQuestion(
    String id, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.deleteQuestion(id, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addSession(
    SessionModel session, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _db.addSession(session, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeSession(
    String id, {
    required String observations,
    String? nextSteps,
    UserModel? byUser,
  }) async {
    await _db.completeSession(
      id,
      observations: observations,
      nextSteps: nextSteps,
      byUser: byUser ?? _requireUser(),
    );
    notifyListeners();
  }

  Future<void> updateSessionStatus(
    String id,
    String status, {
    String? notes,
    UserModel? byUser,
  }) async {
    await _db.updateSessionStatus(
      id,
      status,
      notes: notes,
      byUser: byUser ?? _requireUser(),
    );
    notifyListeners();
  }

  Future<void> deleteSession(String id, {UserModel? byUser}) async {
    await _db.deleteSession(id, byUser: byUser ?? _requireUser());
    notifyListeners();
  }

  Future<void> addIepPlan(
    IndividualEducationPlanModel plan, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.addIepPlan(plan, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateIepPlan(
    IndividualEducationPlanModel plan, {
    UserModel? byUser,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.updateIepPlan(plan, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateObjectiveProgress(
    String iepId,
    String objId,
    int progress, {
    String? evidenceNotes,
    UserModel? byUser,
  }) async {
    await _db.updateObjectiveProgress(
      iepId,
      objId,
      progress,
      evidenceNotes: evidenceNotes,
      byUser: byUser ?? _requireUser(),
    );
    notifyListeners();
  }

  Future<void> resolveAlert(
    String alertId,
    String notes, {
    UserModel? byUser,
  }) async {
    await _db.resolveAlert(alertId, notes, byUser: byUser ?? _requireUser());
    notifyListeners();
  }

  Future<void> addReferral(ReferralModel referral, {UserModel? byUser}) async {
    await _db.addReferral(referral, byUser: byUser ?? _requireUser());
    notifyListeners();
  }

  Future<void> updateReferralStatus(
    String referralId,
    String newStatus, {
    String? outcomeNotes,
    String? followUpAction,
    DateTime? followUpDate,
    UserModel? byUser,
  }) async {
    await _db.updateReferralStatus(
      referralId,
      newStatus,
      outcomeNotes: outcomeNotes,
      followUpAction: followUpAction,
      followUpDate: followUpDate,
      byUser: byUser ?? _requireUser(),
    );
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notifId) async {
    await _db.markNotificationAsRead(notifId, byUser: _requireUser());
    notifyListeners();
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await _db.markAllNotificationsAsRead(byUser: _requireUser());
    notifyListeners();
  }

  Future<void> addUser(UserModel user, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.addUser(user, byUser: byUser ?? _requireUser());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(UserModel updated, {UserModel? byUser}) async {
    await _db.updateUser(updated, byUser: byUser ?? _requireUser());
    notifyListeners();
  }

  Future<void> toggleUserActive(
    String userId,
    bool isActive, {
    UserModel? byUser,
  }) async {
    await _db.toggleUserActive(
      userId,
      isActive,
      byUser: byUser ?? _requireUser(),
    );
    notifyListeners();
  }

  Future<void> deleteUser(String userId, {UserModel? byUser}) async {
    await _db.deleteUser(userId, byUser: byUser ?? _requireUser());
    notifyListeners();
  }

  // ==================== MUASSASALAR VA SINFLAR REYESTRI ====================
  List<Map<String, dynamic>> get institutionsSummary =>
      _db.getInstitutionsSummary();
  List<Map<String, dynamic>> get classesSummary => _db.getClassesSummary();

  // ==================== CSV EXPORT ====================
  String exportStudentsCsv() => _exportService.generateStudentsCsv(students);
  String exportAssessmentsCsv() =>
      _exportService.generateAssessmentsCsv(assessments);
  String exportSessionsCsv() => _exportService.generateSessionsCsv(sessions);
  String exportIepCsv() => _exportService.generateIepCsv(iepPlans);
  String exportAlertsCsv() => _exportService.generateAlertsCsv(alerts);
  String exportReferralsCsv() => _exportService.generateReferralsCsv(referrals);
  String exportAuditLogsCsv() => _exportService.generateAuditLogsCsv(auditLogs);
  String exportObservationsCsv() =>
      _exportService.generateObservationsCsv(observations);

  // ==================== PSIXOLOGIK KUZATUVLAR ====================
  List<PsychologicalObservationModel> getObservationsForStudent(String studentId) {
    return _db.getObservations(forUser: _viewer, studentId: studentId);
  }

  Future<void> addObservation(
    PsychologicalObservationModel observation, {
    UserModel? byUser,
  }) async {
    await _db.addObservation(observation, byUser: byUser ?? _requireUser());
    notifyListeners();
  }

  Future<void> deleteObservation(String id, {UserModel? byUser}) async {
    await _db.deleteObservation(id, byUser: byUser ?? _requireUser());
    notifyListeners();
  }

  // ==================== SAVOL TANLASH VA RIVOJLANISH PROFILI ====================
  /// Bola uchun odatiy savollar to'plami: o'z sinfi (yoki psixolog belgilagan ishchi
  /// sinf) uchun standart savollar, bajarib bo'lmaydiganlari chiqarilgan.
  List<QuestionFit> defaultQuestionsForStudent(
    StudentModel student, {
    String? domain,
  }) => _selection.defaultSet(questions, student, domain: domain);

  /// Barcha savollarni bola uchun tartiblab qaytaradi (mos -> moslashtirish kerak ->
  /// mos emas), har biri sabablari bilan. Psixolog o'zi tanlaydi.
  List<QuestionFit> rankQuestionsForStudent(
    StudentModel student, {
    String? domain,
    int? grade,
  }) {
    return _selection.rankForStudent(
      questions,
      student,
      domain: domain,
      grade: grade,
    );
  }

  /// Bitta savolning bolaga mosligi
  QuestionFit evaluateQuestion(
    AssessmentQuestionModel question,
    StudentModel student, {
    int? grade,
  }) => _selection.evaluate(question, student, grade: grade);

  /// Yo'nalish bo'yicha ishchi sinf (odatda bolaning o'z sinfi)
  int workingGradeFor(StudentModel student, String domain) =>
      _selection.workingGrade(student, domain);

  /// Baholash natijasidan keyin ishchi sinf bo'yicha tavsiya
  LevelChangeAdvice adviseLevelChange(AssessmentModel assessment, int currentGrade) {
    final ratio = assessment.maxScore > 0
        ? assessment.totalScore / assessment.maxScore
        : 0.0;
    return _selection.adviseLevelChange(ratio, currentGrade);
  }

  /// Ikki baholashni foiz bo'yicha solishtirish mumkinmi (bir xil savollar to'plami)
  bool areAssessmentsComparable(AssessmentModel a, AssessmentModel b) =>
      _selection.areComparable(a, b);

  Future<StudentModel> updateStudentAccessProfile(
    String studentId,
    StudentAccessProfile profile,
  ) async {
    final user = _requireUser();
    final updated = await _db.updateAccessProfile(
      studentId,
      profile,
      byUser: user,
    );
    notifyListeners();
    return updated;
  }

  /// [workingGrade] = null — bola yana o'z sinfi savollarini oladi
  Future<StudentModel> setStudentWorkingGrade(
    String studentId,
    String domain,
    int? workingGrade, {
    String? note,
  }) async {
    final user = _requireUser();
    final updated = await _db.setDomainLevel(
      studentId,
      domain,
      workingGrade,
      note: note,
      byUser: user,
    );
    notifyListeners();
    return updated;
  }

  /// Bolaning shaxsiy savollar to'plamlari (tarix bilan)
  List<AssessmentPlanModel> assessmentPlansFor(
    String studentId, {
    String? domain,
    bool onlyActive = false,
  }) {
    final user = _currentUser;
    if (user == null) return [];
    return _db.getAssessmentPlans(
      forUser: user,
      studentId: studentId,
      domain: domain,
      onlyActive: onlyActive,
    );
  }

  /// Qayta baholash uchun joriy to'plam
  AssessmentPlanModel? activeAssessmentPlan(String studentId, String domain) {
    final user = _currentUser;
    if (user == null) return null;
    return _db.getActivePlan(
      forUser: user,
      studentId: studentId,
      domain: domain,
    );
  }

  Future<AssessmentPlanModel> saveAssessmentPlan(AssessmentPlanModel plan) async {
    final user = _requireUser();
    final saved = await _db.saveAssessmentPlan(plan, byUser: user);
    notifyListeners();
    return saved;
  }

  // ==================== DTS: FAN BO'YICHA HAQIQIY DARAJA ====================
  List<String> get curriculumSubjects => _db.getCurriculumSubjects();

  List<CurriculumStandard> curriculumStandards({String? subject, int? grade}) =>
      _db.getCurriculumStandards(subject: subject, grade: grade);

  /// Bilim darajasini baholash: o'qituvchi talablarni belgilaydi, tizim darajani
  /// tavsiya qiladi. [confirmedGrade] — o'qituvchi tasdiqlagan daraja (ixtiyoriy).
  Future<SubjectLevelAssessment> saveSubjectLevel({
    required String studentId,
    required String subject,
    required Map<String, Mastery> results,
    int? confirmedGrade,
    String? notes,
  }) async {
    final saved = await _db.saveSubjectLevel(
      studentId: studentId,
      subject: subject,
      results: results,
      confirmedGrade: confirmedGrade,
      notes: notes,
      byUser: _requireUser(),
    );
    notifyListeners();
    return saved;
  }

  /// Saqlashdan oldin ko'rsatish uchun: natijalardan tavsiya etiladigan daraja
  int? previewSubjectLevel(String subject, Map<String, Mastery> results) =>
      _subjectLevels.suggestGrade(results, curriculumStandards(subject: subject));

  /// Quyiroq sinf talablarini ham tekshirish kerakmi?
  bool subjectLevelNeedsLowerCheck(String subject, Map<String, Mastery> results) =>
      _subjectLevels.needsLowerGradeCheck(
        results,
        curriculumStandards(subject: subject),
      );

  List<SubjectLevelAssessment> subjectLevelHistory(String studentId, {String? subject}) {
    final user = _currentUser;
    if (user == null) return [];
    return _db.getSubjectLevels(forUser: user, studentId: studentId, subject: subject);
  }

  SubjectLevelAssessment? currentSubjectLevel(String studentId, String subject) {
    final user = _currentUser;
    if (user == null) return null;
    return _db.latestSubjectLevel(forUser: user, studentId: studentId, subject: subject);
  }

  /// "7-sinf o'quvchisi, Matematika: 3-sinf darajasi (sinfidan 4 sinf past)"
  String describeSubjectLevel(SubjectLevelAssessment a) => _subjectLevels.describe(a);

  /// Hozirgi darajaga mos keyingi talablar — topshiriq va ITR maqsadlari uchun
  List<CurriculumStandard> nextStandardsFor(String studentId, String subject) {
    final current = currentSubjectLevel(studentId, subject);
    if (current == null) return [];
    return _subjectLevels.nextStandards(
      current.confirmedGrade,
      current.results,
      curriculumStandards(subject: subject),
    );
  }

  /// Fan bo'yicha daraja dinamikasi (tasdiqlangan darajalar bo'yicha)
  DynamicsResult subjectLevelDynamics(
    String studentId,
    String subject, {
    DynamicsPeriod period = DynamicsPeriod.measurement,
  }) {
    final points = subjectLevelHistory(studentId, subject: subject)
        .map((a) => DataPoint(a.assessedAt, a.confirmedGrade.toDouble()))
        .toList();
    return _dynamics.evaluate(
      points,
      period: period,
      absoluteThreshold: 0.5,
      unit: 'sinf darajasi',
    );
  }

  // ==================== O'LCHOVLAR VA DINAMIKA ====================
  List<ProgressMetric> get progressMetrics => _db.getProgressMetrics();

  Future<ProgressMetric> addCustomMetric(ProgressMetric metric) async {
    final saved = await _db.addCustomMetric(metric, byUser: _requireUser());
    notifyListeners();
    return saved;
  }

  Future<ProgressMeasurement> addMeasurement(ProgressMeasurement measurement) async {
    final saved = await _db.addMeasurement(measurement, byUser: _requireUser());
    notifyListeners();
    return saved;
  }

  List<ProgressMeasurement> measurementsFor(String studentId, {String? metricId}) {
    final user = _currentUser;
    if (user == null) return [];
    return _db.getMeasurements(forUser: user, studentId: studentId, metricId: metricId);
  }

  /// Ko'rsatkich bo'yicha dinamika: o'sish / pasayish / barqaror / samarasiz.
  /// [period] — har bir o'lchov, oylik yoki choraklik taqqoslash.
  DynamicsResult measurementDynamics(
    String studentId,
    String metricId, {
    DynamicsPeriod period = DynamicsPeriod.measurement,
  }) {
    final metric = _db.getProgressMetric(metricId);
    final points = measurementsFor(studentId, metricId: metricId)
        .map((m) => DataPoint(m.measuredAt, m.value))
        .toList();
    return _dynamics.evaluate(
      points,
      higherIsBetter: metric?.higherIsBetter ?? true,
      period: period,
      unit: metric?.unit ?? '',
    );
  }

  /// Bir xil savollar to'plami bilan o'tkazilgan baholashlar bo'yicha dinamika (foizda)
  DynamicsResult assessmentDynamics(
    String studentId,
    List<String> questionIds, {
    DynamicsPeriod period = DynamicsPeriod.measurement,
  }) {
    final set = questionIds.toSet();
    final points = assessments
        .where((a) => a.studentId == studentId && a.status == 'completed')
        .where((a) => a.questionIds.toSet().length == set.length &&
            a.questionIds.toSet().containsAll(set))
        .where((a) => a.maxScore > 0)
        .map((a) => DataPoint(a.assessmentDate, a.totalScore / a.maxScore * 100))
        .toList();
    return _dynamics.evaluate(points, period: period, unit: '%');
  }

  // ==================== MUTAXASSIS KABINETI ====================
  /// Joriy foydalanuvchi kabineti: bo'limlar (tartibi bilan), ruxsatlar, yo'nalishlar,
  /// ko'rsatkichlar, mashg'ulot shablonlari va yo'naltirish manzillari.
  SpecialistWorkspace? get workspace {
    final user = _currentUser;
    return user == null ? null : _workspaces.workspaceFor(user);
  }

  bool canUseModule(WorkspaceModule module, {bool edit = false}) {
    final user = _currentUser;
    return user != null && _workspaces.canUse(user, module, edit: edit);
  }

  /// Kabinet bosh sahifasi: o'quvchilarim, hali ishlanmaganlar, e'tibor talab qiladiganlar,
  /// kelgan yo'naltirishlar, yaqin 7 kunlik mashg'ulotlar.
  WorkspaceDashboard? get workspaceDashboard {
    final user = _currentUser;
    return user == null ? null : _workspaces.dashboardFor(user);
  }

  List<StudentModel> get myCaseload {
    final user = _currentUser;
    return user == null ? [] : _workspaces.caseloadFor(user);
  }

  /// Kabinetga mos savollar banki (mutaxassis yo'nalishlari bo'yicha), bola uchun tartiblangan
  List<QuestionFit> workspaceQuestionsFor(StudentModel student) {
    final domains = workspace?.assessmentDomains ?? const <String>[];
    final all = rankQuestionsForStudent(student);
    if (domains.isEmpty) return all;
    return all.where((f) => domains.contains(f.question.domain)).toList();
  }

  /// Kabinetga mos o'lchov ko'rsatkichlari
  List<ProgressMetric> get workspaceMetrics {
    final ids = workspace?.metricIds ?? const <String>[];
    return progressMetrics.where((m) => ids.contains(m.id)).toList();
  }

  // ==================== FAN TOPSHIRIQLARI ====================
  /// Bolaning haqiqiy darajasiga mos topshiriq qoralamalari (keyingi DTS talablaridan).
  /// O'qituvchi tanlaydi, tahrirlaydi va assignSubjectTask bilan beradi.
  List<SubjectTask> suggestSubjectTasks(String studentId, String subject) {
    final user = _currentUser;
    final current = currentSubjectLevel(studentId, subject);
    if (user == null || current == null) return [];
    return nextStandardsFor(studentId, subject)
        .map((s) => SubjectTask(
              id: 'task_${s.id}_${DateTime.now().millisecondsSinceEpoch}',
              studentId: studentId,
              subject: subject,
              levelGrade: s.grade,
              standardId: s.id,
              title: s.description,
              assignedById: user.id,
              assignedByName: user.fullName,
              assignedAt: DateTime.now(),
            ))
        .toList();
  }

  Future<SubjectTask> assignSubjectTask(SubjectTask task) async {
    final saved = await _db.assignSubjectTask(task, byUser: _requireUser());
    notifyListeners();
    return saved;
  }

  Future<SubjectTask> completeSubjectTask(String taskId, Mastery result, {String? note}) async {
    final saved = await _db.completeSubjectTask(taskId, result, note: note, byUser: _requireUser());
    notifyListeners();
    return saved;
  }

  List<SubjectTask> subjectTasksFor(String studentId, {String? subject, bool onlyOpen = false}) {
    final user = _currentUser;
    if (user == null) return [];
    return _db.getSubjectTasks(
      forUser: user, studentId: studentId, subject: subject, onlyOpen: onlyOpen,
    );
  }

  // ==================== MONITORING: QIZIL / SARIQ / YASHIL ====================
  /// Ko'rinadigan barcha bolalar holati (qizil -> sariq -> yashil), sanoqlar bilan
  MonitoringSummary? get monitoringSummary {
    final user = _currentUser;
    return user == null ? null : _childStatus.summaryFor(user);
  }

  /// Bitta bolaning holati va uning sabablari
  ChildStatus childStatus(StudentModel student) =>
      _childStatus.statusFor(student, _requireUser());

  // ==================== YUTUQLAR PASPORTI ====================
  /// "Mening yutuqlar pasportim": qo'lda va avtomatik aniqlangan yutuqlar (yangidan eskiga)
  AchievementPassport achievementPassport(String studentId) =>
      _achievementService.passportFor(studentId, _requireUser());

  Future<Achievement> addAchievement(Achievement achievement) async {
    final saved = await _db.addAchievement(achievement, byUser: _requireUser());
    notifyListeners();
    return saved;
  }

  Future<void> deleteAchievement(String id) async {
    await _db.deleteAchievement(id, byUser: _requireUser());
    notifyListeners();
  }

  // ==================== HISOBOTLAR ====================
  /// Umumiy hisobot (davr berilmasa — oxirgi 30 kun)
  MonitoringReport buildReport({DateTime? from, DateTime? to}) =>
      _reports.build(_requireUser(), from: from, to: to);

  String exportMonitoringReportCsv({DateTime? from, DateTime? to}) =>
      _exportService.generateMonitoringReportCsv(buildReport(from: from, to: to));

  String exportSpecialistActivityCsv({DateTime? from, DateTime? to}) =>
      _exportService.generateSpecialistActivityCsv(buildReport(from: from, to: to));

  // ==================== KONSILIUM ====================
  List<CaseConference> conferencesFor({String? studentId}) {
    final user = _currentUser;
    if (user == null) return [];
    return _db.getConferences(forUser: user, studentId: studentId);
  }

  Future<CaseConference> scheduleConference(CaseConference conference) async {
    final saved = await _db.scheduleConference(conference, byUser: _requireUser());
    notifyListeners();
    return saved;
  }

  Future<CaseConference> addConferenceContribution(
    String conferenceId, {
    required String summary,
    String? recommendations,
  }) async {
    final saved = await _db.addConferenceContribution(
      conferenceId,
      summary: summary,
      recommendations: recommendations,
      byUser: _requireUser(),
    );
    notifyListeners();
    return saved;
  }

  Future<CaseConference> finalizeConference(
    String conferenceId, {
    required String conclusion,
    required List<ConferenceDecision> decisions,
  }) async {
    final saved = await _db.finalizeConference(
      conferenceId,
      conclusion: conclusion,
      decisions: decisions,
      byUser: _requireUser(),
    );
    notifyListeners();
    return saved;
  }

  Future<CaseConference> completeConferenceDecision(String conferenceId, String decisionId) async {
    final saved = await _db.completeConferenceDecision(
      conferenceId,
      decisionId,
      byUser: _requireUser(),
    );
    notifyListeners();
    return saved;
  }

  // ==================== LOGOPEDIK TOVUSHLAR KARTASI ====================
  /// O'zbek tili tovushlari (logopedik guruhlar bilan)
  List<SpeechSound> get speechSounds => UzbekSpeechSounds.all;

  /// Bolaning tovushlar kartasi: har bir maqsadli tovushning bosqichi, tarixi va dinamikasi
  SpeechProfile speechProfile(String studentId) {
    final user = _currentUser;
    if (user == null) return SpeechProfile(studentId, const []);
    return _soundTracker.buildProfile(
      studentId,
      _db.getSoundEntries(forUser: user, studentId: studentId),
    );
  }

  /// Tovush bo'yicha keyingi qadam tavsiyasi
  String soundNextStep(SoundProgress progress) => _soundTracker.nextStep(progress);

  Future<SoundEntry> recordSoundEntry(SoundEntry entry) async {
    final saved = await _db.recordSoundEntry(entry, byUser: _requireUser());
    notifyListeners();
    return saved;
  }

  // ==================== METODIKALAR KUTUBXONASI ====================
  /// Joriy foydalanuvchi kabinetiga mos metodikalar (psixolog — psixologik,
  /// defektolog — defektologik; rahbariyat — barchasi)
  List<PsychologicalMethodItem> get myMethods {
    final user = _currentUser;
    return user == null ? const [] : MethodLibrary.forRole(user.role);
  }

  PsychologicalMethodItem? methodById(String id) => MethodLibrary.byId(id);

  UserModel _requireUser() {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan.');
    }
    return user;
  }
}
