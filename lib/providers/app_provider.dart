import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/assessment_model.dart';
import '../models/session_model.dart';
import '../models/iep_model.dart';
import '../models/monitoring_alert_model.dart';
import '../models/referral_model.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import '../services/local_db_service.dart';

class AppProvider extends ChangeNotifier {
  final LocalDbService _db = LocalDbService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String? _selectedGrade;
  String? _selectedStatus;

  String get searchQuery => _searchQuery;
  String? get selectedGrade => _selectedGrade;
  String? get selectedStatus => _selectedStatus;

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

  // --- GETTERS ---
  List<StudentModel> get students => _db.getStudents(
        query: _searchQuery,
        grade: _selectedGrade,
        status: _selectedStatus,
      );

  List<AssessmentModel> get assessments => _db.getAssessments();
  List<SessionModel> get sessions => _db.getSessions();
  List<IndividualEducationPlanModel> get iepPlans => _db.getIepPlans();
  List<MonitoringAlertModel> get alerts => _db.getAlerts();
  List<MonitoringAlertModel> get unresolvedAlerts => _db.getAlerts(onlyUnresolved: true);
  List<MonitoringAlertModel> getAlerts({bool onlyUnresolved = false}) =>
      onlyUnresolved ? unresolvedAlerts : alerts;
  List<ReferralModel> get referrals => _db.getReferrals();
  List<AuditLogModel> get auditLogs => _db.getAuditLogs();
  List<UserModel> get specialists => _db.getUsers().where((u) => u.role != UserRole.superAdmin).toList();

  // --- DASHBOARD METRICS ---
  int get totalStudentsCount => _db.getStudents().length;
  int get activeIepCount => _db.getIepPlans().where((p) => p.status == 'Faol').length;
  int get thisMonthSessionsCount => _db.getSessions().length;
  int get attentionNeededCount => unresolvedAlerts.length;

  double get averageDevelopmentGrowth {
    final ass = _db.getAssessments();
    if (ass.isEmpty) return 0;
    double sum = 0;
    int count = 0;
    for (var a in ass) {
      if (a.previousScore != null) {
        sum += (a.totalScore - a.previousScore!);
        count++;
      }
    }
    return count > 0 ? (sum / count) : 12.5; // Foiz
  }

  // --- ACTIONS ---
  Future<void> addStudent(StudentModel student) async {
    _isLoading = true;
    notifyListeners();
    await _db.addStudent(student);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAssessment(AssessmentModel assessment) async {
    _isLoading = true;
    notifyListeners();
    await _db.addAssessment(assessment);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSession(SessionModel session) async {
    _isLoading = true;
    notifyListeners();
    await _db.addSession(session);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSessionStatus(String id, String status, {String? notes}) async {
    await _db.updateSessionStatus(id, status, notes: notes);
    notifyListeners();
  }

  Future<void> updateObjectiveProgress(String iepId, String objId, int progress) async {
    await _db.updateObjectiveProgress(iepId, objId, progress);
    notifyListeners();
  }

  Future<void> resolveAlert(String alertId, String notes) async {
    await _db.resolveAlert(alertId, notes);
    notifyListeners();
  }

  Future<void> addReferral(ReferralModel referral) async {
    await _db.addReferral(referral);
    notifyListeners();
  }

  Future<void> updateReferralStatus(String referralId, String newStatus) async {
    await _db.updateReferralStatus(referralId, newStatus);
    notifyListeners();
  }
}
