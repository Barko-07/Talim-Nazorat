import '../models/user_model.dart';
import 'api_client.dart';

/// Kirishning qaysi bosqichida turibmiz (server `state` maydoni).
enum AuthStep {
  /// To'liq kirildi.
  ok,

  /// Emailga yuborilgan 6 xonali kod kutilmoqda.
  emailCode,

  /// Authenticator ilovasidagi kod (yoki zaxira kod) kutilmoqda.
  totp,

  /// Administrator: Authenticator'ni sozlash majburiy.
  totpSetup,

  /// Vaqtinchalik parolni almashtirish majburiy.
  passwordChange,
}

AuthStep _stepOf(String? state) {
  switch (state) {
    case 'ok':
      return AuthStep.ok;
    case 'email_code_required':
      return AuthStep.emailCode;
    case 'mfa_required':
      return AuthStep.totp;
    case 'mfa_setup_required':
      return AuthStep.totpSetup;
    case 'password_change_required':
      return AuthStep.passwordChange;
  }
  throw ApiException(0, 'bad_state', 'Server javobi tushunarsiz: $state');
}

class AuthResult {
  final AuthStep step;
  final UserModel user;

  /// "Eslab qolish" bu hisob uchun ishlaydimi (administratorlarda yo'q).
  final bool canStaySignedIn;

  /// Sessiya "Eslab qolish" bilan ochilgan — ilova faolsizlik uchun chiqarmaydi.
  final bool remembered;

  /// Emailga keyingi kodni necha soniyadan keyin so'rash mumkin.
  final int resendAfter;

  /// Authenticator yoqilganda bir marta beriladigan zaxira kodlar.
  final List<String> recoveryCodes;

  /// Zaxira kod bilan kirilganda — qolgan kodlar soni.
  final int? recoveryCodesLeft;

  const AuthResult({
    required this.step,
    required this.user,
    this.canStaySignedIn = false,
    this.remembered = false,
    this.resendAfter = 0,
    this.recoveryCodes = const [],
    this.recoveryCodesLeft,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final u = json['user'] as Map<String, dynamic>;
    return AuthResult(
      step: _stepOf(json['state'] as String?),
      user: userFromServer(u),
      canStaySignedIn: u['can_stay_signed_in'] == true,
      remembered: json['remembered'] == true,
      resendAfter: (json['resend_after'] as num?)?.toInt() ?? 0,
      recoveryCodes:
          (json['recovery_codes'] as List?)?.cast<String>() ?? const [],
      recoveryCodesLeft: (json['recovery_codes_left'] as num?)?.toInt(),
    );
  }
}

/// Serverdagi foydalanuvchi -> ilovadagi UserModel. Parol hech qachon kelmaydi.
UserModel userFromServer(Map<String, dynamic> u) {
  final profile = (u['profile'] as Map?)?.cast<String, dynamic>() ?? const {};
  String? text(String key) {
    final v = profile[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  return UserModel(
    id: u['id'] as String,
    email: u['email'] as String,
    fullName: u['full_name'] as String,
    role: UserRoleExtension.fromCode(u['role'] as String? ?? ''),
    region: text('region') ?? 'Namangan viloyati',
    district: text('district'),
    institutionId: u['institution_id'] as String?,
    institutionName: text('institution_name'),
    phone: u['phone'] as String?,
    specialization: text('specialization'),
    qualificationCategory: text('qualification_category') ?? 'Mutaxassis',
    experienceYears: (profile['experience_years'] as num?)?.toInt() ?? 0,
    isActive: true,
  );
}

class RegistrationStarted {
  final String registrationId;
  final int resendAfter;
  const RegistrationStarted(this.registrationId, this.resendAfter);
}

class TotpSetup {
  final String secret;
  final String otpauthUri;
  const TotpSetup(this.secret, this.otpauthUri);
}

/// /api/auth endpoint'lari.
class AuthApi {
  AuthApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<AuthResult> login(
    String email,
    String password, {
    bool remember = false,
  }) async => AuthResult.fromJson(
    await _api.post('/api/auth/login', {
      'email': email,
      'password': password,
      'remember': remember,
    }),
  );

  /// Joriy sessiya (ilova qayta ochilganda). Sessiya yo'q bo'lsa — null.
  Future<AuthResult?> me() async {
    try {
      return AuthResult.fromJson(await _api.get('/api/auth/me'));
    } on ApiException catch (e) {
      if (e.status == 401) return null;
      rethrow;
    }
  }

  Future<AuthResult> verifyEmailCode(String code) async => AuthResult.fromJson(
    await _api.post('/api/auth/email-code/verify', {'code': code}),
  );

  /// Yangi kirish kodi. Qaytaradi: keyingisini necha soniyadan so'rash mumkin.
  Future<int> resendEmailCode() async =>
      ((await _api.post('/api/auth/email-code/send'))['resend_after'] as num)
          .toInt();

  Future<AuthResult> verifyTotp(String code) async => AuthResult.fromJson(
    await _api.post('/api/auth/mfa/verify', {'code': code}),
  );

  Future<AuthResult> useRecoveryCode(String code) async =>
      AuthResult.fromJson(
        await _api.post('/api/auth/mfa/recovery', {'code': code}),
      );

  Future<TotpSetup> startTotpSetup(String password) async {
    final r = await _api.post('/api/auth/mfa/setup', {'password': password});
    return TotpSetup(r['secret'] as String, r['otpauth_uri'] as String);
  }

  Future<AuthResult> enableTotp(String code) async => AuthResult.fromJson(
    await _api.post('/api/auth/mfa/enable', {'code': code}),
  );

  Future<void> requestPasswordChangeCode() =>
      _api.post('/api/auth/password/change/request');

  Future<AuthResult> changePassword(
    String currentPassword,
    String newPassword, {
    String? code,
  }) async => AuthResult.fromJson(
    await _api.post('/api/auth/password/change', {
      'current_password': currentPassword,
      'new_password': newPassword,
      if (code != null) 'code': code,
    }),
  );

  Future<void> requestPasswordReset(String email) =>
      _api.post('/api/auth/password/reset/request', {'email': email});

  Future<void> confirmPasswordReset(
    String email,
    String code,
    String newPassword,
  ) => _api.post('/api/auth/password/reset/confirm', {
    'email': email,
    'code': code,
    'new_password': newPassword,
  });

  Future<RegistrationStarted> register({
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
    final r = await _api.post('/api/auth/register', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'role': role.code,
      'specialization': specialization,
      'qualification_category': qualificationCategory,
      'experience_years': experienceYears,
      'region': region,
      'district': district,
      'institution_name': institutionName,
      'password': password,
    });
    return RegistrationStarted(
      r['registration_id'] as String,
      (r['resend_after'] as num).toInt(),
    );
  }

  Future<int> resendRegistrationCode(String registrationId) async =>
      ((await _api.post('/api/auth/register/resend', {
                'registration_id': registrationId,
              }))['resend_after']
              as num)
          .toInt();

  /// Qaytaradi: foydalanuvchiga ko'rsatiladigan xabar.
  Future<String> verifyRegistration(String registrationId, String code) async =>
      (await _api.post('/api/auth/register/verify', {
            'registration_id': registrationId,
            'code': code,
          }))['message']
          as String;

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } finally {
      await _api.clearSession();
    }
  }
}
