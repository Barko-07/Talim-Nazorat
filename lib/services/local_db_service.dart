import 'dart:convert';

import 'package:flutter/foundation.dart';
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
import '../models/psychologist_observation_model.dart';
import '../models/assessment_question_model.dart';
import '../models/assessment_plan_model.dart';
import '../models/development_profile_model.dart';
import '../models/curriculum_model.dart';
import '../models/progress_measurement_model.dart';
import '../models/subject_task_model.dart';
import '../models/work_record_model.dart';
import '../models/achievement_model.dart';
import '../models/case_conference_model.dart';
import '../models/speech_sound_model.dart';
import '../core/constants/curriculum_standards_seed.dart';
import '../core/constants/progress_metrics.dart';
import 'subject_level_service.dart';
import 'sound_tracker_service.dart';
import '../core/constants/psychological_questions_seed.dart';
import 'access_control_service.dart';
import 'app_exceptions.dart';
import 'password_hasher.dart';
import 'monitoring_rule_engine.dart';
import 'seed_data.dart';
import '../core/constants/namangan_data.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  final _uuid = const Uuid();
  final _accessControl = AccessControlService();
  final _ruleEngine = MonitoringRuleEngine();
  final _subjectLevels = SubjectLevelService();
  final _soundTracker = SoundTrackerService();

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
  List<PsychologicalObservationModel> _observations = [];
  List<AssessmentQuestionModel> _questions = [];
  List<AssessmentPlanModel> _plans = [];
  List<CurriculumStandard> _curriculum = [];
  List<SubjectLevelAssessment> _subjectLevelRecords = [];
  List<ProgressMeasurement> _measurements = [];
  List<ProgressMetric> _customMetrics = [];
  List<SubjectTask> _subjectTasks = [];
  List<Achievement> _achievements = [];
  List<CaseConference> _conferences = [];
  List<SoundEntry> _soundEntries = [];

  bool _isInitialized = false;

  // O'qishda buzilgan deb topilgan jadvallar (ustidan yozilmaydi)
  final Set<String> _corruptedKeys = {};

  // Jadval -> o'qib bo'lmagan (alohida zaxiralangan) qatorlar soni
  final Map<String, int> _rejectedRowCounts = {};

  /// Ishga tushishda o'qib bo'lmagan qatorlar (jadval -> soni). Ular `<jadval>_rejected_rows`
  /// kalitida saqlanadi; foydalanuvchiga "N ta yozuv o'qilmadi" deb ko'rsatish mumkin.
  Map<String, int> get rejectedRowCounts => Map.unmodifiable(_rejectedRowCounts);

  /// Xotiradagi barcha jadvallarni tozalash — init() har doim toza holatdan boshlanadi
  /// (oldingi holatdan qolgan yozuvlar yangi bazaga aralashmasin).
  void _clearMemory() {
    _users = [];
    _students = [];
    _assessments = [];
    _sessions = [];
    _iepPlans = [];
    _alerts = [];
    _referrals = [];
    _auditLogs = [];
    _notifications = [];
    _observations = [];
    _questions = [];
    _plans = [];
    _curriculum = [];
    _subjectLevelRecords = [];
    _measurements = [];
    _customMetrics = [];
    _subjectTasks = [];
    _achievements = [];
    _conferences = [];
    _soundEntries = [];
    _corruptedKeys.clear();
    _rejectedRowCounts.clear();
  }

  /// Testlar uchun: keyingi init() ma'lumotlarni qaytadan o'qishi uchun.
  @visibleForTesting
  void resetForTest() => _isInitialized = false;

  /// Ishga tushishda o'qib bo'lmagan jadvallar. Bo'sh bo'lmasa, foydalanuvchini ogohlantirish kerak.
  List<String> get loadErrors => List.unmodifiable(_corruptedKeys);

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool('app_db_seeded_v2') ?? false;
    _clearMemory();

    if (!isSeeded && !kDebugMode) {
      // Release build: real foydalanuvchilarga namunaviy bolalar ma'lumoti ko'rsatilmaydi
      _questions = List.from(PsychologicalQuestionsSeed.initialQuestions);
      await _persistAll();
      await prefs.setBool('app_db_seeded_v2', true);
    } else if (!isSeeded) {
      // Faqat debug rejimida: namunaviy ma'lumotlar bilan boshlang'ich to'ldirish
      _users = List.from(SeedData.users);
      _students = List.from(SeedData.students);
      _assessments = List.from(SeedData.assessments);
      _sessions = List.from(SeedData.sessions);
      _iepPlans = List.from(SeedData.iepPlans);
      _alerts = List.from(SeedData.monitoringAlerts);
      _referrals = List.from(SeedData.referrals);
      _auditLogs = List.from(SeedData.auditLogs);
      _notifications = List.from(SeedData.notifications);
      _observations = List.from(SeedData.observations);
      _questions = List.from(PsychologicalQuestionsSeed.initialQuestions);

      await _persistAll();
      await prefs.setBool('app_db_seeded_v2', true);
    } else {
      _loadFromPrefs(prefs);
    }

    await _migratePlainTextPasswords();
    await _syncStandardQuestions();
    await _syncCurriculumSeed();

    // Monitoring qoidalarini bazadagi mavjud real faktlar bo'yicha baholash
    _reEvaluateRules();

    _isInitialized = true;
  }

  void _loadFromPrefs(SharedPreferences prefs) {
    // Har bir jadval alohida o'qiladi. Biror jadval buzilgan bo'lsa, faqat o'sha
    // jadval zaxiralanadi va yozishdan himoyalanadi — boshqa ma'lumotlar saqlanib qoladi.
    // Hech qachon real ma'lumot namunaviy (seed) ma'lumot bilan almashtirilmaydi.
    _corruptedKeys.clear();
    _users = _decodeTable(prefs, 'db_users', UserModel.fromJson);
    _students = _decodeTable(prefs, 'db_students', StudentModel.fromJson);
    _assessments = _decodeTable(
      prefs,
      'db_assessments',
      AssessmentModel.fromJson,
    );
    _sessions = _decodeTable(prefs, 'db_sessions', SessionModel.fromJson);
    _iepPlans = _decodeTable(
      prefs,
      'db_iep',
      IndividualEducationPlanModel.fromJson,
    );
    _alerts = _decodeTable(prefs, 'db_alerts', MonitoringAlertModel.fromJson);
    _referrals = _decodeTable(prefs, 'db_referrals', ReferralModel.fromJson);
    _auditLogs = _decodeTable(prefs, 'db_audit', AuditLogModel.fromJson);
    _notifications = _decodeTable(
      prefs,
      'db_notifications',
      NotificationModel.fromJson,
    );
    _observations = _decodeTable(
      prefs,
      'db_observations',
      PsychologicalObservationModel.fromJson,
    );
    _questions = _decodeTable(
      prefs,
      'db_questions',
      AssessmentQuestionModel.fromJson,
      // Savollar kutubxonasi — metodik kontent, shaxsiy ma'lumot emas
      fallback: () => List.from(PsychologicalQuestionsSeed.initialQuestions),
    );
    _plans = _decodeTable(
      prefs,
      'db_assessment_plans',
      AssessmentPlanModel.fromJson,
    );
    _curriculum = _decodeTable(
      prefs,
      'db_curriculum',
      CurriculumStandard.fromJson,
    );
    _subjectLevelRecords = _decodeTable(
      prefs,
      'db_subject_levels',
      SubjectLevelAssessment.fromJson,
    );
    _measurements = _decodeTable(
      prefs,
      'db_measurements',
      ProgressMeasurement.fromJson,
    );
    _customMetrics = _decodeTable(
      prefs,
      'db_custom_metrics',
      ProgressMetric.fromJson,
    );
    _subjectTasks = _decodeTable(
      prefs,
      'db_subject_tasks',
      SubjectTask.fromJson,
    );
    _achievements = _decodeTable(
      prefs,
      'db_achievements',
      Achievement.fromJson,
    );
    _conferences = _decodeTable(
      prefs,
      'db_conferences',
      CaseConference.fromJson,
    );
    _soundEntries = _decodeTable(
      prefs,
      'db_sound_entries',
      SoundEntry.fromJson,
    );
  }

  List<T> _decodeTable<T>(
    SharedPreferences prefs,
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    List<T> Function()? fallback,
  }) {
    final raw = prefs.getString(key);
    if (raw == null) return fallback?.call() ?? <T>[];

    // 1. Jadvalning o'zi o'qilmasa — butunlay zaxiralanadi va ustidan yozilmaydi
    final List<dynamic> rows;
    try {
      rows = jsonDecode(raw) as List;
    } catch (e) {
      _corruptedKeys.add(key);
      prefs.setString('${key}_corrupt_backup', raw);
      debugPrint('LocalDbService: "$key" jadvalini o‘qib bo‘lmadi: $e');
      return <T>[];
    }

    // 2. Alohida buzilgan qatorlar boshqalarini yashirmasligi kerak: ular alohida
    // zaxiraga olinadi, qolgan qatorlar odatdagidek yuklanadi.
    final result = <T>[];
    final rejected = <dynamic>[];
    for (final row in rows) {
      try {
        result.add(fromJson(row as Map<String, dynamic>));
      } catch (_) {
        rejected.add(row);
      }
    }
    if (rejected.isNotEmpty) {
      final backupKey = '${key}_rejected_rows';
      var previous = <dynamic>[];
      try {
        previous = jsonDecode(prefs.getString(backupKey) ?? '[]') as List;
      } catch (_) {}
      prefs.setString(backupKey, jsonEncode([...previous, ...rejected]));
      _rejectedRowCounts[key] = rejected.length;
      debugPrint(
        'LocalDbService: "$key" jadvalida ${rejected.length} ta qator o‘qilmadi — "$backupKey" ga zaxiralandi',
      );
    }
    return result;
  }

  Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();
    await _writeTable(prefs, 'db_users', _users.map((e) => e.toJson()));
    await _writeTable(prefs, 'db_students', _students.map((e) => e.toJson()));
    await _writeTable(
      prefs,
      'db_assessments',
      _assessments.map((e) => e.toJson()),
    );
    await _writeTable(prefs, 'db_sessions', _sessions.map((e) => e.toJson()));
    await _writeTable(prefs, 'db_iep', _iepPlans.map((e) => e.toJson()));
    await _writeTable(prefs, 'db_alerts', _alerts.map((e) => e.toJson()));
    await _writeTable(
      prefs,
      'db_referrals',
      _referrals.map((e) => e.toJson()),
    );
    await _writeTable(prefs, 'db_audit', _auditLogs.map((e) => e.toJson()));
    await _writeTable(
      prefs,
      'db_notifications',
      _notifications.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_observations',
      _observations.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_questions',
      _questions.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_assessment_plans',
      _plans.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_curriculum',
      _curriculum.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_subject_levels',
      _subjectLevelRecords.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_measurements',
      _measurements.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_custom_metrics',
      _customMetrics.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_subject_tasks',
      _subjectTasks.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_achievements',
      _achievements.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_conferences',
      _conferences.map((e) => e.toJson()),
    );
    await _writeTable(
      prefs,
      'db_sound_entries',
      _soundEntries.map((e) => e.toJson()),
    );
  }

  Future<void> _writeTable(
    SharedPreferences prefs,
    String key,
    Iterable<Map<String, dynamic>> rows,
  ) async {
    // Buzilgan jadval ustidan yozilmaydi — asl ma'lumotni tiklash imkoniyati saqlanadi
    if (_corruptedKeys.contains(key)) return;
    await prefs.setString(key, jsonEncode(rows.toList()));
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

  // ==================== LOGOPEDIK TOVUSHLAR KARTASI ====================
  /// Tovush bosqichini qayd etish (bolaga biriktirilgan logoped yoki tizim administratori).
  /// Qaydlar o'chirilmaydi — har bir o'zgarish tarixda qoladi.
  Future<SoundEntry> recordSoundEntry(
    SoundEntry entry, {
    required UserModel byUser,
  }) async {
    final student = _studentOrThrow(entry.studentId);
    _require(
      _accessControl.canTrackSounds(byUser, student),
      'tovushlar kartasini bolaga biriktirilgan logoped yuritadi.',
    );
    final error = _soundTracker.validate(entry, DateTime.now());
    if (error != null) throw ValidationException(error);

    final saved = SoundEntry(
      id: entry.id,
      studentId: entry.studentId,
      soundId: entry.soundId,
      stage: entry.stage,
      disorder: entry.disorder,
      substitutedWith:
          entry.disorder == SoundDisorder.substitution ? entry.substitutedWith : null,
      differentiatedFrom: entry.differentiatedFrom,
      note: entry.note,
      recordedById: byUser.id,
      recordedByName: byUser.fullName,
      recordedAt: entry.recordedAt,
    );
    if (_soundEntries.any((e) => e.id == saved.id)) {
      throw const ValidationException('Bu qayd allaqachon saqlangan.');
    }
    _soundEntries.add(saved);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'SoundEntry',
      details:
          '${student.fullName}: "${saved.soundId}" tovushi — ${saved.stage.label}',
    );
    return saved;
  }

  /// Bolaning tovush qaydlari (eskidan yangiga)
  List<SoundEntry> getSoundEntries({
    required UserModel forUser,
    required String studentId,
    String? soundId,
  }) {
    final student = getStudentById(studentId);
    if (student == null || !_accessControl.canViewStudent(forUser, student)) {
      return [];
    }
    return _soundEntries
        .where((e) => e.studentId == studentId)
        .where((e) => soundId == null || e.soundId == soundId)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  }

  // ==================== KONSILIUM ====================
  /// Konsiliumni rejalashtirish (koordinator, muassasa rahbari yoki tizim administratori).
  /// Ishtirokchilar — shu maktabning bolalar bilan ishlaydigan faol mutaxassislari (kamida 2 nafar).
  Future<CaseConference> scheduleConference(
    CaseConference conference, {
    required UserModel byUser,
  }) async {
    final student = _studentOrThrow(conference.studentId);
    _require(
      _accessControl.canAssignSpecialists(byUser, student),
      'konsiliumni koordinator yoki muassasa rahbari chaqiradi.',
    );
    if (conference.agenda.trim().isEmpty) {
      throw const ValidationException('Konsilium kun tartibini kiriting.');
    }
    final participants = conference.participantIds.toSet().toList();
    if (participants.length < 2) {
      throw const ValidationException('Konsiliumda kamida 2 nafar mutaxassis ishtirok etishi kerak.');
    }
    for (final id in participants) {
      final u = getUserById(id);
      if (u == null || !_accessControl.canBeAssigned(u, student)) {
        throw ValidationException(
          'Ishtirokchi ${u?.fullName ?? id} shu maktabning faol mutaxassisi emas.',
        );
      }
    }
    final saved = CaseConference(
      id: conference.id,
      studentId: student.id,
      studentName: student.fullName,
      agenda: conference.agenda.trim(),
      scheduledAt: conference.scheduledAt,
      convenedById: byUser.id,
      convenedByName: byUser.fullName,
      participantIds: participants,
    );
    _conferences.removeWhere((c) => c.id == saved.id);
    _conferences.add(saved);
    for (final id in participants) {
      _notifications.insert(
        0,
        NotificationModel(
          id: 'notif_${_uuid.v4().substring(0, 8)}',
          recipientUserId: id,
          title: 'Konsiliumga taklif',
          body: '${student.fullName} bo‘yicha konsilium: ${saved.agenda}',
          type: 'CONFERENCE',
          relatedRecordId: saved.id,
          relatedStudentId: student.id,
          relatedStudentName: student.fullName,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'CaseConference',
      details: '${student.fullName} bo‘yicha konsilium rejalashtirildi (${participants.length} ishtirokchi)',
    );
    return saved;
  }

  CaseConference _conferenceOrThrow(String id) {
    final c = _conferences.where((c) => c.id == id);
    if (c.isEmpty) throw const NotFoundException('Konsilium topilmadi.');
    return c.first;
  }

  void _replaceConference(CaseConference updated) {
    final i = _conferences.indexWhere((c) => c.id == updated.id);
    _conferences[i] = updated;
  }

  /// Ishtirokchi o'z xulosasini kiritadi (qayta yuborilsa — yangilanadi)
  Future<CaseConference> addConferenceContribution(
    String conferenceId, {
    required String summary,
    String? recommendations,
    required UserModel byUser,
  }) async {
    final conf = _conferenceOrThrow(conferenceId);
    _require(
      conf.participantIds.contains(byUser.id),
      'xulosani faqat konsilium ishtirokchisi kiritadi.',
    );
    if (conf.status != ConferenceStatus.planned) {
      throw const ValidationException('Konsilium yakunlangan — xulosa qo‘shib bo‘lmaydi.');
    }
    if (summary.trim().isEmpty) {
      throw const ValidationException('Xulosa matnini kiriting.');
    }
    final updated = conf.copyWith(
      contributions: [
        ...conf.contributions.where((c) => c.userId != byUser.id),
        ConferenceContribution(
          userId: byUser.id,
          userName: byUser.fullName,
          role: byUser.role.label,
          summary: summary.trim(),
          recommendations: recommendations,
          at: DateTime.now(),
        ),
      ],
    );
    _replaceConference(updated);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'CaseConference',
      details: '${conf.studentName} konsiliumiga xulosa kiritildi',
    );
    return updated;
  }

  /// Konsiliumni yakunlash: umumiy xulosa va qarorlar (chaqiruvchi yoki tizim administratori)
  Future<CaseConference> finalizeConference(
    String conferenceId, {
    required String conclusion,
    required List<ConferenceDecision> decisions,
    required UserModel byUser,
  }) async {
    final conf = _conferenceOrThrow(conferenceId);
    _require(
      conf.convenedById == byUser.id || byUser.role == UserRole.superAdmin,
      'konsiliumni uni chaqirgan mas’ul yakunlaydi.',
    );
    if (conf.status != ConferenceStatus.planned) {
      throw const ValidationException('Konsilium allaqachon yakunlangan yoki bekor qilingan.');
    }
    if (conclusion.trim().isEmpty) {
      throw const ValidationException('Konsiliumning umumiy xulosasini kiriting.');
    }
    for (final d in decisions) {
      if (d.text.trim().isEmpty) {
        throw const ValidationException('Har bir qaror matnini kiriting.');
      }
      if (!conf.isParticipant(d.responsibleId)) {
        throw const ValidationException('Qaror mas’uli konsilium ishtirokchilaridan bo‘lishi kerak.');
      }
    }
    final now = DateTime.now();
    final updated = conf.copyWith(
      status: ConferenceStatus.held,
      conclusion: conclusion.trim(),
      decisions: [
        for (final d in decisions)
          ConferenceDecision(
            id: d.id,
            text: d.text.trim(),
            responsibleId: d.responsibleId,
            responsibleName: getUserById(d.responsibleId)?.fullName ?? d.responsibleName,
            dueDate: d.dueDate,
          ),
      ],
      heldAt: now,
    );
    _replaceConference(updated);
    for (final d in updated.decisions) {
      if (d.responsibleId == byUser.id) continue;
      _notifications.insert(
        0,
        NotificationModel(
          id: 'notif_${_uuid.v4().substring(0, 8)}',
          recipientUserId: d.responsibleId,
          title: 'Konsilium qarori: sizga topshiriq',
          body: '${conf.studentName}: ${d.text}',
          type: 'CONFERENCE_DECISION',
          relatedRecordId: conf.id,
          relatedStudentId: conf.studentId,
          relatedStudentName: conf.studentName,
          createdAt: now,
        ),
      );
    }
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'CaseConference',
      details: '${conf.studentName} konsiliumi yakunlandi (${decisions.length} ta qaror)',
    );
    return updated;
  }

  /// Qarorni bajarilgan deb belgilash (mas'ul yoki konsiliumni chaqirgan shaxs)
  Future<CaseConference> completeConferenceDecision(
    String conferenceId,
    String decisionId, {
    required UserModel byUser,
  }) async {
    final conf = _conferenceOrThrow(conferenceId);
    final decision = conf.decisions.where((d) => d.id == decisionId);
    if (decision.isEmpty) throw const NotFoundException('Qaror topilmadi.');
    _require(
      decision.first.responsibleId == byUser.id ||
          conf.convenedById == byUser.id ||
          byUser.role == UserRole.superAdmin,
      'qarorni faqat uning mas’uli yoki konsilium chaqiruvchisi yopadi.',
    );
    final updated = conf.copyWith(
      decisions: [
        for (final d in conf.decisions)
          d.id == decisionId ? d.markDone(DateTime.now()) : d,
      ],
    );
    _replaceConference(updated);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'CaseConference',
      details: '${conf.studentName}: konsilium qarori bajarildi — ${decision.first.text}',
    );
    return updated;
  }

  /// Konsiliumlar: ishtirokchilar, maktab rahbariyati va koordinator ko'radi
  List<CaseConference> getConferences({
    required UserModel forUser,
    String? studentId,
  }) {
    return _conferences.where((c) {
      if (studentId != null && c.studentId != studentId) return false;
      final student = getStudentById(c.studentId);
      if (student == null) return false;
      final schoolWide = forUser.role == UserRole.superAdmin ||
          AccessControlService.schoolWideRoles.contains(forUser.role);
      if (schoolWide) return _accessControl.canViewStudent(forUser, student);
      return forUser.isActive && c.isParticipant(forUser.id);
    }).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  // ==================== YUTUQLAR PASPORTI ====================
  /// Mutaxassis qo'lda kiritgan yutuqlar (avtomatik yutuqlar AchievementService'da hisoblanadi)
  List<Achievement> getManualAchievements(String studentId) =>
      _achievements.where((a) => a.studentId == studentId).toList();

  Future<Achievement> addAchievement(
    Achievement achievement, {
    required UserModel byUser,
  }) async {
    final student = _studentOrThrow(achievement.studentId);
    _require(
      _accessControl.canCreateAssessment(byUser, student),
      'yutuqni faqat bola bilan ishlaydigan mutaxassis kiritadi.',
    );
    if (achievement.title.trim().isEmpty) {
      throw const ValidationException('Yutuq nomini kiriting.');
    }
    if (achievement.achievedAt.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      throw const ValidationException('Yutuq sanasi kelajakda bo‘lishi mumkin emas.');
    }
    final saved = Achievement(
      id: achievement.id,
      studentId: achievement.studentId,
      category: achievement.category,
      title: achievement.title.trim(),
      description: achievement.description,
      achievedAt: achievement.achievedAt,
      recordedById: byUser.id,
      recordedByName: byUser.fullName,
    );
    _achievements.removeWhere((a) => a.id == saved.id);
    _achievements.add(saved);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'Achievement',
      details: '${student.fullName}: yutuq qayd etildi — ${saved.title}',
    );
    return saved;
  }

  Future<void> deleteAchievement(String id, {required UserModel byUser}) async {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index == -1) throw const NotFoundException('Yutuq topilmadi.');
    final target = _achievements[index];
    _require(
      target.recordedById == byUser.id || byUser.role == UserRole.superAdmin,
      'yutuqni faqat uni kiritgan mutaxassis o‘chiradi.',
    );
    _achievements.removeAt(index);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'DELETE',
      entity: 'Achievement',
      details: 'Yutuq o‘chirildi: ${target.title}',
    );
  }

  // ==================== ISH YOZUVLARI (MONITORING UCHUN) ====================
  /// Bola bilan qilingan barcha ishlar: kim, qachon, qanday ish. Mazmunsiz (maxfiy
  /// kuzatuv matni ochilmaydi). Chaqiruvchi bolani ko'rish huquqini o'zi tekshiradi.
  List<WorkRecord> getWorkRecords(String studentId) {
    return [
      for (final a in _assessments)
        if (a.studentId == studentId)
          WorkRecord(a.specialistId, a.assessmentDate, WorkKind.assessment),
      for (final s in _sessions)
        if (s.studentId == studentId && s.isCompleted)
          WorkRecord(s.specialistId, s.scheduledAt, WorkKind.session),
      for (final o in _observations)
        if (o.studentId == studentId)
          WorkRecord(o.psychologistId, o.date, WorkKind.observation),
      for (final m in _measurements)
        if (m.studentId == studentId)
          WorkRecord(m.recordedById, m.measuredAt, WorkKind.measurement),
      for (final l in _subjectLevelRecords)
        if (l.studentId == studentId)
          WorkRecord(l.assessedById, l.assessedAt, WorkKind.subjectLevel),
      for (final t in _subjectTasks)
        if (t.studentId == studentId)
          WorkRecord(
            t.assignedById,
            t.completedAt ?? t.assignedAt,
            WorkKind.subjectTask,
          ),
      for (final c in _conferences)
        if (c.studentId == studentId)
          for (final contribution in c.contributions)
            WorkRecord(contribution.userId, contribution.at, WorkKind.conference),
      for (final e in _soundEntries)
        if (e.studentId == studentId)
          WorkRecord(e.recordedById, e.recordedAt, WorkKind.soundTracking),
    ]..sort((a, b) => a.at.compareTo(b.at));
  }

  // ==================== RUXSAT YORDAMCHILARI ====================
  void _require(bool allowed, String reason) {
    if (!allowed) throw PermissionDeniedException(reason);
  }

  StudentModel _studentOrThrow(String id) {
    final s = getStudentById(id);
    if (s == null) throw const NotFoundException('O‘quvchi topilmadi.');
    return s;
  }

  /// [actor] [target] foydalanuvchini boshqara oladimi (o'z maktabi doirasida)
  bool _canManageUser(UserModel actor, UserModel target) {
    if (!_accessControl.canManageUsers(actor)) return false;
    if (actor.role == UserRole.superAdmin) return true;
    return target.role != UserRole.superAdmin &&
        _accessControl.isSameInstitution(
          actor,
          target.institutionId,
          target.institutionName,
        );
  }

  // ==================== FOYDALANUVCHILAR VA XAVFSIZLIK ====================
  List<UserModel> getUsers({UserModel? forUser}) {
    if (forUser != null && !forUser.isActive) return const [];
    if (forUser == null || forUser.role == UserRole.superAdmin) {
      return List.unmodifiable(_users);
    }
    // Maktab doirasida xodimlarni ko'rsatish
    return _users.where((u) {
      return _accessControl.isSameInstitution(
        forUser,
        u.institutionId,
        u.institutionName,
      );
    }).toList();
  }

  UserModel? findUserByEmailOrPhone(String identifier) {
    final cleanId = identifier.trim().toLowerCase();
    if (cleanId.isEmpty) return null;
    final phoneKey = _phoneKey(cleanId);

    for (final u in _users) {
      if (u.email.toLowerCase() == cleanId) return u;
      // Telefon faqat to'liq mos kelganda (oxirgi 9 raqam: operator kodi + raqam)
      if (phoneKey != null && u.phone != null && _phoneKey(u.phone!) == phoneKey) {
        return u;
      }
    }
    return null;
  }

  /// Telefon raqamini taqqoslash kaliti: +998 dan keyingi 9 raqam.
  /// 9 tadan kam raqam kiritilsa — telefon sifatida qabul qilinmaydi.
  String? _phoneKey(String input) {
    if (input.contains('@')) return null;
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return null;
    return digits.substring(digits.length - 9);
  }

  /// Kiritilgan parolni saqlangan xesh bilan tekshirish.
  bool verifyPassword(UserModel user, String password) {
    if (PasswordHasher.verify(password, user.password)) return true;
    // Namunaviy (seed) hisoblarda parol yo'q — ular faqat debug rejimida ishlaydi
    return kDebugMode &&
        user.password == null &&
        password == SeedData.demoPassword;
  }

  UserModel _withHashedPassword(UserModel user) {
    final pass = user.password;
    if (pass == null || PasswordHasher.isHashed(pass)) return user;
    return user.copyWith(password: PasswordHasher.hash(pass));
  }

  /// Ilova yangilanganda standart savollar bankini yangilash: yangi standart savollar
  /// qo'shiladi, mavjudlarida bo'sh qolgan sinf va talab ma'lumotlari to'ldiriladi.
  /// Psixologlar yozgan savollarga tegilmaydi.
  Future<void> _syncStandardQuestions() async {
    if (_corruptedKeys.contains('db_questions')) return;
    var changed = false;
    for (final seed in PsychologicalQuestionsSeed.initialQuestions) {
      final i = _questions.indexWhere((q) => q.id == seed.id);
      if (i == -1) {
        _questions.add(seed);
        changed = true;
        continue;
      }
      final cur = _questions[i];
      if (!cur.isStandard) continue;
      final needsFill =
          (cur.requirements == null && seed.requirements != null) ||
          (cur.adaptationHint == null && seed.adaptationHint != null) ||
          (cur.minGrade == null && seed.minGrade != null) ||
          (cur.maxGrade == null && seed.maxGrade != null);
      if (needsFill) {
        _questions[i] = cur.copyWith(
          requirements: cur.requirements ?? seed.requirements,
          adaptationHint: cur.adaptationHint ?? seed.adaptationHint,
          minGrade: cur.minGrade ?? seed.minGrade,
          maxGrade: cur.maxGrade ?? seed.maxGrade,
        );
        changed = true;
      }
    }
    if (changed) await _persistAll();
  }

  /// Eski versiyalarda ochiq matn sifatida saqlangan parollarni xeshlash
  Future<void> _migratePlainTextPasswords() async {
    var changed = false;
    for (var i = 0; i < _users.length; i++) {
      final hashed = _withHashedPassword(_users[i]);
      if (!identical(hashed, _users[i])) {
        _users[i] = hashed;
        changed = true;
      }
    }
    if (changed) await _persistAll();
  }

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// O'zini o'zi ro'yxatdan o'tkazishi mumkin bo'lgan rollar. Rahbariyat, koordinator va
  /// administrator hisoblari faqat administrator tomonidan yaratiladi (addUser).
  static const selfRegistrationRoles = {
    UserRole.psychologist,
    UserRole.speechTherapist,
    UserRole.specialEducation,
    UserRole.specialEdTeacher,
    UserRole.teacher,
  };

  /// Mutaxassisning o'zini ro'yxatdan o'tkazishi
  Future<void> registerUser(UserModel user) async {
    _require(
      selfRegistrationRoles.contains(user.role),
      'bu rol bilan o‘zingiz ro‘yxatdan o‘ta olmaysiz — hisobni administrator yaratadi.',
    );
    if (findUserByEmailOrPhone(user.email) != null ||
        (user.phone != null &&
            user.phone!.isNotEmpty &&
            findUserByEmailOrPhone(user.phone!) != null)) {
      throw const ValidationException(
        'Ushbu telefon raqam yoki pochta bilan hisob allaqachon mavjud.',
      );
    }
    // Biriktirishlar faqat koordinator orqali; yangi hisob faol holatda boshlanadi
    user = _withHashedPassword(
      user.copyWith(assignedStudentIds: const [], isActive: true),
    );
    _users.insert(0, user);
    await _persistAll();
    await addAuditLog(
      userFullName: user.fullName,
      userRole: user.role.label,
      action: 'REGISTER',
      entity: 'User',
      details:
          '${user.fullName} (${user.role.label}) tizimda ro‘yxatdan o‘tdi. Muassasa: ${user.institutionName ?? 'Belgilanmagan'}',
    );
  }

  /// Administrator tomonidan yangi foydalanuvchi yaratish
  Future<void> addUser(UserModel user, {required UserModel byUser}) async {
    _require(
      _canManageUser(byUser, user),
      'foydalanuvchini faqat tizim administratori yoki o‘z maktabi rahbari qo‘sha oladi.',
    );
    if (findUserByEmailOrPhone(user.email) != null) {
      throw const ValidationException(
        'Ushbu elektron pochta manzili bilan foydalanuvchi mavjud.',
      );
    }
    if (user.phone != null &&
        user.phone!.isNotEmpty &&
        findUserByEmailOrPhone(user.phone!) != null) {
      throw const ValidationException(
        'Ushbu telefon raqam bilan foydalanuvchi ro‘yxatdan o‘tgan.',
      );
    }

    _users.insert(0, _withHashedPassword(user));
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'User',
      details:
          'Yangi foydalanuvchi yaratildi: ${user.fullName} (${user.role.label}, ${user.institutionName ?? 'Muassasa ko‘rsatilmagan'})',
    );
  }

  /// Foydalanuvchi ma'lumotlarini yangilash. Oddiy foydalanuvchi faqat o'z profilini
  /// (ism, telefon, parol...) o'zgartiradi — rol, muassasa, holat va biriktirishlarni emas.
  Future<void> updateUser(UserModel updated, {required UserModel byUser}) async {
    final index = _users.indexWhere((u) => u.id == updated.id);
    if (index == -1) throw const NotFoundException('Foydalanuvchi topilmadi.');
    final current = _users[index];

    final isManager =
        _canManageUser(byUser, current) && _canManageUser(byUser, updated);
    if (!isManager) {
      _require(
        byUser.id == updated.id,
        'boshqa foydalanuvchi ma’lumotlarini o‘zgartirish huquqi yo‘q.',
      );
      final privilegedChange =
          current.role != updated.role ||
          current.isActive != updated.isActive ||
          current.institutionId != updated.institutionId ||
          current.institutionName != updated.institutionName ||
          !listEquals(current.assignedStudentIds, updated.assignedStudentIds);
      _require(
        !privilegedChange,
        'o‘z rolingiz, muassasangiz, holatingiz yoki biriktirilgan o‘quvchilaringizni o‘zgartira olmaysiz.',
      );
    }

    _users[index] = _withHashedPassword(updated);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'User',
      details:
          '${updated.fullName} (${updated.role.label}) ma’lumotlari tahrirlandi.',
    );
  }

  Future<void> toggleUserActive(
    String userId,
    bool isActive, {
    required UserModel byUser,
  }) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) throw const NotFoundException('Foydalanuvchi topilmadi.');
    final target = _users[index];
    _require(
      _canManageUser(byUser, target),
      'foydalanuvchi holatini o‘zgartirish uchun administrator huquqi talab qilinadi.',
    );
    if (target.role == UserRole.superAdmin && !isActive) {
      throw const ValidationException(
        'Asosiy tizim administratorini bloklash taqiqlanadi.',
      );
    }
    if (target.id == byUser.id && !isActive) {
      throw const ValidationException('O‘z hisobingizni bloklay olmaysiz.');
    }

    _users[index] = target.copyWith(isActive: isActive);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'PERMISSION_CHANGE',
      entity: 'User',
      details:
          '${target.fullName} hisobi ${isActive ? 'faollashtirildi' : 'bloklandi'}.',
    );
  }

  Future<void> deleteUser(String userId, {required UserModel byUser}) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) throw const NotFoundException('Foydalanuvchi topilmadi.');
    final target = _users[index];
    _require(
      _canManageUser(byUser, target),
      'foydalanuvchini o‘chirish huquqi mavjud emas.',
    );
    if (target.role == UserRole.superAdmin) {
      throw const ValidationException(
        'Asosiy tizim administratorini o‘chirib bo‘lmaydi.',
      );
    }
    if (target.id == byUser.id) {
      throw const ValidationException('O‘z hisobingizni o‘chira olmaysiz.');
    }

    _users.removeAt(index);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'DELETE',
      entity: 'User',
      details:
          'Foydalanuvchi tizimdan o‘chirildi: ${target.fullName} (${target.role.label})',
    );
  }

  // ==================== MUASSASALAR VA SINFLAR REYESTRI ====================
  List<Map<String, dynamic>> getInstitutionsSummary() {
    final Map<String, Map<String, dynamic>> map = {};

    // 1. Dastlab ma'lumotlar bazasidagi o'quvchilar va mutaxassislar orqali aniqlash
    for (final s in _students) {
      final name = s.institutionName.trim();
      if (name.isEmpty) continue;
      if (!map.containsKey(name)) {
        map[name] = {
          'name': name,
          'district': 'Chortoq tumani',
          'type': name.contains('internat')
              ? 'Ixtisoslashtirilgan maktab-internati'
              : name.contains('inklyuziv')
                  ? 'Inklyuziv tayanch maktab'
                  : 'Umumiy o‘rta ta’lim maktabi',
          'studentsCount': 0,
          'specialistsCount': 0,
          'activeIepCount': 0,
        };
      }
      map[name]!['studentsCount'] = (map[name]!['studentsCount'] as int) + 1;
    }

    for (final u in _users) {
      final name = u.institutionName?.trim() ?? '';
      if (name.isEmpty) continue;
      if (!map.containsKey(name)) {
        map[name] = {
          'name': name,
          'district': u.district ?? 'Namangan viloyati',
          'type': name.contains('boshqarma')
              ? 'Davlat boshqaruv organi'
              : 'Ta’lim muassasasi',
          'studentsCount': 0,
          'specialistsCount': 0,
          'activeIepCount': 0,
        };
      }
      map[name]!['specialistsCount'] = (map[name]!['specialistsCount'] as int) + 1;
      if (u.district != null && u.district!.isNotEmpty) {
        map[name]!['district'] = u.district!;
      }
    }

    for (final iep in _iepPlans) {
      final name = iep.institutionName.trim();
      if (map.containsKey(name) && iep.status == 'Faol') {
        map[name]!['activeIepCount'] = (map[name]!['activeIepCount'] as int) + 1;
      }
    }

    // 2. Namangan viloyatining namunaviy bazasidagi maktablarni qo'shish (agar bo'sh bo'lsa)
    for (final district in NamanganData.districts) {
      final schools = NamanganData.getSchoolsForDistrict(district);
      for (final sch in schools.take(4)) {
        if (!map.containsKey(sch)) {
          map[sch] = {
            'name': sch,
            'district': district,
            'type': sch.contains('internat')
                ? 'Ixtisoslashtirilgan maktab-internati'
                : sch.contains('inklyuziv')
                    ? 'Inklyuziv tayanch maktab'
                    : 'Umumiy o‘rta ta’lim maktabi',
            'studentsCount': 0,
            'specialistsCount': 0,
            'activeIepCount': 0,
          };
        }
      }
    }

    final list = map.values.toList();
    list.sort((a, b) {
      final sComp = (b['studentsCount'] as int).compareTo(a['studentsCount'] as int);
      if (sComp != 0) return sComp;
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    return list;
  }

  List<Map<String, dynamic>> getClassesSummary() {
    final Map<String, Map<String, dynamic>> map = {};

    for (final s in _students) {
      final grade = s.grade.trim();
      if (grade.isEmpty) continue;
      final key = '${s.institutionName}_$grade';

      if (!map.containsKey(key)) {
        // Sinf rahbarini topish
        String teacherName = 'Biriktirilmagan';
        for (final u in _users) {
          if (u.role == UserRole.teacher &&
              u.institutionName == s.institutionName) {
            teacherName = u.fullName;
            break;
          }
        }

        map[key] = {
          'key': key,
          'grade': grade,
          'institutionName': s.institutionName,
          'studentsCount': 0,
          'needs': <String>{},
          'teacherName': teacherName,
          'specialistsCount': s.assignedSpecialistIds.length,
        };
      }

      map[key]!['studentsCount'] = (map[key]!['studentsCount'] as int) + 1;
      (map[key]!['needs'] as Set<String>).add(s.primaryNeed);
    }

    final list = map.values.toList();
    list.sort((a, b) => (a['grade'] as String).compareTo(b['grade'] as String));
    return list;
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
      if (!includeArchived &&
          s.status == 'Arxivlangan' &&
          status != 'Arxivlangan') {
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
      if (status != null && status.isNotEmpty && s.status != status) {
        return false;
      }
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

  Future<void> addStudent(
    StudentModel student, {
    required UserModel byUser,
  }) async {
    _require(
      _accessControl.canEditStudent(byUser, student),
      'o‘quvchini faqat muassasa rahbari yoki koordinator ro‘yxatga oladi (o‘z maktabiga).',
    );
    if (_students.any((s) => s.id == student.id)) {
      throw const ValidationException('Bunday o‘quvchi allaqachon mavjud.');
    }
    if (student.firstName.trim().isEmpty || student.lastName.trim().isEmpty) {
      throw const ValidationException('O‘quvchining ismi va familiyasini kiriting.');
    }
    _students.insert(0, student);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'Student',
      details:
          '${student.fullName} (${student.grade}, ${student.institutionName}) bazaga qo‘shildi',
    );
  }

  /// O'quvchi anketasini tahrirlash. Biriktirishlar va rivojlanish profili bu yerda
  /// o'zgarmaydi — ular uchun alohida metodlar bor (eskirgan nusxa ustidan yozilmasin).
  Future<void> updateStudent(
    StudentModel updated, {
    required UserModel byUser,
  }) async {
    final index = _students.indexWhere((s) => s.id == updated.id);
    if (index == -1) throw const NotFoundException('O‘quvchi topilmadi.');
    final current = _students[index];
    _require(
      _accessControl.canEditStudent(byUser, current) &&
          _accessControl.canEditStudent(byUser, updated),
      'o‘quvchi anketasini faqat muassasa rahbari yoki koordinator tahrirlaydi.',
    );
    _students[index] = updated.copyWith(
      assignedSpecialistIds: current.assignedSpecialistIds,
      accessProfile: current.accessProfile,
      domainLevels: current.domainLevels,
    );
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'Student',
      details: '${updated.fullName} anketasi tahrirlandi',
    );
  }

  Future<void> deactivateStudent(
    String studentId,
    String reason, {
    required UserModel byUser,
  }) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) throw const NotFoundException('O‘quvchi topilmadi.');
    final cur = _students[index];
    _require(
      _accessControl.canArchiveStudent(byUser, cur),
      'o‘quvchini faqat muassasa rahbari arxivlay oladi.',
    );
    if (reason.trim().isEmpty) {
      throw const ValidationException('Arxivlash sababini kiriting.');
    }
    _students[index] = cur.copyWith(
      status: 'Arxivlangan',
      deactivationReason: reason,
      deactivatedAt: DateTime.now(),
    );
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'ARCHIVE',
      entity: 'Student',
      details: '${cur.fullName} arxivlandi. Sabab: $reason',
    );
  }

  /// Bolaga mutaxassis biriktirish (koordinator yoki muassasa rahbari)
  Future<void> assignSpecialistToStudent(
    String studentId,
    String specialistId, {
    required UserModel byUser,
  }) async {
    final student = _studentOrThrow(studentId);
    final specialist = getUserById(specialistId);
    if (specialist == null) {
      throw const NotFoundException('Mutaxassis topilmadi.');
    }
    _require(
      _accessControl.canAssignSpecialists(byUser, student),
      'mutaxassisni faqat koordinator yoki muassasa rahbari biriktiradi.',
    );
    if (!_accessControl.canBeAssigned(specialist, student)) {
      throw const ValidationException(
        'Bu foydalanuvchini biriktirib bo‘lmaydi: u faol, bolalar bilan ishlaydigan va shu maktab xodimi bo‘lishi kerak.',
      );
    }
    await _assign(student, specialist, actor: byUser);
  }

  /// Biriktirishni bekor qilish (koordinator yoki muassasa rahbari)
  Future<void> unassignSpecialistFromStudent(
    String studentId,
    String specialistId, {
    required UserModel byUser,
    String? reason,
  }) async {
    final student = _studentOrThrow(studentId);
    _require(
      _accessControl.canAssignSpecialists(byUser, student),
      'biriktirishni faqat koordinator yoki muassasa rahbari bekor qiladi.',
    );
    final sIndex = _students.indexWhere((s) => s.id == studentId);
    _students[sIndex] = student.copyWith(
      assignedSpecialistIds: student.assignedSpecialistIds
          .where((id) => id != specialistId)
          .toList(),
    );
    final uIndex = _users.indexWhere((u) => u.id == specialistId);
    if (uIndex != -1) {
      final u = _users[uIndex];
      _users[uIndex] = u.copyWith(
        assignedStudentIds: u.assignedStudentIds
            .where((id) => id != studentId)
            .toList(),
      );
    }
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'PERMISSION_CHANGE',
      entity: 'Assignment',
      details:
          '${student.fullName}dan mutaxassis biriktirishi bekor qilindi${reason != null ? '. Sabab: $reason' : ''}',
    );
  }

  /// Biriktirish (ruxsat tekshirilgandan keyin chaqiriladi). Takroriy chaqiruv xavfsiz.
  Future<void> _assign(
    StudentModel student,
    UserModel specialist, {
    required UserModel actor,
  }) async {
    final already =
        student.assignedSpecialistIds.contains(specialist.id) &&
        specialist.assignedStudentIds.contains(student.id);
    if (already) return;

    final sIndex = _students.indexWhere((s) => s.id == student.id);
    final uIndex = _users.indexWhere((u) => u.id == specialist.id);
    _students[sIndex] = student.copyWith(
      assignedSpecialistIds: {
        ...student.assignedSpecialistIds,
        specialist.id,
      }.toList(),
    );
    if (uIndex != -1) {
      final u = _users[uIndex];
      _users[uIndex] = u.copyWith(
        assignedStudentIds: {...u.assignedStudentIds, student.id}.toList(),
      );
    }
    if (actor.id != specialist.id) {
      _notifications.insert(
        0,
        NotificationModel(
          id: 'notif_${_uuid.v4().substring(0, 8)}',
          recipientUserId: specialist.id,
          title: 'Yangi o‘quvchi biriktirildi',
          body: '${student.fullName} sizning nazoratingizga biriktirildi.',
          type: 'ASSIGNMENT',
          relatedRecordId: student.id,
          relatedStudentId: student.id,
          relatedStudentName: student.fullName,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _persistAll();
    await addAuditLog(
      userFullName: actor.fullName,
      userRole: actor.role.label,
      action: 'PERMISSION_CHANGE',
      entity: 'Assignment',
      details:
          '${specialist.fullName} ${student.fullName}ga mutaxassis sifatida biriktirildi',
    );
  }

  // ==================== RIVOJLANISH PROFILI ====================
  /// Bolaning imkoniyatlar profilini saqlash (psixolog to'ldiradi)
  Future<StudentModel> updateAccessProfile(
    String studentId,
    StudentAccessProfile profile, {
    required UserModel byUser,
  }) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) throw NotFoundException('O‘quvchi topilmadi.');
    final student = _students[index];
    if (!_accessControl.canEditDevelopmentProfile(byUser, student)) {
      throw PermissionDeniedException(
        'imkoniyatlar profilini faqat bolani baholovchi mutaxassis o‘zgartira oladi.',
      );
    }
    final updated = student.copyWith(
      accessProfile: profile.copyWith(
        updatedAt: DateTime.now(),
        updatedById: byUser.id,
      ),
    );
    _students[index] = updated;
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'StudentAccessProfile',
      details: '${student.fullName} imkoniyatlar profili yangilandi',
    );
    return updated;
  }

  /// Yo'nalish bo'yicha ishchi sinfni belgilash. [workingGrade] = null — bola yana
  /// o'z sinfi savollarini oladi (odatiy holat).
  Future<StudentModel> setDomainLevel(
    String studentId,
    String domain,
    int? workingGrade, {
    String? note,
    required UserModel byUser,
  }) async {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index == -1) throw NotFoundException('O‘quvchi topilmadi.');
    final student = _students[index];
    if (!_accessControl.canEditDevelopmentProfile(byUser, student)) {
      throw PermissionDeniedException(
        'darajani faqat bolani baholovchi mutaxassis belgilay oladi.',
      );
    }
    final levels = Map<String, DomainLevel>.from(student.domainLevels);
    final previous = levels[domain];
    if (workingGrade == null) {
      levels.remove(domain);
    } else {
      levels[domain] = DomainLevel(
        domain: domain,
        workingGrade: workingGrade.clamp(
          GradeBand.lowestGrade,
          GradeBand.highestGrade,
        ),
        setAt: DateTime.now(),
        setById: byUser.id,
        note: note,
      );
    }
    final updated = student.copyWith(domainLevels: levels);
    _students[index] = updated;
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'DomainLevel',
      details:
          '${student.fullName}: "$domain" ishchi sinfi ${previous != null ? GradeBand.gradeLabel(previous.workingGrade) : 'o‘z sinfi'} → ${workingGrade != null ? GradeBand.gradeLabel(workingGrade) : 'o‘z sinfi'}',
    );
    return updated;
  }

  // ==================== SHAXSIY BAHOLASH TO'PLAMLARI ====================
  List<AssessmentPlanModel> getAssessmentPlans({
    required UserModel forUser,
    required String studentId,
    String? domain,
    bool onlyActive = false,
  }) {
    final student = getStudentById(studentId);
    if (student == null || !_accessControl.canViewStudent(forUser, student)) {
      return [];
    }
    return _plans.where((p) {
      if (p.studentId != studentId) return false;
      if (domain != null && p.domain != domain) return false;
      if (onlyActive && !p.isActive) return false;
      return true;
    }).toList();
  }

  AssessmentPlanModel? getActivePlan({
    required UserModel forUser,
    required String studentId,
    required String domain,
  }) {
    final plans = getAssessmentPlans(
      forUser: forUser,
      studentId: studentId,
      domain: domain,
      onlyActive: true,
    );
    return plans.isEmpty ? null : plans.first;
  }

  /// Yangi shaxsiy to'plamni saqlash. Shu bola va yo'nalish uchun avvalgi faol to'plam
  /// faolsizlantiriladi (o'chirilmaydi — tarix uchun saqlanadi).
  Future<AssessmentPlanModel> saveAssessmentPlan(
    AssessmentPlanModel plan, {
    required UserModel byUser,
  }) async {
    final student = getStudentById(plan.studentId);
    if (student == null) throw NotFoundException('O‘quvchi topilmadi.');
    if (!_accessControl.canCreateAssessment(byUser, student)) {
      throw PermissionDeniedException(
        'bu o‘quvchi uchun baholash to‘plamini yaratish huquqi yo‘q.',
      );
    }
    if (plan.questionIds.isEmpty) {
      throw ValidationException('To‘plamda kamida bitta savol bo‘lishi kerak.');
    }
    for (var i = 0; i < _plans.length; i++) {
      final p = _plans[i];
      if (p.isActive &&
          p.studentId == plan.studentId &&
          p.domain == plan.domain &&
          p.id != plan.id) {
        _plans[i] = p.copyWith(isActive: false, replacedByPlanId: plan.id);
      }
    }
    final saved = AssessmentPlanModel(
      id: plan.id,
      studentId: plan.studentId,
      domain: plan.domain,
      workingGrade: plan.workingGrade,
      questionIds: plan.questionIds,
      createdById: byUser.id,
      createdByName: byUser.fullName,
      createdAt: DateTime.now(),
      note: plan.note,
    );
    _plans.removeWhere((p) => p.id == plan.id);
    _plans.insert(0, saved);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'AssessmentPlan',
      details:
          '${student.fullName}: "${plan.domain}" uchun shaxsiy to‘plam (${plan.questionIds.length} ta savol, ${GradeBand.gradeLabel(plan.workingGrade)} darajasi)',
    );
    return saved;
  }

  // ==================== DTS TALABLARI VA FAN BO'YICHA DARAJA ====================
  List<CurriculumStandard> getCurriculumStandards({String? subject, int? grade}) {
    return _curriculum.where((s) {
      if (subject != null && s.subject != subject) return false;
      if (grade != null && s.grade != grade) return false;
      return true;
    }).toList()..sort((a, b) {
      final g = a.grade.compareTo(b.grade);
      return g != 0 ? g : a.id.compareTo(b.id);
    });
  }

  /// Fanlar ro'yxati (talablar mavjud bo'lganlar)
  List<String> getCurriculumSubjects() =>
      _curriculum.map((s) => s.subject).toSet().toList()..sort();

  /// Rasmiy DTS talablarini yuklash (faqat tizim administratori).
  /// Yuklangan fanlar bo'yicha namunaviy (rasmiy bo'lmagan) talablar o'chiriladi.
  Future<int> importCurriculumStandards(
    List<CurriculumStandard> standards, {
    required UserModel byUser,
  }) async {
    if (!_accessControl.canManageSystemSettings(byUser)) {
      throw PermissionDeniedException(
        'DTS talablarini faqat tizim administratori yuklay oladi.',
      );
    }
    final subjects = standards.map((s) => s.subject).toSet();
    _curriculum.removeWhere(
      (s) => subjects.contains(s.subject) && !s.isOfficial,
    );
    for (final s in standards) {
      _curriculum.removeWhere((c) => c.id == s.id);
      _curriculum.add(s);
    }
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'IMPORT',
      entity: 'CurriculumStandard',
      details:
          '${standards.length} ta DTS talabi yuklandi (${subjects.join(', ')})',
    );
    return standards.length;
  }

  /// Namunaviy talablarni qo'shish — faqat rasmiy talablari yuklanmagan fanlar uchun
  Future<void> _syncCurriculumSeed() async {
    if (_corruptedKeys.contains('db_curriculum')) return;
    final officialSubjects = _curriculum
        .where((s) => s.isOfficial)
        .map((s) => s.subject)
        .toSet();
    final existing = _curriculum.map((s) => s.id).toSet();
    var changed = false;
    for (final s in CurriculumStandardsSeed.standards) {
      if (officialSubjects.contains(s.subject) || existing.contains(s.id)) {
        continue;
      }
      _curriculum.add(s);
      changed = true;
    }
    if (changed) await _persistAll();
  }

  /// Fan bo'yicha bilim darajasini saqlash. Tizim darajani tavsiya qiladi
  /// ([suggestedGrade]); [confirmedGrade] berilmasa, tavsiya qilingan daraja olinadi.
  Future<SubjectLevelAssessment> saveSubjectLevel({
    required String studentId,
    required String subject,
    required Map<String, Mastery> results,
    int? confirmedGrade,
    String? notes,
    required UserModel byUser,
  }) async {
    final student = getStudentById(studentId);
    if (student == null) throw NotFoundException('O‘quvchi topilmadi.');
    if (!_accessControl.canAssessSubjectLevel(byUser, student)) {
      throw PermissionDeniedException(
        'bilim darajasini maxsus ta’lim o‘qituvchisi yoki sinf o‘qituvchisi baholaydi.',
      );
    }
    final standards = getCurriculumStandards(subject: subject);
    final known = standards.map((s) => s.id).toSet();
    final cleanResults = {
      for (final e in results.entries)
        if (known.contains(e.key)) e.key: e.value,
    };
    if (cleanResults.isEmpty && confirmedGrade == null) {
      throw ValidationException('Kamida bitta talab bo‘yicha natija kiriting.');
    }
    final suggested = _subjectLevels.suggestGrade(cleanResults, standards);
    final classGrade =
        GradeBand.parseGrade(student.grade) ??
        (student.age - 6).clamp(GradeBand.lowestGrade, GradeBand.highestGrade);
    final assessment = SubjectLevelAssessment(
      id: 'sla_${_uuid.v4().substring(0, 8)}',
      studentId: studentId,
      subject: subject,
      classGrade: classGrade,
      results: cleanResults,
      suggestedGrade: suggested,
      confirmedGrade: (confirmedGrade ?? suggested ?? 0).clamp(
        GradeBand.lowestGrade,
        GradeBand.highestGrade,
      ),
      assessedById: byUser.id,
      assessedByName: byUser.fullName,
      assessedAt: DateTime.now(),
      notes: notes,
    );
    _subjectLevelRecords.insert(0, assessment);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'SubjectLevel',
      details: _subjectLevels.describe(assessment),
    );
    return assessment;
  }

  /// Bolaning fan bo'yicha baholashlari (eskidan yangiga)
  List<SubjectLevelAssessment> getSubjectLevels({
    required UserModel forUser,
    required String studentId,
    String? subject,
  }) {
    final student = getStudentById(studentId);
    if (student == null || !_accessControl.canViewStudent(forUser, student)) {
      return [];
    }
    return _subjectLevelRecords
        .where((a) => a.studentId == studentId)
        .where((a) => subject == null || a.subject == subject)
        .toList()
      ..sort((a, b) => a.assessedAt.compareTo(b.assessedAt));
  }

  SubjectLevelAssessment? latestSubjectLevel({
    required UserModel forUser,
    required String studentId,
    required String subject,
  }) {
    final list = getSubjectLevels(
      forUser: forUser,
      studentId: studentId,
      subject: subject,
    );
    return list.isEmpty ? null : list.last;
  }

  // ==================== FAN TOPSHIRIQLARI VA O'QUV NATIJALARI ====================
  Future<SubjectTask> assignSubjectTask(
    SubjectTask task, {
    required UserModel byUser,
  }) async {
    final student = getStudentById(task.studentId);
    if (student == null) throw NotFoundException('O‘quvchi topilmadi.');
    if (!_accessControl.canAssessSubjectLevel(byUser, student)) {
      throw PermissionDeniedException(
        'fan topshiriqlarini maxsus ta’lim o‘qituvchisi yoki sinf o‘qituvchisi beradi.',
      );
    }
    if (task.title.trim().isEmpty) {
      throw ValidationException('Topshiriq nomini kiriting.');
    }
    final saved = SubjectTask(
      id: task.id,
      studentId: task.studentId,
      subject: task.subject,
      levelGrade: task.levelGrade,
      standardId: task.standardId,
      title: task.title.trim(),
      description: task.description,
      assignedById: byUser.id,
      assignedByName: byUser.fullName,
      assignedAt: DateTime.now(),
      dueDate: task.dueDate,
    );
    _subjectTasks.removeWhere((t) => t.id == saved.id);
    _subjectTasks.add(saved);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'SubjectTask',
      details:
          '${student.fullName}: ${task.subject} topshirig‘i (${task.levelGrade}-sinf darajasi): ${saved.title}',
    );
    return saved;
  }

  /// Topshiriq natijasini qayd etish (o'quv natijasi)
  Future<SubjectTask> completeSubjectTask(
    String taskId,
    Mastery result, {
    String? note,
    required UserModel byUser,
  }) async {
    final index = _subjectTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) throw NotFoundException('Topshiriq topilmadi.');
    final task = _subjectTasks[index];
    final student = getStudentById(task.studentId);
    if (student == null ||
        !_accessControl.canAssessSubjectLevel(byUser, student)) {
      throw PermissionDeniedException(
        'natijani kiritish huquqi yo‘q.');
    }
    final done = task.complete(result, note: note);
    _subjectTasks[index] = done;
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'SubjectTask',
      details: '${student.fullName}: "${task.title}" — ${result.label}',
    );
    return done;
  }

  List<SubjectTask> getSubjectTasks({
    required UserModel forUser,
    required String studentId,
    String? subject,
    bool onlyOpen = false,
  }) {
    final student = getStudentById(studentId);
    if (student == null || !_accessControl.canViewStudent(forUser, student)) {
      return [];
    }
    return _subjectTasks
        .where((t) => t.studentId == studentId)
        .where((t) => subject == null || t.subject == subject)
        .where((t) => !onlyOpen || !t.isCompleted)
        .toList()
      ..sort((a, b) => a.assignedAt.compareTo(b.assignedAt));
  }

  // ==================== O'LCHOVLAR (BIRLIKLI NATIJALAR) ====================
  /// Standart va foydalanuvchi qo'shgan ko'rsatkichlar
  List<ProgressMetric> getProgressMetrics() => [
    ...ProgressMetrics.all,
    ..._customMetrics,
  ];

  ProgressMetric? getProgressMetric(String id) {
    for (final m in getProgressMetrics()) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<ProgressMetric> addCustomMetric(
    ProgressMetric metric, {
    required UserModel byUser,
  }) async {
    if (!byUser.isActive || !byUser.role.canCreateAssessments) {
      throw PermissionDeniedException(
        'ko‘rsatkich qo‘shish huquqi yo‘q.');
    }
    if (metric.name.trim().isEmpty || metric.unit.trim().isEmpty) {
      throw ValidationException('Ko‘rsatkich nomi va o‘lchov birligini kiriting.');
    }
    if (getProgressMetric(metric.id) != null) {
      throw ValidationException('Bunday ko‘rsatkich allaqachon mavjud.');
    }
    _customMetrics.add(metric);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'ProgressMetric',
      details: 'Yangi ko‘rsatkich: ${metric.name} (${metric.unit})',
    );
    return metric;
  }

  Future<ProgressMeasurement> addMeasurement(
    ProgressMeasurement measurement, {
    required UserModel byUser,
  }) async {
    final student = getStudentById(measurement.studentId);
    if (student == null) throw NotFoundException('O‘quvchi topilmadi.');
    if (!_accessControl.canCreateAssessment(byUser, student)) {
      throw PermissionDeniedException(
        'bu o‘quvchi uchun natija kiritish huquqi yo‘q.',
      );
    }
    final metric = getProgressMetric(measurement.metricId);
    if (metric == null) throw NotFoundException('Ko‘rsatkich topilmadi.');
    if (measurement.value.isNaN || measurement.value < 0) {
      throw ValidationException('Qiymat manfiy bo‘lmagan son bo‘lishi kerak.');
    }
    final saved = ProgressMeasurement(
      id: measurement.id,
      studentId: measurement.studentId,
      metricId: measurement.metricId,
      value: measurement.value,
      measuredAt: measurement.measuredAt,
      recordedById: byUser.id,
      recordedByName: byUser.fullName,
      note: measurement.note,
      iepObjectiveId: measurement.iepObjectiveId,
    );
    _measurements.removeWhere((m) => m.id == saved.id);
    _measurements.add(saved);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'ProgressMeasurement',
      details:
          '${student.fullName}: ${metric.name} — ${saved.value} ${metric.unit}',
    );
    return saved;
  }

  /// Bolaning o'lchovlari (eskidan yangiga)
  List<ProgressMeasurement> getMeasurements({
    required UserModel forUser,
    required String studentId,
    String? metricId,
  }) {
    final student = getStudentById(studentId);
    if (student == null || !_accessControl.canViewStudent(forUser, student)) {
      return [];
    }
    return _measurements
        .where((m) => m.studentId == studentId)
        .where((m) => metricId == null || m.metricId == metricId)
        .toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
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
        // Bolasi topilmagan (yetim) yozuvlar ham yashiriladi
        if (student == null ||
            !_accessControl.canViewStudent(forUser, student)) {
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

  Future<void> addAssessment(
    AssessmentModel assessment, {
    required UserModel byUser,
  }) async {
    final student = _studentOrThrow(assessment.studentId);
    _require(
      _accessControl.canCreateAssessment(byUser, student),
      'bu o‘quvchi sizga biriktirilmagan yoki baholash huquqingiz yo‘q.',
    );
    _require(
      assessment.specialistId == byUser.id ||
          byUser.role == UserRole.superAdmin,
      'baholashni faqat o‘z nomingizdan kiritishingiz mumkin.',
    );
    _assessments.insert(0, assessment);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'Assessment',
      details:
          '${assessment.studentName} uchun ${assessment.category} baholash: ${assessment.title} (${assessment.totalScore}/${assessment.maxScore} ball)',
    );
  }

  Future<void> updateAssessment(
    AssessmentModel updated, {
    required UserModel byUser,
  }) async {
    final index = _assessments.indexWhere((a) => a.id == updated.id);
    if (index == -1) throw const NotFoundException('Baholash topilmadi.');
    final current = _assessments[index];
    _require(
      _accessControl.canModifyAssessment(byUser, current),
      'baholashni faqat uni o‘tkazgan mutaxassis yoki rahbariyat o‘zgartiradi.',
    );
    if (updated.studentId != current.studentId) {
      throw const ValidationException(
        'Baholashni boshqa o‘quvchiga ko‘chirib bo‘lmaydi.',
      );
    }
    _assessments[index] = updated.copyWith(updatedAt: DateTime.now());
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'Assessment',
      details:
          '${updated.studentName} uchun ${updated.title} baholash yangilandi (Holati: ${updated.status})',
    );
  }

  Future<void> deleteAssessment(
    String id, {
    required UserModel byUser,
  }) async {
    final index = _assessments.indexWhere((a) => a.id == id);
    if (index == -1) throw const NotFoundException('Baholash topilmadi.');
    final target = _assessments[index];
    _require(
      _accessControl.canModifyAssessment(byUser, target),
      'baholashni faqat uni o‘tkazgan mutaxassis yoki rahbariyat o‘chiradi.',
    );
    _assessments.removeAt(index);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'DELETE',
      entity: 'Assessment',
      details: '${target.studentName} uchun ${target.title} baholash o‘chirildi',
    );
  }

  // ==================== SAVOLLAR KUTUBXONASI (QUESTION LIBRARY) ====================
  List<AssessmentQuestionModel> getQuestions({
    UserModel? forUser,
    String? domain,
    String? query,
    bool? myQuestionsOnly,
    String? status,
    String? questionType,
  }) {
    return _questions.where((q) {
      if (domain != null && domain != 'Barchasi' && q.domain != domain) {
        return false;
      }
      if (status != null && status != 'Barchasi' && q.status != status) {
        return false;
      }
      if (questionType != null &&
          questionType != 'Barchasi' &&
          q.questionType != questionType) {
        return false;
      }
      if (myQuestionsOnly == true && forUser != null) {
        if (q.authorId != forUser.id) return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final qLower = query.toLowerCase().trim();
        final textMatches = q.text.toLowerCase().contains(qLower);
        final titleMatches = q.title?.toLowerCase().contains(qLower) ?? false;
        final domainMatches = q.domain.toLowerCase().contains(qLower);
        if (!textMatches && !titleMatches && !domainMatches) return false;
      }
      return true;
    }).toList();
  }

  AssessmentQuestionModel? getQuestionById(String id) {
    try {
      return _questions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addQuestion(
    AssessmentQuestionModel question, {
    required UserModel byUser,
  }) async {
    _require(
      _accessControl.canCreateQuestion(byUser),
      'savol qo‘shish huquqi yo‘q.',
    );
    if (question.text.trim().isEmpty) {
      throw const ValidationException('Savol matnini kiriting.');
    }
    if (_questions.any((q) => q.id == question.id)) {
      throw const ValidationException('Bunday savol allaqachon mavjud.');
    }
    // Foydalanuvchi qo'shgan savol standart bo'la olmaydi
    final saved = byUser.role == UserRole.superAdmin
        ? question
        : question.copyWith(isStandard: false);
    _questions.insert(0, saved);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'Question',
      details:
          'Kutubxonaga yangi savol qo‘shildi: "${question.text.length > 50 ? "${question.text.substring(0, 50)}..." : question.text}" (${question.domain})',
    );
  }

  Future<void> updateQuestion(
    AssessmentQuestionModel question, {
    required UserModel byUser,
  }) async {
    final index = _questions.indexWhere((q) => q.id == question.id);
    if (index == -1) throw const NotFoundException('Savol topilmadi.');
    final current = _questions[index];
    _require(
      _accessControl.canModifyQuestion(byUser, current),
      'standart savollarni faqat tizim administratori, boshqalarini — muallif o‘zgartiradi.',
    );
    _questions[index] = question.copyWith(
      updatedAt: DateTime.now(),
      isStandard: current.isStandard,
      authorId: current.authorId,
    );
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'Question',
      details: 'Savol tahrirlandi: ${question.id} (${question.domain})',
    );
  }

  Future<void> deleteQuestion(
    String questionId, {
    required UserModel byUser,
  }) async {
    final index = _questions.indexWhere((q) => q.id == questionId);
    if (index == -1) throw const NotFoundException('Savol topilmadi.');
    final target = _questions[index];
    _require(
      _accessControl.canModifyQuestion(byUser, target),
      'standart savollarni faqat tizim administratori, boshqalarini — muallif o‘chiradi.',
    );
    _questions.removeAt(index);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'DELETE',
      entity: 'Question',
      details:
          'Kutubxonadan savol o‘chirildi: ${target.text.length > 40 ? "${target.text.substring(0, 40)}..." : target.text}',
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
        // Bolasi topilmagan (yetim) yozuvlar ham yashiriladi
        if (student == null ||
            !_accessControl.canViewStudent(forUser, student)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<Map<String, dynamic>> addSession(
    SessionModel session, {
    required UserModel byUser,
  }) async {
    final student = _studentOrThrow(session.studentId);
    _require(
      _accessControl.canScheduleSession(byUser, student),
      'bu o‘quvchi sizga biriktirilmagan.',
    );
    final schedulesForOthers =
        byUser.role == UserRole.superAdmin ||
        AccessControlService.schoolWideRoles.contains(byUser.role);
    _require(
      session.specialistId == byUser.id || schedulesForOthers,
      'mashg‘ulotni faqat o‘zingiz uchun rejalashtira olasiz.',
    );

    // Takroriy seans: bir xil o'quvchi va mutaxassis uchun bir xil vaqt
    final duplicate = _sessions.any(
      (s) =>
          s.studentId == session.studentId &&
          s.specialistId == session.specialistId &&
          s.scheduledAt.year == session.scheduledAt.year &&
          s.scheduledAt.month == session.scheduledAt.month &&
          s.scheduledAt.day == session.scheduledAt.day &&
          s.scheduledAt.hour == session.scheduledAt.hour &&
          s.scheduledAt.minute == session.scheduledAt.minute,
    );
    if (duplicate) {
      return {
        'success': false,
        'message':
            'Ushbu vaqtda bu mutaxassis va o‘quvchi uchun allaqachon mashg‘ulot rejalashtirilgan.',
      };
    }

    _sessions.insert(0, session);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'Session',
      details:
          '${session.studentName} bilan ${session.topic} mashg‘uloti rejalashtirildi',
    );
    return {'success': true};
  }

  SessionModel _sessionForChange(String sessionId, UserModel byUser) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) throw const NotFoundException('Mashg‘ulot topilmadi.');
    final cur = _sessions[index];
    _require(
      _accessControl.canCompleteSession(byUser, cur),
      'mashg‘ulotni faqat mas’ul mutaxassis yoki rahbariyat o‘zgartiradi.',
    );
    return cur;
  }

  Future<void> completeSession(
    String sessionId, {
    required String observations,
    String? nextSteps,
    required UserModel byUser,
  }) async {
    final cur = _sessionForChange(sessionId, byUser);
    if (observations.trim().isEmpty) {
      throw const ValidationException(
        'Mashg‘ulotni yakunlash uchun kuzatuv natijasini yozing.',
      );
    }
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    _sessions[index] = cur.copyWith(
      status: 'Bajarildi',
      attendanceConfirmed: true,
      observations: observations,
      nextSteps: nextSteps ?? cur.nextSteps,
    );
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'Session',
      details:
          '${cur.studentName} bilan ${cur.topic} mashg‘uloti bajarilgan deb tasdiqlandi',
    );
  }

  static const sessionStatuses = {
    'Rejalashtirilgan',
    'Bajarildi',
    'Qatnashmadi',
    'Bekor qilindi',
  };

  Future<void> updateSessionStatus(
    String sessionId,
    String status, {
    String? notes,
    required UserModel byUser,
  }) async {
    final cur = _sessionForChange(sessionId, byUser);
    if (!sessionStatuses.contains(status)) {
      throw ValidationException('Noma’lum mashg‘ulot holati: $status');
    }
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    _sessions[index] = cur.copyWith(
      status: status,
      observations: notes ?? cur.observations,
      attendanceConfirmed: status == 'Bajarildi',
    );
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'Session',
      details: '${cur.studentName} bilan mashg‘ulot holati: $status ga o‘zgardi',
    );
  }

  Future<void> deleteSession(
    String sessionId, {
    required UserModel byUser,
  }) async {
    final cur = _sessionForChange(sessionId, byUser);
    _sessions.removeWhere((s) => s.id == sessionId);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'DELETE',
      entity: 'Session',
      details: '${cur.studentName} bilan ${cur.topic} mashg‘uloti o‘chirildi',
    );
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
        // Bolasi topilmagan (yetim) yozuvlar ham yashiriladi
        if (student == null ||
            !_accessControl.canViewStudent(forUser, student)) {
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

  Future<void> addIepPlan(
    IndividualEducationPlanModel plan, {
    required UserModel byUser,
  }) async {
    final student = _studentOrThrow(plan.studentId);
    _require(
      _accessControl.canManageIep(byUser, null) &&
          _accessControl.canViewStudent(byUser, student),
      'individual rejani koordinator, rahbariyat yoki bolaga biriktirilgan maxsus ta’lim o‘qituvchisi tuzadi.',
    );
    if (_iepPlans.any((p) => p.id == plan.id)) {
      throw const ValidationException('Bunday reja allaqachon mavjud.');
    }
    _iepPlans.insert(0, plan);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'IEP',
      details:
          '${plan.studentName} uchun ITR rejasi yaratildi (${plan.objectives.length} ta maqsad)',
    );
  }

  Future<void> updateIepPlan(
    IndividualEducationPlanModel plan, {
    required UserModel byUser,
  }) async {
    final index = _iepPlans.indexWhere((p) => p.id == plan.id);
    if (index == -1) throw const NotFoundException('Reja topilmadi.');
    final current = _iepPlans[index];
    _require(
      _accessControl.canManageIep(byUser, current),
      'rejani tahrirlash huquqi yo‘q.',
    );
    if (plan.studentId != current.studentId) {
      throw const ValidationException('Rejani boshqa o‘quvchiga ko‘chirib bo‘lmaydi.');
    }
    _iepPlans[index] = plan;
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'IEP',
      details: '${plan.studentName} ning ITR rejasi yangilandi',
    );
  }

  Future<void> updateObjectiveProgress(
    String iepId,
    String objectiveId,
    int progress, {
    String? evidenceNotes,
    required UserModel byUser,
  }) async {
    final pIndex = _iepPlans.indexWhere((p) => p.id == iepId);
    if (pIndex == -1) throw const NotFoundException('Reja topilmadi.');
    final plan = _iepPlans[pIndex];
    final objective = plan.objectives.where((o) => o.id == objectiveId);
    if (objective.isEmpty) throw const NotFoundException('Maqsad topilmadi.');
    _require(
      _accessControl.canUpdateObjectiveProgress(byUser, plan, objective.first),
      'bu maqsad bo‘yicha natija kiritish huquqi yo‘q.',
    );
    final value = progress.clamp(0, 100);
    final newObjectives = plan.objectives.map((obj) {
      if (obj.id != objectiveId) return obj;
      final newStatus = value >= 100
          ? 'Bajarildi'
          : value > 0
          ? 'Jarayonda'
          : 'Rejalashtirilgan';
      return obj.copyWith(
        progressPercent: value,
        status: newStatus,
        evidenceNotes: evidenceNotes ?? obj.evidenceNotes,
      );
    }).toList();

    _iepPlans[pIndex] = plan.copyWith(objectives: newObjectives);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'IEP_Objective',
      details:
          '${plan.studentName} ITR maqsadi bo‘yicha progress: $value% qilib belgilandi',
    );
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
        // Bolasi topilmagan (yetim) yozuvlar ham yashiriladi
        if (student == null ||
            !_accessControl.canViewStudent(forUser, student)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> resolveAlert(
    String alertId,
    String notes, {
    required UserModel byUser,
  }) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index == -1) throw const NotFoundException('Monitoring signali topilmadi.');
    final cur = _alerts[index];
    final student = _studentOrThrow(cur.studentId);
    _require(
      _accessControl.canResolveAlert(byUser, student),
      'bu signalni hal qilish huquqi yo‘q.',
    );
    if (notes.trim().isEmpty) {
      throw const ValidationException('Qanday chora ko‘rilganini yozing.');
    }
    _alerts[index] = cur.copyWith(
      isResolved: true,
      status: 'Hal qilindi',
      resolvedNotes: notes,
      resolvedAt: DateTime.now(),
    );
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'RESOLVE',
      entity: 'Alert',
      details: 'Monitoring signali (${cur.ruleTitle}) hal etildi: $notes',
    );
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

  static const referralStatuses = {
    'Qoralamada',
    'Yuborildi',
    'Qabul qilindi',
    'Jarayonda',
    'Yakunlandi',
    'Rad etildi',
  };

  Future<void> addReferral(
    ReferralModel referral, {
    required UserModel byUser,
  }) async {
    final student = _studentOrThrow(referral.studentId);
    _require(
      _accessControl.canCreateReferral(byUser) &&
          _accessControl.canViewStudent(byUser, student),
      'bu o‘quvchini yo‘naltirish huquqi yo‘q.',
    );
    if (referral.reason.trim().isEmpty) {
      throw const ValidationException('Yo‘naltirish sababini kiriting.');
    }
    final saved = referral.copyWith(
      fromSpecialistId: byUser.id,
      fromSpecialistName: byUser.fullName,
      fromSpecialistRole: byUser.role.label,
    );
    _referrals.insert(0, saved);

    // Aniq mutaxassisga yo'naltirilgan bo'lsa — unga bildirishnoma
    if (saved.toSpecialistId != null && saved.toSpecialistId!.isNotEmpty) {
      _notifications.insert(
        0,
        NotificationModel(
          id: 'notif_${_uuid.v4().substring(0, 8)}',
          recipientUserId: saved.toSpecialistId!,
          title: 'Yangi yo‘naltirish (${saved.priority})',
          body:
              '${saved.fromSpecialistName} ${saved.studentName}ni ko‘rikdan o‘tkazish uchun yo‘naltirdi.',
          type: 'REFERRAL',
          relatedRecordId: saved.id,
          relatedStudentId: saved.studentId,
          relatedStudentName: saved.studentName,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'Referral',
      details:
          '${saved.studentName} -> ${saved.toSpecialistType} xizmatiga yo‘naltirildi. Sabab: ${saved.reason}',
    );
  }

  /// Yo'naltirish holatini o'zgartirish. Qabul qiluvchi mutaxassis yo'naltirishni
  /// qabul qilganda u bolaga avtomatik biriktiriladi — shundan keyin bolaning
  /// ma'lumotlarini ko'ra va natija kirita oladi.
  Future<void> updateReferralStatus(
    String referralId,
    String newStatus, {
    String? outcomeNotes,
    String? followUpAction,
    DateTime? followUpDate,
    required UserModel byUser,
  }) async {
    final index = _referrals.indexWhere((r) => r.id == referralId);
    if (index == -1) throw const NotFoundException('Yo‘naltirish topilmadi.');
    final cur = _referrals[index];
    _require(
      _accessControl.canProcessReferral(byUser, cur),
      'bu yo‘naltirish bilan ishlash huquqi yo‘q.',
    );
    if (!referralStatuses.contains(newStatus)) {
      throw ValidationException('Noma’lum yo‘naltirish holati: $newStatus');
    }

    final isRecipient =
        cur.toSpecialistId == byUser.id ||
        cur.toSpecialistType == byUser.role.label;
    final accepting = newStatus == 'Qabul qilindi' || newStatus == 'Jarayonda';

    _referrals[index] = cur.copyWith(
      status: newStatus,
      outcomeNotes: outcomeNotes ?? cur.outcomeNotes,
      followUpAction: followUpAction ?? cur.followUpAction,
      followUpDate: followUpDate ?? cur.followUpDate,
      toSpecialistId: accepting && isRecipient ? byUser.id : cur.toSpecialistId,
      toSpecialistName: accepting && isRecipient
          ? byUser.fullName
          : cur.toSpecialistName,
      updatedAt: DateTime.now(),
    );

    if (accepting && isRecipient) {
      final student = getStudentById(cur.studentId);
      final me = getUserById(byUser.id) ?? byUser;
      if (student != null && _accessControl.canBeAssigned(me, student)) {
        await _assign(student, me, actor: byUser);
      }
    }

    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'UPDATE',
      entity: 'Referral',
      details:
          'Yo‘naltirish holati: $newStatus deb belgilandi (${cur.studentName})',
    );
  }

  // ==================== IN-APP NOTIFIKATSIYALAR ====================
  List<NotificationModel> getNotifications(String userId) {
    return _notifications.where((n) => n.recipientUserId == userId).toList();
  }

  int getUnreadNotificationCount(String userId) {
    return _notifications
        .where((n) => n.recipientUserId == userId && !n.isRead)
        .length;
  }

  /// Bildirishnomani o'qilgan deb belgilash — faqat qabul qiluvchi
  Future<void> markNotificationAsRead(
    String notificationId, {
    required UserModel byUser,
  }) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    _require(
      _notifications[index].recipientUserId == byUser.id,
      'boshqa foydalanuvchining bildirishnomasi.',
    );
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    await _persistAll();
  }

  Future<void> markAllNotificationsAsRead({required UserModel byUser}) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientUserId == byUser.id &&
          !_notifications[i].isRead) {
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
    // Faqat audit jadvali yoziladi — har bir amalda butun bazani qayta yozmaslik uchun
    final prefs = await SharedPreferences.getInstance();
    await _writeTable(prefs, 'db_audit', _auditLogs.map((e) => e.toJson()));
  }

  // ==================== PSIXOLOGIK KUZATUV JURNALI ====================
  List<PsychologicalObservationModel> getObservations({
    UserModel? forUser,
    String? studentId,
    String? category,
  }) {
    return _observations.where((o) {
      if (studentId != null && o.studentId != studentId) return false;
      if (category != null && o.category != category) return false;
      if (forUser != null) {
        final student = getStudentById(o.studentId);
        if (student == null ||
            !_accessControl.canViewStudent(forUser, student)) {
          return false;
        }
        if (o.isConfidential &&
            !_accessControl.canViewConfidentialObservation(
              forUser,
              o.psychologistId,
            )) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> addObservation(
    PsychologicalObservationModel observation, {
    required UserModel byUser,
  }) async {
    final student = _studentOrThrow(observation.studentId);
    _require(
      _accessControl.canWriteObservation(byUser, student),
      'psixologik kuzatuvni faqat bolaga biriktirilgan psixolog yozadi.',
    );
    _require(
      observation.psychologistId == byUser.id ||
          byUser.role == UserRole.superAdmin,
      'kuzatuvni faqat o‘z nomingizdan yozishingiz mumkin.',
    );
    if (observation.observationText.trim().isEmpty) {
      throw const ValidationException('Kuzatuv matnini kiriting.');
    }
    _observations.insert(0, observation);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'CREATE',
      entity: 'Observation',
      details:
          '${observation.studentName} uchun psixologik kuzatuv qayd etildi (${observation.category})',
    );
  }

  Future<void> deleteObservation(
    String id, {
    required UserModel byUser,
  }) async {
    final index = _observations.indexWhere((o) => o.id == id);
    if (index == -1) throw const NotFoundException('Kuzatuv topilmadi.');
    final obs = _observations[index];
    _require(
      obs.psychologistId == byUser.id || byUser.role == UserRole.superAdmin,
      'kuzatuvni faqat muallif o‘chiradi.',
    );
    _observations.removeAt(index);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser.fullName,
      userRole: byUser.role.label,
      action: 'DELETE',
      entity: 'Observation',
      details:
          '${obs.studentName} ning ${obs.category} bo‘yicha kuzatuvi o‘chirildi',
    );
  }
}
