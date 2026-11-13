import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/namangan_data.dart';
import '../../../models/user_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/password_hasher.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/theme/box_input_border.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  String _search = '';
  UserRole? _filterRole;
  bool? _filterActive;
  String? _filterDistrict;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final allUsers = app.allUsers;

    final filteredUsers =
        allUsers.where((u) {
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            final matchesName = u.fullName.toLowerCase().contains(q);
            final matchesEmail = u.email.toLowerCase().contains(q);
            final matchesPhone = (u.phone ?? '').toLowerCase().contains(q);
            final matchesInst = (u.institutionName ?? '')
                .toLowerCase()
                .contains(q);
            if (!matchesName &&
                !matchesEmail &&
                !matchesPhone &&
                !matchesInst) {
              return false;
            }
          }
          if (_filterRole != null && u.role != _filterRole) return false;
          if (_filterActive != null && u.isActive != _filterActive) {
            return false;
          }
          if (_filterDistrict != null &&
              _filterDistrict!.isNotEmpty &&
              u.district != _filterDistrict) {
            return false;
          }
          return true;
        }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 640;
              final headerTexts = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Foydalanuvchilar Boshqaruvi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
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
                          '${filteredUsers.length} ta xodim',
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
                    'Tizim xodimlarini ro‘yxatga olish, rollarini belgilash, ma’lumotlarini tahrirlash va hisoblarini faollashtirish/bloklash',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              );

              final addBtn = ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context, currentUser),
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('Yangi Foydalanuvchi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [headerTexts, const SizedBox(height: 12), addBtn],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: headerTexts),
                  const SizedBox(width: 16),
                  addBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 2. FILTRLAR PANELI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: AppColors.cardGlassBorder, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v.trim()),
                          decoration: InputDecoration(
                            hintText:
                                'F.I.SH, email, telefon yoki muassasa bo‘yicha qidiruv...',
                            prefixIcon: const Icon(
                              LucideIcons.search,
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: BoxInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: BoxInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<UserRole?>(
                          initialValue: _filterRole,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Roli bo‘yicha',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: BoxInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Barcha rollar'),
                            ),
                            ...UserRole.values.map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                  r.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _filterRole = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<bool?>(
                          isExpanded: true,
                          initialValue: _filterActive,
                          decoration: InputDecoration(
                            labelText: 'Holati',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: BoxInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Barcha holatlar'),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Faqat faollar'),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text('Faqat bloklanganlar'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _filterActive = v),
                        ),
                      ),
                      if (_search.isNotEmpty ||
                          _filterRole != null ||
                          _filterActive != null) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: 'Filtrlarni tozalash',
                          onPressed:
                              () => setState(() {
                                _search = '';
                                _filterRole = null;
                                _filterActive = null;
                                _filterDistrict = null;
                              }),
                          icon: Icon(LucideIcons.x, color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. FOYDALANUVCHILAR RO'YXATI JADVALI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: AppColors.cardGlassBorder, width: 1.0),
            ),
            child:
                filteredUsers.isEmpty
                    ? Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.userX,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Mos keluvchi foydalanuvchilar topilmadi',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = filteredUsers[index];
                        final isCurrent = u.id == currentUser?.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: u.role.color.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              u.role.icon,
                              color: u.role.color,
                              size: 22,
                            ),
                          ),
                          title: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                u.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Siz',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              _buildRolePill(u.role),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  u.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (u.phone != null)
                                  Text(
                                    '${u.phone}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                Text(
                                  u.institutionName ?? 'Muassasa yo‘q',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // HOLAT TUGMASI (Faol / Bloklangan)
                              InkWell(
                                onTap:
                                    isCurrent
                                        ? null
                                        : () => _toggleUserStatus(
                                          context,
                                          u,
                                          currentUser,
                                        ),
                                borderRadius: BorderRadius.circular(20),
                                child: StatusBadge.active(
                                  u.isActive,
                                  inactiveLabel: 'Bloklangan',
                                ),
                              ),
                              const SizedBox(width: 8),

                              // TAHRIRLASH
                              IconButton(
                                icon: Icon(
                                  LucideIcons.edit,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                tooltip: 'Tahrirlash',
                                onPressed:
                                    () => _showEditUserDialog(
                                      context,
                                      u,
                                      currentUser,
                                    ),
                              ),

                              // O'CHIRISH (Super admindan tashqari)
                              if (!isCurrent && u.role != UserRole.superAdmin)
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  tooltip: 'Tizimdan o‘chirish',
                                  onPressed:
                                      () => _confirmDeleteUser(
                                        context,
                                        u,
                                        currentUser,
                                      ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePill(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: role.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: role.color.withValues(alpha: 0.25)),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: role.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==================== FOYDALANUVCHINI FAOLLASHTIRISH / BLOKLASH ====================
  void _toggleUserStatus(
    BuildContext context,
    UserModel target,
    UserModel? byUser,
  ) {
    final app = context.read<AppProvider>();
    final newStatus = !target.isActive;
    final actionText = newStatus ? 'faollashtirish' : 'bloklash';

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Foydalanuvchini $actionText'),
            content: Text(
              'Haqiqatan ham "${target.fullName}" hisobini ${actionText}ni xohlaysizmi?\n\n'
              '${newStatus ? "Foydalanuvchi tizimga kirish huquqiga ega bo‘ladi." : "Foydalanuvchining tizimga kirishi darhol to‘xtatiladi."}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor qilish'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      newStatus ? AppColors.success : AppColors.error,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await app.toggleUserActive(
                      target.id,
                      newStatus,
                      byUser: byUser,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${target.fullName} hisobi muvaffaqiyatli ${newStatus ? 'faollashtirildi' : 'bloklandi'}.',
                          ),
                          backgroundColor:
                              newStatus ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: Text(newStatus ? 'Faollashtirish' : 'Bloklash'),
              ),
            ],
          ),
    );
  }

  // ==================== O'CHIRISHNI TASDIQLASH ====================
  void _confirmDeleteUser(
    BuildContext context,
    UserModel target,
    UserModel? byUser,
  ) {
    final app = context.read<AppProvider>();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Foydalanuvchini o‘chirish'),
            content: Text(
              'Diqqat! "${target.fullName}" (${target.role.label}) hisobini tizimdan butunlay o‘chirib tashlamoqchimisiz?\n\nUshbu amal audit jurnaliga qayd etiladi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor qilish'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await app.deleteUser(target.id, byUser: byUser);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${target.fullName} tizimdan o‘chirildi.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('O‘chirish'),
              ),
            ],
          ),
    );
  }

  // ==================== YANGI FOYDALANUVCHI QO'SHISH MODAL ====================
  void _showAddUserDialog(BuildContext context, UserModel? byUser) {
    final app = context.read<AppProvider>();
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+998 ');
    final emailCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final passCtrl = TextEditingController(
      text: PasswordHasher.generateTemporary(),
    );
    int expYears = 3;
    String category = 'Mutaxassis';
    UserRole selectedRole = UserRole.psychologist;
    String selectedDistrict = NamanganData.defaultDistrict;
    String selectedSchool =
        NamanganData.getSchoolsForDistrict(selectedDistrict).first;

    specCtrl.text = selectedRole.professionTitle;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setDlgState) {
              final schools = NamanganData.getSchoolsForDistrict(
                selectedDistrict,
              );

              return AlertDialog(
                title: const Text(
                  'Yangi Foydalanuvchi / Xodim Yaratish',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5),
                ),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'F.I.SH (Familya Ism Sharif) *',
                              prefixIcon: Icon(LucideIcons.user),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'F.I.SH kiritilishi shart'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<UserRole>(
                                  isExpanded: true,
                                  initialValue: selectedRole,
                                  decoration: const InputDecoration(
                                    labelText: 'Roli va Lavozimi *',
                                  ),
                                  items:
                                      UserRole.values
                                          .where(
                                            (r) => r != UserRole.superAdmin,
                                          )
                                          .map(
                                            (r) => DropdownMenuItem(
                                              value: r,
                                              child: Text(
                                                r.label,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDlgState(() {
                                        selectedRole = v;
                                        specCtrl.text =
                                            selectedRole.professionTitle;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: category,
                                  decoration: const InputDecoration(
                                    labelText: 'Malaka toifasi',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Oliy toifa',
                                      child: Text('Oliy toifa'),
                                    ),
                                    DropdownMenuItem(
                                      value: '1-toifa',
                                      child: Text('1-toifa'),
                                    ),
                                    DropdownMenuItem(
                                      value: '2-toifa',
                                      child: Text('2-toifa'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Mutaxassis',
                                      child: Text('Mutaxassis'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDlgState(() => category = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: phoneCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Telefon raqam *',
                                    prefixIcon: Icon(LucideIcons.phone),
                                  ),
                                  validator:
                                      (v) =>
                                          v == null || v.trim().length < 9
                                              ? 'Telefon raqami kiritilsin'
                                              : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: emailCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Elektron pochta (Email) *',
                                    prefixIcon: Icon(LucideIcons.mail),
                                  ),
                                  validator:
                                      (v) =>
                                          v == null || !v.contains('@')
                                              ? 'Email to‘g‘ri kiritilsin'
                                              : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: selectedDistrict,
                                  decoration: const InputDecoration(
                                    labelText: 'Hudud / Tuman *',
                                  ),
                                  items:
                                      NamanganData.districts
                                          .map(
                                            (d) => DropdownMenuItem(
                                              value: d,
                                              child: Text(
                                                d,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDlgState(() {
                                        selectedDistrict = v;
                                        selectedSchool =
                                            NamanganData.getSchoolsForDistrict(
                                              selectedDistrict,
                                            ).first;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue:
                                      schools.contains(selectedSchool)
                                          ? selectedSchool
                                          : schools.first,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Ta’lim muassasasi *',
                                  ),
                                  items:
                                      schools
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDlgState(() => selectedSchool = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: specCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Mutaxassislik sohasi',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  initialValue: expYears,
                                  decoration: const InputDecoration(
                                    labelText: 'Ish staji',
                                  ),
                                  items: List.generate(
                                    40,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('${i + 1} yil'),
                                    ),
                                  ),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDlgState(() => expYears = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Boshlang‘ich kirish paroli *',
                              prefixIcon: Icon(LucideIcons.lock),
                            ),
                            validator:
                                (v) =>
                                    v == null || v.trim().length < 6
                                        ? 'Parol kamida 6 belgi'
                                        : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Bekor qilish'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        final newId =
                            'usr_${const Uuid().v4().substring(0, 8)}';
                        final newUser = UserModel(
                          id: newId,
                          email: emailCtrl.text.trim(),
                          fullName: nameCtrl.text.trim(),
                          role: selectedRole,
                          region: NamanganData.defaultRegion,
                          district: selectedDistrict,
                          phone: phoneCtrl.text.trim(),
                          specialization: specCtrl.text.trim(),
                          qualificationCategory: category,
                          experienceYears: expYears,
                          institutionId:
                              'inst_${selectedDistrict.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}',
                          institutionName: selectedSchool,
                          password: passCtrl.text.trim(),
                          isActive: true,
                        );

                        try {
                          await app.addUser(newUser, byUser: byUser);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${newUser.fullName} muvaffaqiyatli yaratildi.',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Saqlash va Yaratish'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // ==================== TAHRIRLASH MODAL ====================
  void _showEditUserDialog(
    BuildContext context,
    UserModel target,
    UserModel? byUser,
  ) {
    final app = context.read<AppProvider>();
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: target.fullName);
    final phoneCtrl = TextEditingController(text: target.phone ?? '');
    final specCtrl = TextEditingController(text: target.specialization ?? '');
    int expYears = target.experienceYears;
    String category = target.qualificationCategory ?? 'Mutaxassis';
    UserRole selectedRole = target.role;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDlgState) => AlertDialog(
                  title: Text(
                    '${target.fullName} ma’lumotlarini tahrirlash',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                    ),
                  ),
                  content: SizedBox(
                    width: 480,
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'F.I.SH *',
                                prefixIcon: Icon(LucideIcons.user),
                              ),
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'F.I.SH to‘ldirilsin'
                                          : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: phoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Telefon raqam',
                                prefixIcon: Icon(LucideIcons.phone),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<UserRole>(
                              isExpanded: true,
                              initialValue: selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Lavozim va Rol',
                              ),
                              items:
                                  UserRole.values
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r.label),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDlgState(() => selectedRole = v);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: category,
                                    decoration: const InputDecoration(
                                      labelText: 'Toifa',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Oliy toifa',
                                        child: Text('Oliy toifa'),
                                      ),
                                      DropdownMenuItem(
                                        value: '1-toifa',
                                        child: Text('1-toifa'),
                                      ),
                                      DropdownMenuItem(
                                        value: '2-toifa',
                                        child: Text('2-toifa'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Mutaxassis',
                                        child: Text('Mutaxassis'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setDlgState(() => category = v);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    isExpanded: true,
                                    initialValue: expYears,
                                    decoration: const InputDecoration(
                                      labelText: 'Ish staji',
                                    ),
                                    items: List.generate(
                                      40,
                                      (i) => DropdownMenuItem(
                                        value: i + 1,
                                        child: Text('${i + 1} yil'),
                                      ),
                                    ),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setDlgState(() => expYears = v);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: specCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Mutaxassislik sohasi',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Bekor qilish'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          final updated = target.copyWith(
                            fullName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            role: selectedRole,
                            qualificationCategory: category,
                            experienceYears: expYears,
                            specialization: specCtrl.text.trim(),
                          );

                          try {
                            await app.updateUser(updated, byUser: byUser);
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Ma’lumotlar muvaffaqiyatli saqlandi.',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Saqlash'),
                    ),
                  ],
                ),
          ),
    );
  }
}
