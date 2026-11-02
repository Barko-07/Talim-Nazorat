import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../services/local_db_service.dart';
import '../services/app_exceptions.dart';
import '../services/auth_session.dart';
import '../services/login_guard.dart';
import '../services/password_hasher.dart';

class AuthProvider extends ChangeNotifier with WidgetsBindingObserver {
  final LocalDbService _db = LocalDbService();
  final LoginGuard _guard = LoginGuard();
  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  UserRole get currentRole => _currentUser?.role ?? UserRole.reviewer;

  Timer? _sessionTimer;

  AuthProvider() {
    WidgetsBinding.instance.addObserver(this);
    _checkSavedSession();
    // Ilova bitta ekranda ochiq qolib ketsa ham sessiya muddati nazorat qilinadi
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => validateSession(),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) validateSession();
  }

  /// Sessiyani tekshiradi: muddati tugagan, hisob bloklangan yoki roli o'zgargan bo'lsa —
  /// tizimdan chiqaradi (yangi huquqlar bilan qayta kirish talab qilinadi).
  Future<void> validateSession() async {
    final cached = _currentUser;
    if (cached == null) return;
    final prefs = await SharedPreferences.getInstance();
    final session = AuthSession.decode(prefs.getString(AuthSession.prefsKey));
    final fresh = _db.getUserById(cached.id);
    final valid = session != null &&
        session.isValid() &&
        session.userId == cached.id &&
        fresh != null &&
        fresh.isActive &&
        fresh.role == cached.role;
    if (!valid) await logout();
  }

  Future<void> _checkSavedSession() async {
    _isLoading = true;
    notifyListeners();

    await _db.init();
    _dummyHash.length; // soxta xeshni oldindan tayyorlash

    final prefs = await SharedPreferences.getInstance();
    // Eski versiyadagi muddatsiz sessiya kaliti bekor qilinadi — qayta kirish talab qilinadi
    await prefs.remove('auth_user_id');

    final session = AuthSession.decode(prefs.getString(AuthSession.prefsKey));
    final user = session == null ? null : _db.getUserById(session.userId);
    if (session != null && session.isValid() && user != null && user.isActive) {
      _currentUser = user;
      await prefs.setString(AuthSession.prefsKey, session.touched().encode());
    } else {
      await prefs.remove(AuthSession.prefsKey);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Foydalanuvchi faolligini qayd etadi (faolliksiz vaqt shu paytdan hisoblanadi).
  /// Sessiya muddati tugagan bo'lsa — tizimdan chiqariladi.
  Future<void> touchSession() async {
    if (_currentUser == null) return;
    await validateSession();
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final session = AuthSession.decode(prefs.getString(AuthSession.prefsKey))!;
    final now = DateTime.now();
    if (now.difference(session.lastActive) > const Duration(minutes: 1)) {
      await prefs.setString(AuthSession.prefsKey, session.touched(now: now).encode());
    }
  }

  /// Hisob mavjud emasligini ham noto'g'ri parol kabi tekshirish uchun soxta xesh
  /// (javob vaqti bo'yicha hisob borligini aniqlab bo'lmasin)
  static final String _dummyHash = PasswordHasher.hash('__no_such_account__');

  static const _invalidCredentials = 'Login yoki parol noto‘g‘ri.';

  Map<String, dynamic> _fail(String message) {
    _isLoading = false;
    notifyListeners();
    return {'success': false, 'message': message};
  }

  /// Telefon raqami yoki pochta orqali kirish.
  /// Xavfsizlik: hisob borligi oshkor qilinmaydi (bir xil xabar), ketma-ket noto'g'ri
  /// urinishlar loginni vaqtincha bloklaydi, shubhali urinishlar jurnalga yoziladi.
  Future<Map<String, dynamic>> login(
    String identifier,
    String password, {
    UserRole? requiredRole,
  }) async {
    _isLoading = true;
    notifyListeners();

    final id = identifier.trim();
    if (id.isEmpty) {
      return _fail('Telefon raqamingiz yoki elektron pochtangizni kiriting.');
    }
    if (password.isEmpty) {
      return _fail('Iltimos, parolingizni kiriting.');
    }

    final user = _db.findUserByEmailOrPhone(id);
    final accountKey = user == null ? null : LoginGuard.accountKey(user.id);
    final locked = await _guard.lockRemaining(id) ??
        (accountKey == null ? null : await _guard.lockRemaining(accountKey));
    if (locked != null) {
      await _db.logSecurityEvent(
        action: 'SECURITY_LOCKED_ATTEMPT',
        details: 'Bloklangan loginga kirish urinishi: ${LoginGuard.mask(id)}',
      );
      final minutes = (locked.inSeconds / 60).ceil();
      return _fail(
        'Juda ko‘p noto‘g‘ri urinish. $minutes daqiqadan keyin qayta urinib ko‘ring.',
      );
    }

    final passwordOk = user != null
        ? _db.verifyPassword(user, password.trim())
        : (PasswordHasher.verify(password, _dummyHash) && false);

    if (user == null || !passwordOk) {
      var nowLocked = await _guard.registerFailure(id);
      if (accountKey != null) {
        nowLocked = await _guard.registerFailure(accountKey) || nowLocked;
      }
      await _db.logSecurityEvent(
        action: nowLocked ? 'SECURITY_LOCKOUT' : 'SECURITY_LOGIN_FAILED',
        details: nowLocked
            ? '${LoginGuard.maxFailures} ta noto‘g‘ri urinish — login vaqtincha bloklandi: ${LoginGuard.mask(id)}'
            : 'Noto‘g‘ri login yoki parol: ${LoginGuard.mask(id)}',
        actor: user,
      );
      if (nowLocked) {
        final wait = await _guard.lockRemaining(id) ??
            (accountKey == null ? null : await _guard.lockRemaining(accountKey)) ??
            LoginGuard.lockDuration;
        return _fail(
          'Juda ko‘p noto‘g‘ri urinish. ${(wait.inSeconds / 60).ceil()} daqiqadan keyin qayta urinib ko‘ring.',
        );
      }
      return _fail(_invalidCredentials);
    }

    if (!user.isActive) {
      await _db.logSecurityEvent(
        action: 'SECURITY_BLOCKED_LOGIN',
        details: 'Bloklangan hisob bilan kirish urinishi',
        actor: user,
      );
      return _fail('Ushbu hisob bloklangan. Iltimos, administrator bilan bog‘laning.');
    }

    // Soha mosligi faqat parol tasdiqlangandan keyin tekshiriladi (rol oshkor qilinmaydi)
    if (requiredRole != null && user.role != requiredRole) {
      return _fail('Bu hisob tanlangan bo‘lim uchun mo‘ljallanmagan.');
    }

    await _guard.registerSuccess(id);
    if (accountKey != null) await _guard.registerSuccess(accountKey);
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AuthSession.prefsKey, AuthSession.start(user.id).encode());

    await _db.addAuditLog(
      userFullName: user.fullName,
      userRole: user.role.label,
      action: 'LOGIN',
      entity: 'Auth',
      details: '${user.fullName} (${user.role.label}) tizimga kirdi',
    );

    _isLoading = false;
    notifyListeners();
    return {'success': true, 'message': 'Xush kelibsiz!'};
  }

  // Yangi mutaxassisni ro'yxatdan o'tkazish (Sign Up - Namangan tumanlari va maktabi bilan)
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required UserRole role,
    required String specialization,
    required String qualificationCategory,
    String region = 'Namangan viloyati',
    String district = 'Namangan shahri',
    required String institutionName,
    required String password,
    int experienceYears = 3,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 350));

    // Telefon yoki email bandligini tekshirish
    if (_db.findUserByEmailOrPhone(phone) != null) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Ushbu telefon raqam bilan allaqachon hisob ochilgan.',
      };
    }

    if (email.isNotEmpty && _db.findUserByEmailOrPhone(email) != null) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Ushbu elektron pochta allaqachon ro‘yxatdan o‘tgan.',
      };
    }

    final newId = 'usr_${const Uuid().v4().substring(0, 8)}';
    final fullName = '$lastName $firstName'.trim();

    final newUser = UserModel(
      id: newId,
      email: email.trim().isNotEmpty ? email.trim() : '$phone@talim.uz',
      fullName: fullName,
      role: role,
      region: region,
      district: district,
      phone: phone.trim(),
      specialization: specialization.trim(),
      qualificationCategory: qualificationCategory,
      experienceYears: experienceYears,
      institutionId:
          'inst_namangan_${district.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}',
      institutionName: institutionName.trim().isNotEmpty
          ? institutionName.trim()
          : '14-sonli inklyuziv maktab',
      password: password.trim(),
      isActive: true,
    );

    try {
      await _db.registerUser(newUser);
    } on AppException catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }

    // Yangi yaratilgan foydalanuvchi sifatida avtomatik kirish.
    // Bazadagi nusxa olinadi — xotirada ochiq parol saqlanmasin.
    _currentUser = _db.getUserById(newUser.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AuthSession.prefsKey, AuthSession.start(newUser.id).encode());

    _isLoading = false;
    notifyListeners();
    return {'success': true, 'message': 'Muvaffaqiyatli ro‘yxatdan o‘tdingiz!'};
  }

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'Foydalanuvchi tizimga kirmagan.'};
    }

    if (!_db.verifyPassword(_currentUser!, currentPassword.trim())) {
      return {
        'success': false,
        'message': 'Amaldagi parol noto‘g‘ri kiritildi.',
      };
    }

    if (newPassword.trim().length < 6) {
      return {
        'success': false,
        'message': 'Yangi parol kamida 6 ta belgidan iborat bo‘lishi shart.',
      };
    }

    final updated = _currentUser!.copyWith(password: newPassword.trim());
    try {
      await _db.updateUser(updated, byUser: _currentUser!);
    } on AppException catch (e) {
      return {'success': false, 'message': e.toString()};
    }
    // Bazadagi (xeshlangan) nusxa — xotirada ochiq parol saqlanmasin
    _currentUser = _db.getUserById(updated.id);
    notifyListeners();

    await _db.addAuditLog(
      userFullName: _currentUser!.fullName,
      userRole: _currentUser!.role.label,
      action: 'PASSWORD_CHANGE',
      entity: 'Auth',
      details: '${_currentUser!.fullName} parolini muvaffaqiyatli yangiladi',
    );

    return {
      'success': true,
      'message': 'Parolingiz muvaffaqiyatli o‘zgartirildi.',
    };
  }

  Future<Map<String, dynamic>> requestPasswordRecovery(String identifier) async {
    final cleaned = identifier.trim();
    if (cleaned.isEmpty) {
      return {
        'success': false,
        'message': 'Telefon raqamingiz yoki elektron pochtangizni kiriting.',
      };
    }
    try {
      await _db.requestPasswordRecovery(cleaned);
      return {
        'success': true,
        'message':
            'So‘rov qabul qilindi! Agar hisob mavjud bo‘lsa, muassasa yoki tizim administratoriga parolni tiklash xabarnomasi yuborildi.',
      };
    } on AppException catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    final user = _currentUser;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AuthSession.prefsKey);
    if (user != null) {
      await _db.addAuditLog(
        userFullName: user.fullName,
        userRole: user.role.label,
        action: 'LOGOUT',
        entity: 'Auth',
        details: '${user.fullName} tizimdan chiqdi',
      );
    }
    notifyListeners();
  }
}
