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
import '../core/constants/psychological_questions_seed.dart';
import 'access_control_service.dart';
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

  bool _isInitialized = false;

  // O'qishda buzilgan deb topilgan jadvallar (ustidan yozilmaydi)
  final Set<String> _corruptedKeys = {};

  /// Testlar uchun: keyingi init() ma'lumotlarni qaytadan o'qishi uchun.
  @visibleForTesting
  void resetForTest() => _isInitialized = false;

  /// Ishga tushishda o'qib bo'lmagan jadvallar. Bo'sh bo'lmasa, foydalanuvchini ogohlantirish kerak.
  List<String> get loadErrors => List.unmodifiable(_corruptedKeys);

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool('app_db_seeded_v2') ?? false;

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
  }

  List<T> _decodeTable<T>(
    SharedPreferences prefs,
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    List<T> Function()? fallback,
  }) {
    final raw = prefs.getString(key);
    if (raw == null) return fallback?.call() ?? <T>[];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Asl ma'lumotni zaxiralash va jadvalni ustidan yozishdan himoyalash
      _corruptedKeys.add(key);
      prefs.setString('${key}_corrupt_backup', raw);
      debugPrint('LocalDbService: "$key" jadvalini o‘qib bo‘lmadi: $e');
      return <T>[];
    }
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

  // ==================== FOYDALANUVCHILAR VA XAVFSIZLIK ====================
  List<UserModel> getUsers({UserModel? forUser}) {
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

  Future<void> registerUser(UserModel user) async {
    user = _withHashedPassword(user);
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

  /// Administrator tomonidan yangi foydalanuvchi yaratish (Backend huquq tekshiruvi bilan)
  Future<void> addUser(UserModel user, {UserModel? byUser}) async {
    if (byUser != null && !_accessControl.canManageUsers(byUser)) {
      throw Exception(
        'Ruxsat cheklangan: Faqat administrator foydalanuvchi qo‘sha oladi.',
      );
    }

    if (findUserByEmailOrPhone(user.email) != null) {
      throw Exception('Ushbu elektron pochta manzili bilan foydalanuvchi mavjud.');
    }
    if (user.phone != null && user.phone!.isNotEmpty && findUserByEmailOrPhone(user.phone!) != null) {
      throw Exception('Ushbu telefon raqam bilan foydalanuvchi ro‘yxatdan o‘tgan.');
    }

    _users.insert(0, _withHashedPassword(user));
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? 'Administrator',
      userRole: byUser?.role.label ?? 'Tizim administratori',
      action: 'CREATE',
      entity: 'User',
      details:
          'Yangi foydalanuvchi yaratildi: ${user.fullName} (${user.role.label}, ${user.institutionName ?? 'Muassasa ko‘rsatilmagan'})',
    );
  }

  Future<void> updateUser(UserModel updated, {UserModel? byUser}) async {
    if (byUser != null && !_accessControl.canManageUsers(byUser) && byUser.id != updated.id) {
      throw Exception(
        'Ruxsat cheklangan: Boshqa foydalanuvchi ma’lumotlarini o‘zgartirish huquqi yo‘q.',
      );
    }

    final index = _users.indexWhere((u) => u.id == updated.id);
    if (index != -1) {
      _users[index] = _withHashedPassword(updated);
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? updated.fullName,
        userRole: byUser?.role.label ?? updated.role.label,
        action: 'UPDATE',
        entity: 'User',
        details:
            '${updated.fullName} (${updated.role.label}) ma’lumotlari tahrirlandi.',
      );
    }
  }

  Future<void> toggleUserActive(
    String userId,
    bool isActive, {
    UserModel? byUser,
  }) async {
    if (byUser != null && !_accessControl.canManageUsers(byUser)) {
      throw Exception(
        'Ruxsat cheklangan: Foydalanuvchi faolligini o‘zgartirish uchun administrator huquqi talab qilinadi.',
      );
    }

    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      // Super adminning o'zini bloklashidan himoya
      if (_users[index].role == UserRole.superAdmin && !isActive) {
        throw Exception('Asosiy tizim administratorini bloklash taqiqlanadi.');
      }

      _users[index] = _users[index].copyWith(isActive: isActive);
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Administrator',
        userRole: byUser?.role.label ?? 'Tizim administratori',
        action: 'PERMISSION_CHANGE',
        entity: 'User',
        details:
            '${_users[index].fullName} hisobi ${isActive ? 'faollashtirildi' : 'bloklandi'}.',
      );
    }
  }

  Future<void> deleteUser(String userId, {UserModel? byUser}) async {
    if (byUser != null && !_accessControl.canManageUsers(byUser)) {
      throw Exception(
        'Ruxsat cheklangan: Foydalanuvchini o‘chirish huquqi mavjud emas.',
      );
    }

    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final target = _users[index];
      if (target.role == UserRole.superAdmin) {
        throw Exception('Asosiy tizim administratorini o‘chirib bo‘lmaydi.');
      }

      _users.removeAt(index);
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Administrator',
        userRole: byUser?.role.label ?? 'Tizim administratori',
        action: 'DELETE',
        entity: 'User',
        details:
            'Foydalanuvchi tizimdan o‘chirildi: ${target.fullName} (${target.role.label})',
      );
    }
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

  Future<void> addStudent(StudentModel student, {UserModel? byUser}) async {
    _students.insert(0, student);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? 'Foydalanuvchi',
      userRole: byUser?.role.label ?? 'Xodim',
      action: 'CREATE',
      entity: 'Student',
      details:
          '${student.fullName} (${student.grade}, ${student.institutionName}) bazaga qo‘shildi',
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

  Future<void> deactivateStudent(
    String studentId,
    String reason, {
    UserModel? byUser,
  }) async {
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

  Future<void> assignSpecialistToStudent(
    String studentId,
    String specialistId, {
    UserModel? byUser,
  }) async {
    final sIndex = _students.indexWhere((s) => s.id == studentId);
    final uIndex = _users.indexWhere((u) => u.id == specialistId);
    if (sIndex != -1 && uIndex != -1) {
      final student = _students[sIndex];
      final specialist = _users[uIndex];

      final updatedSpecIds = List<String>.from(student.assignedSpecialistIds);
      if (!updatedSpecIds.contains(specialistId)) {
        updatedSpecIds.add(specialistId);
      }

      final updatedStudentIds = List<String>.from(
        specialist.assignedStudentIds,
      );
      if (!updatedStudentIds.contains(studentId)) {
        updatedStudentIds.add(studentId);
      }

      _students[sIndex] = student.copyWith(
        assignedSpecialistIds: updatedSpecIds,
      );
      _users[uIndex] = specialist.copyWith(
        assignedStudentIds: updatedStudentIds,
      );

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
        details:
            '${specialist.fullName} ${student.fullName}ga mutaxassis sifatida biriktirildi',
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
    UserModel? byUser,
  }) async {
    _assessments.insert(0, assessment);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? assessment.specialistName,
      userRole: byUser?.role.label ?? assessment.specialistRole,
      action: 'CREATE',
      entity: 'Assessment',
      details:
          '${assessment.studentName} uchun ${assessment.category} baholash: ${assessment.title} (${assessment.totalScore}/${assessment.maxScore} ball)',
    );
  }

  Future<void> updateAssessment(
    AssessmentModel updated, {
    UserModel? byUser,
  }) async {
    final index = _assessments.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _assessments[index] = updated.copyWith(updatedAt: DateTime.now());
      _reEvaluateRules();
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? updated.specialistName,
        userRole: byUser?.role.label ?? updated.specialistRole,
        action: 'UPDATE',
        entity: 'Assessment',
        details:
            '${updated.studentName} uchun ${updated.title} baholash yangilandi (Holati: ${updated.status})',
      );
    }
  }

  Future<void> deleteAssessment(
    String id, {
    UserModel? byUser,
  }) async {
    final index = _assessments.indexWhere((a) => a.id == id);
    if (index != -1) {
      final target = _assessments[index];
      _assessments.removeAt(index);
      _reEvaluateRules();
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? target.specialistName,
        userRole: byUser?.role.label ?? target.specialistRole,
        action: 'DELETE',
        entity: 'Assessment',
        details: '${target.studentName} uchun ${target.title} baholash o‘chirildi',
      );
    }
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
    UserModel? byUser,
  }) async {
    _questions.insert(0, question);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? question.authorName,
      userRole: byUser?.role.label ?? 'Amaliyotchi psixolog',
      action: 'CREATE',
      entity: 'Question',
      details:
          'Kutubxonaga yangi savol qo‘shildi: "${question.text.length > 50 ? "${question.text.substring(0, 50)}..." : question.text}" (${question.domain})',
    );
  }

  Future<void> updateQuestion(
    AssessmentQuestionModel question, {
    UserModel? byUser,
  }) async {
    final index = _questions.indexWhere((q) => q.id == question.id);
    if (index != -1) {
      _questions[index] = question.copyWith(updatedAt: DateTime.now());
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? question.authorName,
        userRole: byUser?.role.label ?? 'Amaliyotchi psixolog',
        action: 'UPDATE',
        entity: 'Question',
        details: 'Savol tahrirlandi: ${question.id} (${question.domain})',
      );
    }
  }

  Future<void> deleteQuestion(
    String questionId, {
    UserModel? byUser,
  }) async {
    final index = _questions.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      final target = _questions[index];
      _questions.removeAt(index);
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Mutaxassis',
        userRole: byUser?.role.label ?? 'Amaliyotchi psixolog',
        action: 'DELETE',
        entity: 'Question',
        details:
            'Kutubxonadan savol o‘chirildi: ${target.text.length > 40 ? "${target.text.substring(0, 40)}..." : target.text}',
      );
    }
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
    UserModel? byUser,
  }) async {
    // 1. Takroriy seans tekshiruvi (Bir xil o'quvchi va mutaxassis uchun bir xil vaqtda seans bormi?)
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
        'message': 'Ushbu vaqtda bu mutaxassis va o‘quvchi uchun allaqachon mashg‘ulot rejalashtirilgan.',
      };
    }

    _sessions.insert(0, session);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? session.specialistName,
      userRole: byUser?.role.label ?? session.specialistRole,
      action: 'CREATE',
      entity: 'Session',
      details:
          '${session.studentName} bilan ${session.topic} mashg‘uloti rejalashtirildi',
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
        details:
            '${cur.studentName} bilan ${cur.topic} mashg‘uloti bajarilgan deb tasdiqlandi',
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
        details:
            '${cur.studentName} bilan mashg‘ulot holati: $status ga o‘zgardi',
      );
    }
  }

  Future<void> deleteSession(String sessionId, {UserModel? byUser}) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final cur = _sessions[index];
      _sessions.removeAt(index);
      _reEvaluateRules();
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? cur.specialistName,
        userRole: byUser?.role.label ?? cur.specialistRole,
        action: 'DELETE',
        entity: 'Session',
        details: '${cur.studentName} bilan ${cur.topic} mashg‘uloti o‘chirildi',
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
    UserModel? byUser,
  }) async {
    _iepPlans.insert(0, plan);
    _reEvaluateRules();
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? plan.responsibleTeacherName,
      userRole: byUser?.role.label ?? 'Koordinator',
      action: 'CREATE',
      entity: 'IEP',
      details:
          '${plan.studentName} uchun ITR rejasi yaratildi (${plan.objectives.length} ta maqsad)',
    );
  }

  Future<void> updateIepPlan(
    IndividualEducationPlanModel plan, {
    UserModel? byUser,
  }) async {
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
        details:
            '${plan.studentName} ITR maqsadi bo‘yicha progress: $progress% qilib belgilandi',
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
    UserModel? byUser,
  }) async {
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
    if (referral.toSpecialistId != null &&
        referral.toSpecialistId!.isNotEmpty) {
      await createNotification(
        NotificationModel(
          id: 'notif_${_uuid.v4().substring(0, 8)}',
          recipientUserId: referral.toSpecialistId!,
          title: 'Yangi yo‘naltirish (${referral.priority})',
          body:
              '${referral.fromSpecialistName} ${referral.studentName}ni ko‘rikdan o‘tkazish uchun yo‘naltirdi.',
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
      details:
          '${referral.studentName} -> ${referral.toSpecialistType} xizmatiga yo‘naltirildi. Sabab: ${referral.reason}',
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
        details:
            'Yo‘naltirish holati: $newStatus deb belgilandi (${cur.studentName})',
      );
    }
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
      if (_notifications[i].recipientUserId == userId &&
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
    await _persistAll();
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
    UserModel? byUser,
  }) async {
    _observations.insert(0, observation);
    await _persistAll();
    await addAuditLog(
      userFullName: byUser?.fullName ?? observation.psychologistName,
      userRole: byUser?.role.label ?? 'Amaliyotchi psixolog',
      action: 'CREATE',
      entity: 'Observation',
      details:
          '${observation.studentName} uchun psixologik kuzatuv qayd etildi (${observation.category})',
    );
  }

  Future<void> deleteObservation(String id, {UserModel? byUser}) async {
    final index = _observations.indexWhere((o) => o.id == id);
    if (index != -1) {
      final obs = _observations.removeAt(index);
      await _persistAll();
      await addAuditLog(
        userFullName: byUser?.fullName ?? 'Psixolog',
        userRole: byUser?.role.label ?? 'Amaliyotchi psixolog',
        action: 'DELETE',
        entity: 'Observation',
        details:
            '${obs.studentName} ning ${obs.category} bo‘yicha kuzatuvi o‘chirildi',
      );
    }
  }
}
