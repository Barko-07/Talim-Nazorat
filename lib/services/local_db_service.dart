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
import '../models/notification_model.dart';
import 'access_control_service.dart';
import 'monitoring_rule_engine.dart';
import 'seed_data.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  final _uuid = const Uuid();
  final _accessControl = AccessControlService();
  final _ruleEngine = MonitoringRuleEngine();

  // Xotiradagi kesh jadvallari (Doimiy SharedPreferences bilan sinxron)
  List<UserModel> _users = [];
  List<StudentModel> _students = [];
  List<AssessmentModel> _assessments = [];
  List<SessionModel> _sessions = [];
  List<IndividualEducationPlanModel> _iepPlans = [];
  List<MonitoringAlertModel> _alerts = [];
  List<ReferralModel> _referrals = [];
  List<AuditLogModel> _auditLogs = [];
  List<NotificationModel> _notifications = [];

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool('app_db_seeded_v2') ?? false;

    if (!isSeeded) {
      // Yangilangan Chortoq va Koordinator ma'lumotlari bilan boshlang'ich to'ldirish
      _users = List.from(SeedData.users);
      _students = List.from(SeedData.students);
      _assessments = List.from(SeedData.assessments);
      _sessions = List.from(SeedData.sessions);
      _iepPlans = List.from(SeedData.iepPlans);
      _alerts = List.from(SeedData.monitoringAlerts);
      _referrals = List.from(SeedData.referrals);
      _auditLogs = List.from(SeedData.auditLogs);
      _notifications = List.from(SeedData.notifications);

      await _persistAll();
      await prefs.setBool('app_db_seeded_v2', true);
    } else {
      _loadFromPrefs(prefs);
    }

    // Monitoring qoidalarini bazadagi mavjud real faktlar bo'yicha baholash
    _reEvaluateRules();

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

      final notifRaw = prefs.getString('db_notifications');
      _notifications = notifRaw != null
          ? (jsonDecode(notifRaw) as List)
              .map((e) => NotificationModel.fromJson(e))
              .toList()
          : List.from(SeedData.notifications);
    } catch (_) {
      _users = List.from(SeedData.users);
      _students = List.from(SeedData.students);
      _assessments = List.from(SeedData.assessments);
      _sessions = List.from(SeedData.sessions);
      _iepPlans = List.from(SeedData.iepPlans);
      _alerts = List.from(SeedData.monitoringAlerts);
      _referrals = List.from(SeedData.referrals);
      _auditLogs = List.from(SeedData.auditLogs);
      _notifications = List.from(SeedData.notifications);
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
    await prefs.setString('db_notifications', jsonEncode(_notifications.map((e) => e.toJson()).toList()));
  }

  void _reEvaluateRules() {
    _alerts = _ruleEngine.evaluateRules(
      students: _students,
      assessments: _assessments,
      sessions: _sessions,
      iepPlans: _iepPlans,
      existingAlerts: _alerts,
    );
  }

  // ==================== FOYDALANUVCHILAR VA XAVFSIZLIK ====================
  List<UserModel> getUsers({UserModel? forUser}) {
    if (forUser == null || forUser.role == UserRole.superAdmin) {
      return List.unmodifiable(_users);
    }
    // Maktab doirasida xodimlarni ko'rsatish
    return _users.where((u) {
      return _accessControl.isSameInstitution(forUser, u.institutionId, u.institutionName);
    }).toList();
  }

  UserModel? findUserByEmailOrPhone(String identifier) {
    final cleanId = identifier.trim().toLowerCase();
    final digitsOnly = cleanId.replaceAll(RegExp(r'\D'), '');

    for (final u in _users) {
      if (u.email.toLowerCase() == cleanId) return u;
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

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> registerUser(UserModel user) async {
    _users.insert(0, user);
    await _persistAll();
    await addAuditLog(
      userFullName: user.fullName,
      userRole: user.role.label,
      action: 'REGISTER',
      entity: 'User',
      details: '${user.fullName} (${user.role.label}) tizimda ro‘yxatdan o‘tdi. Muassasa: ${user.institutionName ?? 'Belgilanmagan'}',
    );
  }

  Future<void> updateUser(UserModel updated, {UserModel? byUser}) async {
    final index = _users.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      _users[index] = updated;
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? updated.fullName,
        userRole: byUser?.role.label ?? updated.role.label,
        action: 'UPDATE',
        entity: 'User',
        details: '${updated.fullName} ma’lumotlari tahrirlandi.',
      );
    }
  }

  Future<void> toggleUserActive(String userId, bool isActive, {UserModel? byUser}) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(isActive: isActive);
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Administrator',
        userRole: byUser?.role.label ?? 'Tizim administratori',
        action: 'PERMISSION_CHANGE',
        entity: 'User',
        details: '${_users[index].fullName} hisobi ${isActive ? 'faollashtirildi' : 'bloklandi'}.',
      );
    }
  }

  // ==================== BOLALAR (STUDENTS) ====================
  List<StudentModel> getStudents({
    UserModel? forUser,
    String? query,
    String? grade,
    String? status,
    bool includeArchived = false,
  }) {
    return _students.where((s) {
      // 1. Huquq va maktab izolyatsiyasi tekshiruvi
      if (forUser != null && !_accessControl.canViewStudent(forUser, s)) {
        return false;
      }
      // 2. Arxivlanganlar filtri
      if (!includeArchived && s.status == 'Arxivlangan' && status != 'Arxivlangan') {
        return false;
      }
      // 3. Qidiruv
      if (query != null && query.trim().isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchesName = s.fullName.toLowerCase().contains(q);
        final matchesNeed = s.primaryNeed.toLowerCase().contains(q);
        final matchesGrade = s.grade.toLowerCase().contains(q);
        if (!matchesName && !matchesNeed && !matchesGrade) return false;
      }
      // 4. Sinf va status
      if (grade != null && grade.isNotEmpty && s.grade != grade) return false;
      if (status != null && status.isNotEmpty && s.status != status) return false;
      return true;
    }).toList();
  }

  StudentModel? getStudentById(String id, {UserModel? forUser}) {
    try {
      final s = _students.firstWhere((st) => st.id == id);
      if (forUser != null && !_accessControl.canViewStudent(forUser, s)) {
        return null;
      }
      return s;
    } catch (_) {
      return null;
    }
  }

  Future<void> addStudent(StudentModel student, {UserModel? byUser}) async {
    _students.insert(0, student);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? 'Foydalanuvchi',
      userRole: byUser?.role.label ?? 'Xodim',
      action: 'CREATE',
      entity: 'Student',
      details: '${student.fullName} (${student.grade}, ${student.institutionName}) bazaga qo‘shildi',
    );
  }

  Future<void> updateStudent(StudentModel updated, {UserModel? byUser}) async {
    final index = _students.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _students[index] = updated;
      _reEvaluateRules();
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Foydalanuvchi',
        userRole: byUser?.role.label ?? 'Xodim',
        action: 'UPDATE',
        entity: 'Student',
        details: '${updated.fullName} anketasi tahrirlandi',
      );
    }
  }

  Future<void> deactivateStudent(String studentId, String reason, {UserModel? byUser}) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final cur = _students[index];
      _students[index] = cur.copyWith(
        status: 'Arxivlangan',
        deactivationReason: reason,
        deactivatedAt: DateTime.now(),
      );
      _reEvaluateRules();
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Administrator',
        userRole: byUser?.role.label ?? 'Administrator',
        action: 'ARCHIVE',
        entity: 'Student',
        details: '${cur.fullName} arxivlandi. Sabab: $reason',
      );
    }
  }

  Future<void> assignSpecialistToStudent(String studentId, String specialistId, {UserModel? byUser}) async {
    final sIndex = _students.indexWhere((s) => s.id == studentId);
    final uIndex = _users.indexWhere((u) => u.id == specialistId);
    if (sIndex != -1 && uIndex != -1) {
      final student = _students[sIndex];
      final specialist = _users[uIndex];

      final updatedSpecIds = List<String>.from(student.assignedSpecialistIds);
      if (!updatedSpecIds.contains(specialistId)) {
        updatedSpecIds.add(specialistId);
      }

      final updatedStudentIds = List<String>.from(specialist.assignedStudentIds);
      if (!updatedStudentIds.contains(studentId)) {
        updatedStudentIds.add(studentId);
      }

      _students[sIndex] = student.copyWith(assignedSpecialistIds: updatedSpecIds);
      _users[uIndex] = specialist.copyWith(assignedStudentIds: updatedStudentIds);

      await createNotification(
        NotificationModel(
          id: 'notif_${_uuid.v4().substring(0, 8)}',
          recipientUserId: specialistId,
          title: 'Yangi o‘quvchi biriktirildi',
          body: '${student.fullName} sizning nazoratingizga biriktirildi.',
          type: 'ASSIGNMENT',
          relatedRecordId: student.id,
          relatedStudentId: student.id,
          relatedStudentName: student.fullName,
          createdAt: DateTime.now(),
        ),
      );

      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Administrator',
        userRole: byUser?.role.label ?? 'Administrator',
        action: 'PERMISSION_CHANGE',
        entity: 'Assignment',
        details: '${specialist.fullName} ${student.fullName}ga mutaxassis sifatida biriktirildi',
      );
    }
  }

  // ==================== BAHOLASHLAR (ASSESSMENTS) ====================
  List<AssessmentModel> getAssessments({
    UserModel? forUser,
    String? studentId,
    String? category,
  }) {
    return _assessments.where((a) {
      if (studentId != null && a.studentId != studentId) return false;
      if (category != null && a.category != category) return false;
      if (forUser != null) {
        final student = getStudentById(a.studentId);
        if (student != null && !_accessControl.canViewStudent(forUser, student)) {
          return false;
        }
      }
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

  Future<void> addAssessment(AssessmentModel assessment, {UserModel? byUser}) async {
    _assessments.insert(0, assessment);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? assessment.specialistName,
      userRole: byUser?.role.label ?? assessment.specialistRole,
      action: 'CREATE',
      entity: 'Assessment',
      details: '${assessment.studentName} uchun ${assessment.category} baholash: ${assessment.title} (${assessment.totalScore}/${assessment.maxScore} ball)',
    );
  }

  // ==================== MASHG'ULOTLAR (SESSIONS) ====================
  List<SessionModel> getSessions({
    UserModel? forUser,
    String? studentId,
    String? specialistId,
  }) {
    return _sessions.where((s) {
      if (studentId != null && s.studentId != studentId) return false;
      if (specialistId != null && s.specialistId != specialistId) return false;
      if (forUser != null) {
        final student = getStudentById(s.studentId);
        if (student != null && !_accessControl.canViewStudent(forUser, student)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<Map<String, dynamic>> addSession(SessionModel session, {UserModel? byUser}) async {
    // 1. Takroriy seans tekshiruvi (Bir xil o'quvchi va mutaxassis uchun bir xil vaqtda seans bormi?)
    final duplicate = _sessions.any((s) =>
        s.studentId == session.studentId &&
        s.specialistId == session.specialistId &&
        s.scheduledAt.year == session.scheduledAt.year &&
        s.scheduledAt.month == session.scheduledAt.month &&
        s.scheduledAt.day == session.scheduledAt.day &&
        s.scheduledAt.hour == session.scheduledAt.hour &&
        s.scheduledAt.minute == session.scheduledAt.minute);

    if (duplicate) {
      return {'success': false, 'message': 'Ushbu vaqtda bu mutaxassis va o‘quvchi uchun allaqachon mashg‘ulot rejalashtirilgan.'};
    }

    _sessions.insert(0, session);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? session.specialistName,
      userRole: byUser?.role.label ?? session.specialistRole,
      action: 'CREATE',
      entity: 'Session',
      details: '${session.studentName} bilan ${session.topic} mashg‘uloti rejalashtirildi',
    );
    return {'success': true};
  }

  Future<void> completeSession(
    String sessionId, {
    required String observations,
    String? nextSteps,
    UserModel? byUser,
  }) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final cur = _sessions[index];
      _sessions[index] = cur.copyWith(
        status: 'Bajarildi',
        attendanceConfirmed: true,
        observations: observations,
        nextSteps: nextSteps ?? cur.nextSteps,
      );
      _reEvaluateRules();
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? cur.specialistName,
        userRole: byUser?.role.label ?? cur.specialistRole,
        action: 'UPDATE',
        entity: 'Session',
        details: '${cur.studentName} bilan ${cur.topic} mashg‘uloti bajarilgan deb tasdiqlandi',
      );
    }
  }

  Future<void> updateSessionStatus(
    String sessionId,
    String status, {
    String? notes,
    UserModel? byUser,
  }) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final cur = _sessions[index];
      _sessions[index] = cur.copyWith(
        status: status,
        observations: notes ?? cur.observations,
        attendanceConfirmed: status == 'Bajarildi',
      );
      _reEvaluateRules();
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? cur.specialistName,
        userRole: byUser?.role.label ?? cur.specialistRole,
        action: 'UPDATE',
        entity: 'Session',
        details: '${cur.studentName} bilan mashg‘ulot holati: $status ga o‘zgardi',
      );
    }
  }

  // ==================== INDIVIDUAL TA'LIM REJASI (ITR / IEP) ====================
  List<IndividualEducationPlanModel> getIepPlans({
    UserModel? forUser,
    String? studentId,
  }) {
    return _iepPlans.where((p) {
      if (studentId != null && p.studentId != studentId) return false;
      if (forUser != null) {
        final student = getStudentById(p.studentId);
        if (student != null && !_accessControl.canViewStudent(forUser, student)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  IndividualEducationPlanModel? getIepById(String id) {
    try {
      return _iepPlans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addIepPlan(IndividualEducationPlanModel plan, {UserModel? byUser}) async {
    _iepPlans.insert(0, plan);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? plan.responsibleTeacherName,
      userRole: byUser?.role.label ?? 'Koordinator',
      action: 'CREATE',
      entity: 'IEP',
      details: '${plan.studentName} uchun ITR rejasi yaratildi (${plan.objectives.length} ta maqsad)',
    );
  }

  Future<void> updateIepPlan(IndividualEducationPlanModel plan, {UserModel? byUser}) async {
    final index = _iepPlans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _iepPlans[index] = plan;
      _reEvaluateRules();
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? plan.responsibleTeacherName,
        userRole: byUser?.role.label ?? 'Koordinator',
        action: 'UPDATE',
        entity: 'IEP',
        details: '${plan.studentName} ning ITR rejasi yangilandi',
      );
    }
  }

  Future<void> updateObjectiveProgress(
    String iepId,
    String objectiveId,
    int progress, {
    String? evidenceNotes,
    UserModel? byUser,
  }) async {
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
          return obj.copyWith(
            progressPercent: progress,
            status: newStatus,
            evidenceNotes: evidenceNotes ?? obj.evidenceNotes,
          );
        }
        return obj;
      }).toList();

      _iepPlans[pIndex] = plan.copyWith(objectives: newObjectives);
      _reEvaluateRules();
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Mutaxassis',
        userRole: byUser?.role.label ?? 'Xodim',
        action: 'UPDATE',
        entity: 'IEP_Objective',
        details: '${plan.studentName} ITR maqsadi bo‘yicha progress: $progress% qilib belgilandi',
      );
    }
  }

  // ==================== MONITORING VA ALERT TRIAGE ====================
  List<MonitoringAlertModel> getAlerts({
    UserModel? forUser,
    bool? onlyUnresolved,
  }) {
    _reEvaluateRules();
    return _alerts.where((a) {
      if (onlyUnresolved == true && a.isResolved) return false;
      if (forUser != null) {
        final student = getStudentById(a.studentId);
        if (student != null && !_accessControl.canViewStudent(forUser, student)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> resolveAlert(String alertId, String notes, {UserModel? byUser}) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      final cur = _alerts[index];
      _alerts[index] = cur.copyWith(
        isResolved: true,
        status: 'Hal qilindi',
        resolvedNotes: notes,
        resolvedAt: DateTime.now(),
      );
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Mutaxassis',
        userRole: byUser?.role.label ?? 'Xodim',
        action: 'RESOLVE',
        entity: 'Alert',
        details: 'Monitoring signali (${cur.ruleTitle}) hal etildi: $notes',
      );
    }
  }

  // ==================== YO'NALTIRISHLAR (REFERRALS) ====================
  List<ReferralModel> getReferrals({UserModel? forUser}) {
    return _referrals.where((r) {
      if (forUser != null) {
        if (!_accessControl.canProcessReferral(forUser, r)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> addReferral(ReferralModel referral, {UserModel? byUser}) async {
    _referrals.insert(0, referral);
    await _persistAll();

    // Agar yo'naltirilgan mutaxassis mavjud bo'lsa unga notifikatsiya jo'natish
    if (referral.toSpecialistId != null && referral.toSpecialistId!.isNotEmpty) {
      await createNotification(
        NotificationModel(
          id: 'notif_${_uuid.v4().substring(0, 8)}',
          recipientUserId: referral.toSpecialistId!,
          title: 'Yangi yo‘naltirish (${referral.priority})',
          body: '${referral.fromSpecialistName} ${referral.studentName}ni ko‘rikdan o‘tkazish uchun yo‘naltirdi.',
          type: 'REFERRAL',
          relatedRecordId: referral.id,
          relatedStudentId: referral.studentId,
          relatedStudentName: referral.studentName,
          createdAt: DateTime.now(),
        ),
      );
    }

    await addAuditLog(
      userFullName: byUser?.fullName ?? referral.fromSpecialistName,
      userRole: byUser?.role.label ?? 'Mutaxassis',
      action: 'CREATE',
      entity: 'Referral',
      details: '${referral.studentName} -> ${referral.toSpecialistType} xizmatiga yo‘naltirildi. Sabab: ${referral.reason}',
    );
  }

  Future<void> updateReferralStatus(
    String referralId,
    String newStatus, {
    String? outcomeNotes,
    String? followUpAction,
    DateTime? followUpDate,
    UserModel? byUser,
  }) async {
    final index = _referrals.indexWhere((r) => r.id == referralId);
    if (index != -1) {
      final cur = _referrals[index];
      _referrals[index] = cur.copyWith(
        status: newStatus,
        outcomeNotes: outcomeNotes ?? cur.outcomeNotes,
        followUpAction: followUpAction ?? cur.followUpAction,
        followUpDate: followUpDate ?? cur.followUpDate,
        updatedAt: DateTime.now(),
      );
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Mutaxassis',
        userRole: byUser?.role.label ?? 'Xodim',
        action: 'UPDATE',
        entity: 'Referral',
        details: 'Yo‘naltirish holati: $newStatus deb belgilandi (${cur.studentName})',
      );
    }
  }

  // ==================== IN-APP NOTIFIKATSIYALAR ====================
  List<NotificationModel> getNotifications(String userId) {
    return _notifications.where((n) => n.recipientUserId == userId).toList();
  }

  int getUnreadNotificationCount(String userId) {
    return _notifications.where((n) => n.recipientUserId == userId && !n.isRead).length;
  }

  Future<void> createNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
    await _persistAll();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _persistAll();
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientUserId == userId && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _persistAll();
  }

  // ==================== AUDIT JURNALI ====================
  List<AuditLogModel> getAuditLogs({UserModel? forUser}) {
    if (forUser != null && !_accessControl.canViewAuditLogs(forUser)) {
      return [];
    }
    return List.unmodifiable(_auditLogs);
  }

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
