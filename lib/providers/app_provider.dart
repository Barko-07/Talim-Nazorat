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
import '../services/local_db_service.dart';
import '../services/report_export_service.dart';

class AppProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService();
  final ReportExportService _exportService = ReportExportService();

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
        forUser: _currentUser,
        query: _searchQuery,
        grade: _selectedGrade,
        status: _selectedStatus,
      );

  List<StudentModel> get allStudentsIncludingArchived => _db.getStudents(
        forUser: _currentUser,
        includeArchived: true,
      );

  List<AssessmentModel> get assessments => _db.getAssessments(forUser: _currentUser);
  List<SessionModel> get sessions => _db.getSessions(forUser: _currentUser);
  List<IndividualEducationPlanModel> get iepPlans => _db.getIepPlans(forUser: _currentUser);
  List<MonitoringAlertModel> get alerts => _db.getAlerts(forUser: _currentUser);
  List<MonitoringAlertModel> get unresolvedAlerts => _db.getAlerts(forUser: _currentUser, onlyUnresolved: true);
  List<MonitoringAlertModel> getAlerts({bool onlyUnresolved = false}) =>
      onlyUnresolved ? unresolvedAlerts : alerts;
  List<ReferralModel> get referrals => _db.getReferrals(forUser: _currentUser);
  List<AuditLogModel> get auditLogs => _db.getAuditLogs(forUser: _currentUser);
  List<UserModel> get specialists => _db.getUsers(forUser: _currentUser).where((u) => u.role != UserRole.superAdmin).toList();
  List<UserModel> get allUsers => _db.getUsers(forUser: _currentUser);

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
    await _db.addStudent(student, byUser: byUser ?? _currentUser);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateStudent(StudentModel student, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    await _db.updateStudent(student, byUser: byUser ?? _currentUser);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deactivateStudent(String studentId, String reason, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    await _db.deactivateStudent(studentId, reason, byUser: byUser ?? _currentUser);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> assignSpecialistToStudent(String studentId, String specialistId, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    await _db.assignSpecialistToStudent(studentId, specialistId, byUser: byUser ?? _currentUser);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAssessment(AssessmentModel assessment, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    await _db.addAssessment(assessment, byUser: byUser ?? _currentUser);
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addSession(SessionModel session, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    final res = await _db.addSession(session, byUser: byUser ?? _currentUser);
    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<void> completeSession(
    String id, {
    required String observations,
    String? nextSteps,
    UserModel? byUser,
  }) async {
    await _db.completeSession(id, observations: observations, nextSteps: nextSteps, byUser: byUser ?? _currentUser);
    notifyListeners();
  }

  Future<void> updateSessionStatus(String id, String status, {String? notes, UserModel? byUser}) async {
    await _db.updateSessionStatus(id, status, notes: notes, byUser: byUser ?? _currentUser);
    notifyListeners();
  }

  Future<void> addIepPlan(IndividualEducationPlanModel plan, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    await _db.addIepPlan(plan, byUser: byUser ?? _currentUser);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateIepPlan(IndividualEducationPlanModel plan, {UserModel? byUser}) async {
    _isLoading = true;
    notifyListeners();
    await _db.updateIepPlan(plan, byUser: byUser ?? _currentUser);
    _isLoading = false;
    notifyListeners();
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
      byUser: byUser ?? _currentUser,
    );
    notifyListeners();
  }

  Future<void> resolveAlert(String alertId, String notes, {UserModel? byUser}) async {
    await _db.resolveAlert(alertId, notes, byUser: byUser ?? _currentUser);
    notifyListeners();
  }

  Future<void> addReferral(ReferralModel referral, {UserModel? byUser}) async {
    await _db.addReferral(referral, byUser: byUser ?? _currentUser);
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
      byUser: byUser ?? _currentUser,
    );
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notifId) async {
    await _db.markNotificationAsRead(notifId);
    notifyListeners();
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await _db.markAllNotificationsAsRead(userId);
    notifyListeners();
  }

  Future<void> updateUser(UserModel updated, {UserModel? byUser}) async {
    await _db.updateUser(updated, byUser: byUser ?? _currentUser);
    notifyListeners();
  }

  Future<void> toggleUserActive(String userId, bool isActive, {UserModel? byUser}) async {
    await _db.toggleUserActive(userId, isActive, byUser: byUser ?? _currentUser);
    notifyListeners();
  }

  // ==================== CSV EXPORT ====================
  String exportStudentsCsv() => _exportService.generateStudentsCsv(students);
  String exportAssessmentsCsv() => _exportService.generateAssessmentsCsv(assessments);
  String exportSessionsCsv() => _exportService.generateSessionsCsv(sessions);
  String exportIepCsv() => _exportService.generateIepCsv(iepPlans);
  String exportAlertsCsv() => _exportService.generateAlertsCsv(alerts);
  String exportReferralsCsv() => _exportService.generateReferralsCsv(referrals);
}
