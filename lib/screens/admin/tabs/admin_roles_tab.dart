import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/app_provider.dart';

class AdminRolesTab extends StatefulWidget {
  const AdminRolesTab({super.key});

  @override
  State<AdminRolesTab> createState() => _AdminRolesTabState();
}

class _AdminRolesTabState extends State<AdminRolesTab> {
  UserRole _selectedRole = UserRole.superAdmin;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allUsers = app.allUsers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Rollar va Ruxsatlar Boshqaruvi (RBAC)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '9 ta tizim roli',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Davlat axborot xavfsizligi va minimal imtiyozlar (Least Privilege) talablariga muvofiq rollar huquqlari matritsasi',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. IKKI USTUNLI TARKIB: CHAPDA ROLLAR, O'NGDA TAFSILOTLAR VA MATRITSA
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CHAP USTUN: ROLLAR RO'YXATI
              SizedBox(
                width: 320,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Text(
                            'Tizim Rollari',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Divider(height: 12),
                        ...UserRole.values.map((role) {
                          final isSelected = role == _selectedRole;
                          final count = allUsers
                              .where((u) => u.role == role && u.isActive)
                              .length;

                          return InkWell(
                            onTap: () => setState(() => _selectedRole = role),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    role.icon,
                                    size: 18,
                                    color: isSelected
                                        ? AppColors.primary
                                        : role.color,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      role.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // O'NG USTUN: TANLANGAN ROL HUQUQLARI MATRITSASI
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ROL SARLAVHASI
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  _selectedRole.color.withValues(alpha: 0.15),
                              child: Icon(
                                _selectedRole.icon,
                                color: _selectedRole.color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedRole.label,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Tizim kodi: ${_selectedRole.code} • Kasbiy yo‘nalish: ${_selectedRole.professionTitle}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _selectedRole.domainDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // RUXSATLAR MATRITSASI
                        Text(
                          'Funksional Ruxsatlar va Vakolatlar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPermissionItem(
                          title: 'O‘quvchilar bazasini ko‘rish',
                          description:
                              'Hududiy yoki maktab doirasidagi bolalar ro‘yxatini ko‘rish',
                          allowed: _selectedRole != UserRole.parent,
                        ),
                        _buildPermissionItem(
                          title: 'O‘quvchi anketasini yaratish / tahrirlash',
                          description:
                              'Yangi bola kiritish, anketasini o‘zgartirish',
                          allowed: _selectedRole == UserRole.superAdmin ||
                              _selectedRole == UserRole.institutionAdmin ||
                              _selectedRole == UserRole.coordinator ||
                              _selectedRole == UserRole.teacher,
                        ),
                        _buildPermissionItem(
                          title: 'Maxfiy tibbiy ma’lumotlarni ko‘rish',
                          description:
                              'Kasalxona/tibbiy xulosalar va psixologik diagnozlar',
                          allowed: _selectedRole == UserRole.superAdmin ||
                              _selectedRole == UserRole.institutionAdmin ||
                              _selectedRole == UserRole.psychologist ||
                              _selectedRole == UserRole.specialEducation ||
                              _selectedRole == UserRole.coordinator,
                        ),
                        _buildPermissionItem(
                          title: 'Diagnostik baholash o‘tkazish',
                          description:
                              'Baholash kartasini to‘ldirish va ball qo‘yish',
                          allowed: _selectedRole.canCreateAssessments,
                        ),
                        _buildPermissionItem(
                          title: 'Korreksion mashg‘ulotlarni rejalashtirish',
                          description:
                              'Bolalar uchun yakka tartibdagi mashg‘ulot taqvimi',
                          allowed: _selectedRole != UserRole.reviewer &&
                              _selectedRole != UserRole.parent,
                        ),
                        _buildPermissionItem(
                          title: 'Mashg‘ulot natijasini tasdiqlash',
                          description:
                              'O‘tkazilgan dars bo‘yicha professional kuzatuv kiritish',
                          allowed: _selectedRole == UserRole.superAdmin ||
                              _selectedRole == UserRole.institutionAdmin ||
                              _selectedRole == UserRole.psychologist ||
                              _selectedRole == UserRole.speechTherapist ||
                              _selectedRole == UserRole.specialEducation ||
                              _selectedRole == UserRole.teacher,
                        ),
                        _buildPermissionItem(
                          title: 'ITR rejasini boshqarish va maqsad belgilash',
                          description:
                              'Individual Ta’lim Rejasini tasdiqlash va maqsadlar qo‘yish',
                          allowed: _selectedRole == UserRole.superAdmin ||
                              _selectedRole == UserRole.institutionAdmin ||
                              _selectedRole == UserRole.coordinator,
                        ),
                        _buildPermissionItem(
                          title: 'Foydalanuvchilarni boshqarish (CRUD)',
                          description:
                              'Xodim qo‘shish, tahrirlash, faollashtirish va bloklash',
                          allowed: _selectedRole == UserRole.superAdmin ||
                              _selectedRole == UserRole.institutionAdmin,
                        ),
                        _buildPermissionItem(
                          title: 'Audit jurnalini ko‘rish',
                          description:
                              'Tizimdagi barcha amallar va o‘zgarishlar jurnalini o‘qish',
                          allowed: _selectedRole == UserRole.superAdmin ||
                              _selectedRole == UserRole.institutionAdmin ||
                              _selectedRole == UserRole.reviewer,
                        ),
                        _buildPermissionItem(
                          title: 'Tizim umumiy sozlamalari va ma’muriyat',
                          description:
                              'Baza sozlamalari, xavfsizlik va davlat parametrlari',
                          allowed: _selectedRole == UserRole.superAdmin,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required bool allowed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: allowed
                  ? AppColors.successBg
                  : AppColors.errorBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              allowed ? Icons.check : Icons.close,
              size: 14,
              color: allowed
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: allowed
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            allowed ? 'Ruxsat etilgan' : 'Taqiqlangan',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: allowed
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
