import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/assessment_model.dart';
import '../models/session_model.dart';
import '../models/iep_model.dart';
import '../models/monitoring_alert_model.dart';
import '../models/referral_model.dart';
import '../models/audit_log_model.dart';
import 'seed_data.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  final _uuid = const Uuid();

  // Xotiradagi kesh jadvallari (Tezkor murojaat)
  List<UserModel> _users = [];
  List<StudentModel> _students = [];
  List<AssessmentModel> _assessments = [];
  List<SessionModel> _sessions = [];
  List<IndividualEducationPlanModel> _iepPlans = [];
  List<MonitoringAlertModel> _alerts = [];
  List<ReferralModel> _referrals = [];
  List<AuditLogModel> _auditLogs = [];

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool('app_db_seeded_v1') ?? false;

    if (!isSeeded) {
      // Birinchi marta ishga tushganda sifatli o'zbekcha namuna ma'lumotlar bilan to'ldirish
      _users = List.from(SeedData.users);
      _students = List.from(SeedData.students);
      _assessments = List.from(SeedData.assessments);
      _sessions = List.from(SeedData.sessions);
      _iepPlans = List.from(SeedData.iepPlans);
      _alerts = List.from(SeedData.monitoringAlerts);
      _referrals = List.from(SeedData.referrals);
      _auditLogs = List.from(SeedData.auditLogs);

      await _persistAll();
      await prefs.setBool('app_db_seeded_v1', true);
    } else {
      // Diskdan yuklab olish
      _loadFromPrefs(prefs);
    }

    _isInitialized = true;
  }

  void _loadFromPrefs(SharedPreferences prefs) {
    try {
      final usersRaw = prefs.getString('db_users');
      _users = usersRaw != null
          ? (jsonDecode(usersRaw) as List)
              .map((e) => UserModel.fromJson(e))
              .toList()
          : List.from(SeedData.users);

      final studentsRaw = prefs.getString('db_students');
      _students = studentsRaw != null
          ? (jsonDecode(studentsRaw) as List)
              .map((e) => StudentModel.fromJson(e))
              .toList()
          : List.from(SeedData.students);

      final assessmentsRaw = prefs.getString('db_assessments');
      _assessments = assessmentsRaw != null
          ? (jsonDecode(assessmentsRaw) as List)
              .map((e) => AssessmentModel.fromJson(e))
              .toList()
          : List.from(SeedData.assessments);

      final sessionsRaw = prefs.getString('db_sessions');
      _sessions = sessionsRaw != null
          ? (jsonDecode(sessionsRaw) as List)
              .map((e) => SessionModel.fromJson(e))
              .toList()
          : List.from(SeedData.sessions);

      final iepRaw = prefs.getString('db_iep');
      _iepPlans = iepRaw != null
          ? (jsonDecode(iepRaw) as List)
              .map((e) => IndividualEducationPlanModel.fromJson(e))
              .toList()
          : List.from(SeedData.iepPlans);

      final alertsRaw = prefs.getString('db_alerts');
      _alerts = alertsRaw != null
          ? (jsonDecode(alertsRaw) as List)
              .map((e) => MonitoringAlertModel.fromJson(e))
              .toList()
          : List.from(SeedData.monitoringAlerts);

      final referralsRaw = prefs.getString('db_referrals');
      _referrals = referralsRaw != null
          ? (jsonDecode(referralsRaw) as List)
              .map((e) => ReferralModel.fromJson(e))
              .toList()
          : List.from(SeedData.referrals);

      final auditRaw = prefs.getString('db_audit');
      _auditLogs = auditRaw != null
          ? (jsonDecode(auditRaw) as List)
              .map((e) => AuditLogModel.fromJson(e))
              .toList()
          : List.from(SeedData.auditLogs);
    } catch (e) {
      // Zaxira reja
      _users = List.from(SeedData.users);
      _students = List.from(SeedData.students);
      _assessments = List.from(SeedData.assessments);
      _sessions = List.from(SeedData.sessions);
      _iepPlans = List.from(SeedData.iepPlans);
      _alerts = List.from(SeedData.monitoringAlerts);
      _referrals = List.from(SeedData.referrals);
      _auditLogs = List.from(SeedData.auditLogs);
    }
  }

  Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_users', jsonEncode(_users.map((e) => e.toJson()).toList()));
    await prefs.setString('db_students', jsonEncode(_students.map((e) => e.toJson()).toList()));
    await prefs.setString('db_assessments', jsonEncode(_assessments.map((e) => e.toJson()).toList()));
    await prefs.setString('db_sessions', jsonEncode(_sessions.map((e) => e.toJson()).toList()));
    await prefs.setString('db_iep', jsonEncode(_iepPlans.map((e) => e.toJson()).toList()));
    await prefs.setString('db_alerts', jsonEncode(_alerts.map((e) => e.toJson()).toList()));
    await prefs.setString('db_referrals', jsonEncode(_referrals.map((e) => e.toJson()).toList()));
    await prefs.setString('db_audit', jsonEncode(_auditLogs.map((e) => e.toJson()).toList()));
  }

  // --- FOYDALANUVCHILAR VA ROLLOR ---
  List<UserModel> getUsers() => List.unmodifiable(_users);

  UserModel? findUserByEmail(String email) {
    try {
      return _users.firstWhere((u) => u.email.toLowerCase() == email.toLowerCase().trim());
    } catch (_) {
      return null;
    }
  }

  UserModel? findUserByEmailOrPhone(String identifier) {
    final cleanId = identifier.trim().toLowerCase();
    final digitsOnly = cleanId.replaceAll(RegExp(r'\D'), '');

    for (final u in _users) {
      if (u.email.toLowerCase() == cleanId) {
        return u;
      }
      if (u.phone != null) {
        final userDigits = u.phone!.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.isNotEmpty &&
            (userDigits == digitsOnly ||
                userDigits.endsWith(digitsOnly) ||
                digitsOnly.endsWith(userDigits))) {
          return u;
        }
      }
    }
    return null;
  }

  Future<void> registerUser(UserModel user) async {
    _users.insert(0, user);
    await _persistAll();
    await addAuditLog(
      userFullName: user.fullName,
      userRole: user.role.label,
      action: 'REGISTER',
      entity: 'User',
      details: '${user.fullName} (${user.role.label}) tizimda yangi ro‘yxatdan o‘tdi',
    );
  }

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- BOLALAR (STUDENTS) ---
  List<StudentModel> getStudents({String? query, String? grade, String? status}) {
    return _students.where((s) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchesName = s.fullName.toLowerCase().contains(q);
        final matchesNeed = s.primaryNeed.toLowerCase().contains(q);
        if (!matchesName && !matchesNeed) return false;
      }
      if (grade != null && grade.isNotEmpty && s.grade != grade) return false;
      if (status != null && status.isNotEmpty && s.status != status) return false;
      return true;
    }).toList();
  }

  StudentModel? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addStudent(StudentModel student) async {
    _students.insert(0, student);
    await _persistAll();
    await addAuditLog(
      userFullName: 'Tizim foydalanuvchisi',
      userRole: 'Administrator',
      action: 'CREATE',
      entity: 'Student',
      details: '${student.fullName} bazaga qo‘shildi',
    );
  }

  Future<void> updateStudent(StudentModel updated) async {
    final index = _students.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _students[index] = updated;
      await _persistAll();
    }
  }

  // --- BAHOLASHLAR (ASSESSMENTS) ---
  List<AssessmentModel> getAssessments({String? studentId, String? category}) {
    return _assessments.where((a) {
      if (studentId != null && a.studentId != studentId) return false;
      if (category != null && a.category != category) return false;
      return true;
    }).toList();
  }

  AssessmentModel? getAssessmentById(String id) {
    try {
      return _assessments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addAssessment(AssessmentModel assessment) async {
    _assessments.insert(0, assessment);
    await _persistAll();
    await addAuditLog(
      userFullName: assessment.specialistName,
      userRole: assessment.specialistRole,
      action: 'CREATE',
      entity: 'Assessment',
      details: '${assessment.studentName} uchun baholash o‘tkazildi: ${assessment.title}',
    );
  }

  // --- MASHG'ULOTLAR (SESSIONS) ---
  List<SessionModel> getSessions({String? studentId, String? specialistId}) {
    return _sessions.where((s) {
      if (studentId != null && s.studentId != studentId) return false;
      if (specialistId != null && s.specialistId != specialistId) return false;
      return true;
    }).toList();
  }

  Future<void> addSession(SessionModel session) async {
    _sessions.insert(0, session);
    await _persistAll();
  }

  Future<void> updateSessionStatus(String sessionId, String status, {String? notes}) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final current = _sessions[index];
      _sessions[index] = SessionModel(
        id: current.id,
        studentId: current.studentId,
        studentName: current.studentName,
        specialistId: current.specialistId,
        specialistName: current.specialistName,
        specialistRole: current.specialistRole,
        scheduledAt: current.scheduledAt,
        durationMinutes: current.durationMinutes,
        status: status,
        topic: current.topic,
        activities: current.activities,
        observations: notes ?? current.observations,
        nextSteps: current.nextSteps,
      );
      await _persistAll();
    }
  }

  // --- INDIVIDUAL TA'LIM REJASI (ITR / IEP) ---
  List<IndividualEducationPlanModel> getIepPlans({String? studentId}) {
    if (studentId != null) {
      return _iepPlans.where((p) => p.studentId == studentId).toList();
    }
    return List.unmodifiable(_iepPlans);
  }

  IndividualEducationPlanModel? getIepById(String id) {
    try {
      return _iepPlans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateObjectiveProgress(String iepId, String objectiveId, int progress) async {
    final pIndex = _iepPlans.indexWhere((p) => p.id == iepId);
    if (pIndex != -1) {
      final plan = _iepPlans[pIndex];
      final newObjectives = plan.objectives.map((obj) {
        if (obj.id == objectiveId) {
          final newStatus = progress >= 100
              ? 'Bajarildi'
              : progress > 0
                  ? 'Jarayonda'
                  : 'Rejalashtirilgan';
          return PlanObjectiveModel(
            id: obj.id,
            title: obj.title,
            domain: obj.domain,
            targetDate: obj.targetDate,
            status: newStatus,
            progressPercent: progress,
            successCriteria: obj.successCriteria,
          );
        }
        return obj;
      }).toList();

      _iepPlans[pIndex] = IndividualEducationPlanModel(
        id: plan.id,
        studentId: plan.studentId,
        studentName: plan.studentName,
        studentGrade: plan.studentGrade,
        institutionName: plan.institutionName,
        title: plan.title,
        academicYear: plan.academicYear,
        startDate: plan.startDate,
        reviewDate: plan.reviewDate,
        responsibleTeacherId: plan.responsibleTeacherId,
        responsibleTeacherName: plan.responsibleTeacherName,
        status: plan.status,
        baselineSummary: plan.baselineSummary,
        longTermGoals: plan.longTermGoals,
        objectives: newObjectives,
      );
      await _persistAll();
    }
  }

  // --- MONITORING OGOHLANTIRISHLARI (TRIAGE) ---
  List<MonitoringAlertModel> getAlerts({bool? onlyUnresolved}) {
    if (onlyUnresolved == true) {
      return _alerts.where((a) => !a.isResolved).toList();
    }
    return List.unmodifiable(_alerts);
  }

  Future<void> resolveAlert(String alertId, String notes) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(
        isResolved: true,
        resolvedNotes: notes,
        resolvedAt: DateTime.now(),
      );
      await _persistAll();
    }
  }

  // --- YO'NALTIRISHLAR (REFERRALS) ---
  List<ReferralModel> getReferrals() => List.unmodifiable(_referrals);

  Future<void> addReferral(ReferralModel referral) async {
    _referrals.insert(0, referral);
    await _persistAll();
  }

  Future<void> updateReferralStatus(String referralId, String newStatus) async {
    final index = _referrals.indexWhere((r) => r.id == referralId);
    if (index != -1) {
      final current = _referrals[index];
      _referrals[index] = ReferralModel(
        id: current.id,
        studentId: current.studentId,
        studentName: current.studentName,
        fromSpecialistName: current.fromSpecialistName,
        toSpecialistType: current.toSpecialistType,
        reason: current.reason,
        priority: current.priority,
        status: newStatus,
        createdAt: current.createdAt,
      );
      await _persistAll();
    }
  }

  // --- AUDIT JURNALI ---
  List<AuditLogModel> getAuditLogs() => List.unmodifiable(_auditLogs);

  Future<void> addAuditLog({
    required String userFullName,
    required String userRole,
    required String action,
    required String entity,
    required String details,
  }) async {
    final log = AuditLogModel(
      id: _uuid.v4(),
      userFullName: userFullName,
      userRole: userRole,
      action: action,
      entity: entity,
      details: details,
      timestamp: DateTime.now(),
    );
    _auditLogs.insert(0, log);
    await _persistAll();
  }
}
