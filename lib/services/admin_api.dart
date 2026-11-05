import '../models/user_model.dart';
import 'api_client.dart';

/// Serverdagi foydalanuvchi (administrator ko'rinishi). Parol hech qachon kelmaydi.
class AdminUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? institutionId;
  final String? phone;
  final bool isActive;
  final bool locked;
  final bool pendingApproval;
  final bool mustChangePassword;
  final Map<String, dynamic> profile;

  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.institutionId,
    this.phone,
    this.isActive = true,
    this.locked = false,
    this.pendingApproval = false,
    this.mustChangePassword = false,
    this.profile = const {},
  });

  /// Ro'yxatdan o'tishda o'zi yozgan maktab nomi (administrator tasdiqlashda ko'radi).
  String? get statedInstitution => _text('institution_name');
  String? get district => _text('district');
  String? get specialization => _text('specialization');

  String? _text(String key) {
    final v = profile[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
    id: j['id'] as String,
    email: j['email'] as String,
    fullName: j['full_name'] as String,
    role: UserRoleExtension.fromCode(j['role'] as String? ?? ''),
    institutionId: j['institution_id'] as String?,
    phone: j['phone'] as String?,
    isActive: j['is_active'] != false,
    locked: j['locked'] == true,
    pendingApproval: j['pending_approval'] == true,
    mustChangePassword: j['must_change_password'] == true,
    profile: (j['profile'] as Map?)?.cast<String, dynamic>() ?? const {},
  );
}

class Institution {
  final String id;
  final String name;
  final String region;

  /// Shu muassasadagi tasdiqlangan hisoblar soni.
  final int users;

  const Institution({
    required this.id,
    required this.name,
    this.region = '',
    this.users = 0,
  });

  factory Institution.fromJson(Map<String, dynamic> j) => Institution(
    id: j['id'] as String,
    name: j['name'] as String,
    region: j['region'] as String? ?? '',
    users: (j['users'] as num?)?.toInt() ?? 0,
  );
}

/// /api/admin endpoint'lari. Ularni faqat tizim administratori (emailga kelgan
/// kod bilan kirgan) chaqira oladi; boshqalarga server 404 qaytaradi.
class AdminApi {
  AdminApi([ApiClient? client]) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<AdminUser>> users() async =>
      (await _api.getList(
        '/api/admin/users',
      )).map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();

  /// Yangi hisob. Vaqtinchalik parol foydalanuvchining emailiga yuboriladi —
  /// u javobda qaytmaydi va administratorga ham ko'rsatilmaydi.
  Future<AdminUser> createUser({
    required String email,
    required String fullName,
    required UserRole role,
    String? institutionId,
    String? phone,
  }) async => AdminUser.fromJson(
    await _api.post('/api/admin/users', {
      'email': email,
      'full_name': fullName,
      'role': role.code,
      if (institutionId != null) 'institution_id': institutionId,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    }),
  );

  Future<AdminUser> update(
    String id, {
    UserRole? role,
    bool? isActive,
    String? institutionId,
  }) async => AdminUser.fromJson(
    await _api.patch('/api/admin/users/$id', {
      if (role != null) 'role': role.code,
      if (isActive != null) 'is_active': isActive,
      if (institutionId != null) 'institution_id': institutionId,
    }),
  );

  Future<AdminUser> approve(String id, String institutionId) async =>
      AdminUser.fromJson(
        await _api.post('/api/admin/users/$id/approve', {
          'institution_id': institutionId,
        }),
      );

  Future<void> reject(String id) => _api.post('/api/admin/users/$id/reject');

  Future<AdminUser> unlock(String id) async =>
      AdminUser.fromJson(await _api.post('/api/admin/users/$id/unlock'));

  Future<void> revokeSessions(String id) =>
      _api.post('/api/admin/users/$id/revoke-sessions');

  Future<List<Institution>> institutions() async =>
      (await _api.getList(
        '/api/admin/institutions',
      )).map((e) => Institution.fromJson(e as Map<String, dynamic>)).toList();

  Future<Institution> createInstitution(
    String name, {
    String region = '',
  }) async => Institution.fromJson(
    await _api.post('/api/admin/institutions', {
      'name': name,
      'region': region,
    }),
  );
}
