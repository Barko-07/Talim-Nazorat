import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/config/app_config.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_api.dart';
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
  String? _initializationError;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Ilova ochilib, saqlangan sessiya tekshirilayotgan payt (kirish tugmasi emas).
  bool get isInitializing => _initializing;
  bool _initializing = true;
  String? get initializationError => _initializationError;

  UserRole get currentRole => _currentUser?.role ?? UserRole.reviewer;

  Timer? _sessionTimer;

  /// Serverdagi SESSION_IDLE_MINUTES bilan bir xil.
  static const serverIdleTimeout = Duration(minutes: 30);
  DateTime _lastActivity = DateTime.now();
  DateTime _lastServerCheck = DateTime.now();

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
    if (AppConfig.serverMode) {
      // Faolsizlik ilovada hisoblanadi: har daqiqalik tekshiruv serverga
      // so'rov yuborsa, serverdagi 30 daqiqalik muddat hech qachon tugamasdi.
      if (!_staySignedIn &&
          DateTime.now().difference(_lastActivity) > serverIdleTimeout) {
        await logout();
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final session = AuthSession.decode(prefs.getString(AuthSession.prefsKey));
    final fresh = _db.getUserById(cached.id);
    final valid =
        session != null &&
        session.isValid() &&
        session.userId == cached.id &&
        fresh != null &&
        fresh.isActive &&
        fresh.role == cached.role;
    if (!valid) await logout();
  }

  Future<void> _checkSavedSession() async {
    _initializing = true;
    _isLoading = true;
    _initializationError = null;
    notifyListeners();

    try {
      await _db.init();
      if (AppConfig.serverMode) {
        await _restoreServerSession();
        _lastActivity = DateTime.now();
        return;
      }
      _dummyHash.length; // soxta xeshni oldindan tayyorlash

      final prefs = await SharedPreferences.getInstance();
      // Bazani o‘qigandan keyingina eskirgan sessiya kalitini bekor qilamiz.
      await prefs.remove('auth_user_id');

      final session = AuthSession.decode(prefs.getString(AuthSession.prefsKey));
      final user = session == null ? null : _db.getUserById(session.userId);
      if (session != null &&
          session.isValid() &&
          user != null &&
          user.isActive) {
        _currentUser = user;
        await prefs.setString(AuthSession.prefsKey, session.touched().encode());
      } else {
        await prefs.remove(AuthSession.prefsKey);
      }
    } catch (_) {
      _currentUser = null;
      _initializationError = 'Local storage initialization failed.';
    } finally {
      _isLoading = false;
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> retryInitialization() => _checkSavedSession();

  /// Foydalanuvchi faolligini qayd etadi (faolliksiz vaqt shu paytdan hisoblanadi).
  /// Sessiya muddati tugagan bo'lsa — tizimdan chiqariladi.
  Future<void> touchSession() async {
    if (_currentUser == null) return;
    if (AppConfig.serverMode) {
      await validateSession();
      if (_currentUser == null) return;
      final now = DateTime.now();
      _lastActivity = now;
      // Faol foydalanuvchining serverdagi sessiyasi ham yangilanadi (5 daqiqada bir marta).
      if (now.difference(_lastServerCheck) > const Duration(minutes: 5)) {
        _lastServerCheck = now;
        await _validateServerSession();
      }
      return;
    }
    await validateSession();
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final session = AuthSession.decode(prefs.getString(AuthSession.prefsKey))!;
    final now = DateTime.now();
    if (now.difference(session.lastActive) > const Duration(minutes: 1)) {
      await prefs.setString(
        AuthSession.prefsKey,
        session.touched(now: now).encode(),
      );
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
    bool remember = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    final id = identifier.trim();
    if (id.isEmpty) {
      return _fail(
        AppConfig.serverMode
            ? 'Elektron pochtangizni kiriting.'
            : 'Telefon raqamingiz yoki elektron pochtangizni kiriting.',
      );
    }
    if (password.isEmpty) {
      return _fail('Iltimos, parolingizni kiriting.');
    }
    await _saveRememberedLogin(remember ? id : null);
    if (AppConfig.serverMode) {
      _lastActivity = DateTime.now();
      return _serverLogin(id.toLowerCase(), password, remember);
    }

    final user = _db.findUserByEmailOrPhone(id);
    final accountKey = user == null ? null : LoginGuard.accountKey(user.id);
    final locked =
        await _guard.lockRemaining(id) ??
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

    final passwordOk =
        user != null
            ? _db.verifyPassword(user, password.trim())
            : (PasswordHasher.verify(password, _dummyHash) && false);

    if (user == null || !passwordOk) {
      var nowLocked = await _guard.registerFailure(id);
      if (accountKey != null) {
        nowLocked = await _guard.registerFailure(accountKey) || nowLocked;
      }
      await _db.logSecurityEvent(
        action: nowLocked ? 'SECURITY_LOCKOUT' : 'SECURITY_LOGIN_FAILED',
        details:
            nowLocked
                ? '${LoginGuard.maxFailures} ta noto‘g‘ri urinish — login vaqtincha bloklandi: ${LoginGuard.mask(id)}'
                : 'Noto‘g‘ri login yoki parol: ${LoginGuard.mask(id)}',
        actor: user,
      );
      if (nowLocked) {
        final wait =
            await _guard.lockRemaining(id) ??
            (accountKey == null
                ? null
                : await _guard.lockRemaining(accountKey)) ??
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
      return _fail(
        'Ushbu hisob bloklangan. Iltimos, administrator bilan bog‘laning.',
      );
    }

    // Soha mosligi faqat parol tasdiqlangandan keyin tekshiriladi (rol oshkor qilinmaydi)
    if (requiredRole != null && user.role != requiredRole) {
      return _fail('Bu hisob tanlangan bo‘lim uchun mo‘ljallanmagan.');
    }

    await _guard.registerSuccess(id);
    if (accountKey != null) await _guard.registerSuccess(accountKey);
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AuthSession.prefsKey,
      AuthSession.start(user.id).encode(),
    );

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
      institutionName:
          institutionName.trim().isNotEmpty
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
    await prefs.setString(
      AuthSession.prefsKey,
      AuthSession.start(newUser.id).encode(),
    );

    _isLoading = false;
    notifyListeners();
    return {'success': true, 'message': 'Muvaffaqiyatli ro‘yxatdan o‘tdingiz!'};
  }

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword, {
    String? code,
  }) async {
    if (_currentUser == null) {
      return {'success': false, 'message': 'Foydalanuvchi tizimga kirmagan.'};
    }
    if (AppConfig.serverMode) {
      try {
        _apply(
          await _authApi.changePassword(currentPassword, newPassword, code: code),
        );
        return _ok('Parolingiz muvaffaqiyatli o‘zgartirildi.');
      } on ApiException catch (e) {
        return _apiFail(e);
      }
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

  Future<Map<String, dynamic>> requestPasswordRecovery(
    String identifier,
  ) async {
    final cleaned = identifier.trim();
    if (AppConfig.serverMode) return requestPasswordReset(cleaned);
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
    if (AppConfig.serverMode) {
      _pending = null;
      _staySignedIn = false;
      try {
        await _authApi.logout();
      } on ApiException catch (_) {
        // Server bilan aloqa bo'lmasa ham, qurilmada sessiya tugatiladi;
        // serverdagi sessiya o'z muddati (30 daqiqa faolsizlik) bilan yopiladi.
      }
    } else if (user != null) {
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

  // ======================================================================
  // SERVER REJIMI (AppConfig.serverMode): kirish, ikkinchi bosqich (emailga
  // kod yoki Authenticator), ro'yxatdan o'tish va parolni tiklash serverda.
  // Barcha tekshiruvlarni server qiladi — ilova faqat natijani ko'rsatadi.
  // ======================================================================

  final AuthApi _authApi = AuthApi();

  /// Parol to'g'ri, lekin kirish hali tugamagan (kod kutilmoqda va h.k.).
  AuthResult? _pending;

  AuthStep? get pendingStep => _pending?.step;
  UserModel? get pendingUser => _pending?.user;
  int get resendAfter => _pending?.resendAfter ?? 0;

  /// "Eslab qolish" bilan ochilgan sessiya — ilova faolsizlik uchun chiqarmaydi
  /// (muddatini server belgilaydi: 30 kun).
  bool _staySignedIn = false;

  static const _rememberedLoginKey = 'remembered_login';

  /// "Eslab qolish" belgilangan bo'lsa — keyingi safar email maydoni to'ldirilgan bo'ladi.
  Future<String?> rememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberedLoginKey);
  }

  Future<void> _saveRememberedLogin(String? login) async {
    final prefs = await SharedPreferences.getInstance();
    if (login == null) {
      await prefs.remove(_rememberedLoginKey);
    } else {
      await prefs.setString(_rememberedLoginKey, login);
    }
  }

  Map<String, dynamic> _ok([String message = '', Object? extra]) => {
    'success': true,
    'message': message,
    'step': _pending?.step ?? AuthStep.ok,
    'extra': extra,
  };

  Map<String, dynamic> _apiFail(ApiException e) {
    _isLoading = false;
    notifyListeners();
    return {
      'success': false,
      'message': e.message,
      'code': e.code,
      'retryAfter': e.retryAfter,
    };
  }

  /// Server javobini qo'llaydi: kirish tugagan bo'lsa — foydalanuvchi faollashadi,
  /// aks holda keyingi bosqich eslab qolinadi.
  void _apply(AuthResult result) {
    if (result.step == AuthStep.ok) {
      _db.cacheSignedInUser(result.user);
      _currentUser = result.user;
      _staySignedIn = result.remembered;
      _pending = null;
    } else {
      _pending = result;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _restoreServerSession() async {
    try {
      final me = await _authApi.me();
      if (me != null && me.step == AuthStep.ok) {
        _apply(me);
      } else if (me != null) {
        // Yarim qolgan kirish (masalan kod kiritilmagan) — boshidan boshlanadi.
        await _authApi.logout();
      }
    } on ApiException catch (_) {
      // Internet yo'q: kirish sahifasi ko'rsatiladi, xabar kirishda chiqadi.
    }
  }

  Future<void> _validateServerSession() async {
    try {
      final me = await _authApi.me();
      if (me == null || me.step != AuthStep.ok) {
        _currentUser = null;
        _pending = null;
        notifyListeners();
      }
    } on ApiException catch (_) {
      // Vaqtinchalik aloqa uzilishi sessiyani tugatmaydi.
    }
  }

  Future<Map<String, dynamic>> _serverLogin(
    String email,
    String password,
    bool remember,
  ) async {
    if (!email.contains('@')) {
      return _fail('Elektron pochtangizni kiriting (masalan: ism@maktab.uz).');
    }
    try {
      _apply(await _authApi.login(email, password, remember: remember));
      return _ok('Xush kelibsiz!');
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  /// Faqat administratorlar: emailga kelgan kirish kodi.
  Future<Map<String, dynamic>> verifyEmailCode(String code) async {
    try {
      _apply(await _authApi.verifyEmailCode(code));
      return _ok();
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  /// "Kodni qayta yuborish". `extra` — keyingi so'rovgacha kutiladigan soniyalar.
  Future<Map<String, dynamic>> resendEmailCode() async {
    try {
      final wait = await _authApi.resendEmailCode();
      return _ok('Yangi kod emailingizga yuborildi', wait);
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  Future<Map<String, dynamic>> verifyTotp(String code) async {
    try {
      _apply(await _authApi.verifyTotp(code));
      return _ok();
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  /// Zaxira kod bilan kirish. `extra` — qolgan zaxira kodlar soni.
  Future<Map<String, dynamic>> useRecoveryCode(String code) async {
    try {
      final result = await _authApi.useRecoveryCode(code);
      _apply(result);
      return _ok('', result.recoveryCodesLeft);
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  Future<Map<String, dynamic>> startTotpSetup(String password) async {
    try {
      return _ok('', await _authApi.startTotpSetup(password));
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  /// Authenticator'ni yoqish. `extra` — bir marta ko'rsatiladigan zaxira kodlar.
  /// Kodlar ko'rsatilib bo'lgach [finishTotpSetup] chaqiriladi.
  Future<Map<String, dynamic>> enableTotp(String code) async {
    try {
      final result = await _authApi.enableTotp(code);
      _enabledTotp = result;
      return {'success': true, 'extra': result.recoveryCodes};
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  AuthResult? _enabledTotp;

  /// Foydalanuvchi zaxira kodlarini saqlab olganini tasdiqladi — kirish yakunlanadi.
  void finishTotpSetup() {
    final result = _enabledTotp;
    _enabledTotp = null;
    if (result != null) _apply(result);
  }

  /// Vaqtinchalik parolni birinchi kirishda almashtirish (qo'shimcha kod so'ralmaydi).
  Future<Map<String, dynamic>> changeTemporaryPassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      _apply(await _authApi.changePassword(currentPassword, newPassword));
      return _ok('Parolingiz yangilandi');
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  /// Profil sozlamalarida parolni o'zgartirish uchun emailga kod yuborish.
  Future<Map<String, dynamic>> requestPasswordChangeCode() async {
    try {
      await _authApi.requestPasswordChangeCode();
      return _ok('Tasdiqlash kodi emailingizga yuborildi');
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    if (!email.trim().contains('@')) {
      return {'success': false, 'message': 'Elektron pochtangizni kiriting.'};
    }
    try {
      await _authApi.requestPasswordReset(email.trim().toLowerCase());
      return _ok('Agar hisob mavjud bo‘lsa, tasdiqlash kodi emailga yuborildi.');
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  Future<Map<String, dynamic>> confirmPasswordReset(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      await _authApi.confirmPasswordReset(
        email.trim().toLowerCase(),
        code,
        newPassword,
      );
      return _ok('Parolingiz tiklandi. Endi yangi parol bilan kiring.');
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  /// Ro'yxatdan o'tish (1-qadam). `extra` — [RegistrationStarted].
  Future<Map<String, dynamic>> startRegistration({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required UserRole role,
    required String specialization,
    required String qualificationCategory,
    required int experienceYears,
    required String region,
    required String district,
    required String institutionName,
    required String password,
  }) async {
    try {
      final started = await _authApi.register(
        firstName: firstName,
        lastName: lastName,
        email: email.trim().toLowerCase(),
        phone: phone,
        role: role,
        specialization: specialization,
        qualificationCategory: qualificationCategory,
        experienceYears: experienceYears,
        region: region,
        district: district,
        institutionName: institutionName,
        password: password,
      );
      return _ok('Tasdiqlash kodi emailingizga yuborildi', started);
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  Future<Map<String, dynamic>> resendRegistrationCode(String id) async {
    try {
      final wait = await _authApi.resendRegistrationCode(id);
      return _ok('Yangi kod emailingizga yuborildi', wait);
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  Future<Map<String, dynamic>> verifyRegistration(String id, String code) async {
    try {
      return _ok(await _authApi.verifyRegistration(id, code));
    } on ApiException catch (e) {
      return _apiFail(e);
    }
  }

  /// Kirish yarim yo'lda tashlab ketildi ("Orqaga") — serverdagi yarim sessiya yopiladi.
  Future<void> cancelPendingLogin() async {
    _pending = null;
    notifyListeners();
    try {
      await _authApi.logout();
    } on ApiException catch (_) {}
  }
}
