import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/access_control_service.dart';

class SpecialistsScreen extends StatelessWidget {
  const SpecialistsScreen({super.key});

  void _showAddStaffDialog(BuildContext context) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+998 ');
    final emailCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    UserRole selectedRole = UserRole.psychologist;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Yangi xodim / mutaxassis qo‘shish'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'F.I.Sh. (To‘liq) *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Lavozimi va roli *',
                    ),
                    items: [
                      UserRole.psychologist,
                      UserRole.speechTherapist,
                      UserRole.specialEducation,
                      UserRole.teacher,
                      UserRole.coordinator,
                      UserRole.institutionAdmin,
                    ]
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setDlgState(() {
                        selectedRole = v!;
                        specCtrl.text = selectedRole.professionTitle;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: specCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mutaxassislik yo‘nalishi',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Telefon raqami *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Elektron pochta (Email)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Iltimos, xodimning to‘liq ismini kiriting!',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final newStaff = UserModel(
                  id: 'usr_${const Uuid().v4().substring(0, 8)}',
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim().isNotEmpty
                      ? emailCtrl.text.trim()
                      : '${phoneCtrl.text.replaceAll(RegExp(r'\D'), '')}@talim.uz',
                  phone: phoneCtrl.text.trim(),
                  role: selectedRole,
                  specialization: specCtrl.text.trim().isNotEmpty
                      ? specCtrl.text.trim()
                      : selectedRole.label,
                  institutionId: user?.institutionId,
                  institutionName: user?.institutionName,
                  region: user?.region ?? 'Namangan viloyati',
                  district: user?.district ?? 'Chortoq tumani',
                  password: 'Parol2026!',
                  isActive: true,
                );

                await app.updateUser(newStaff, byUser: user);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Yangi xodim muvaffaqiyatli qo‘shildi! Boshlang‘ich parol: Parol2026!',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Qo‘shish'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final accessControl = AccessControlService();
    final canManage = user != null && accessControl.canManageUsers(user);

    final staffList = canManage ? app.allUsers : app.specialists;
    final allStudents = app.students;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Mutaxassislar')) : null,
      body: ResponsivePageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              icon: LucideIcons.userCheck,
              title: 'Kadrlar va mutaxassislar shtati',
              subtitle:
                  'Muassasa xodimlari, biriktirilgan sohalar va o‘quvchi yuklamasi (${staffList.length} nafar)',
              action: canManage
                  ? FilledButton.icon(
                      icon: const Icon(LucideIcons.userPlus, size: 16),
                      label: const Text('Yangi xodim'),
                      onPressed: () => _showAddStaffDialog(context),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                itemCount: staffList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  final assignedCount = allStudents
                      .where((s) => s.assignedSpecialistIds.contains(staff.id))
                      .length;
                  final isActive = staff.isActive;

                  return SurfaceCard(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: staff.role.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            staff.role.icon,
                            color: staff.role.color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    staff.fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isActive
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  if (!isActive)
                                    const StatusPill(
                                      label: 'Bloklangan',
                                      color: AppColors.error,
                                      backgroundColor: AppColors.errorBg,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${staff.role.label} • ${staff.specialization ?? staff.role.professionTitle}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: staff.role.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${staff.institutionName ?? 'Belgilanmagan'} • ${staff.phone ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                border:
                                    Border.all(color: AppColors.hairlineBorder),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$assignedCount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: AppColors.primary,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const Text(
                                    'o‘quvchi',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (canManage &&
                                staff.id != user.id &&
                                staff.role != UserRole.superAdmin) ...[
                              const SizedBox(height: 6),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 28),
                                  foregroundColor: isActive
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                                onPressed: () {
                                  app.toggleUserActive(
                                    staff.id,
                                    !isActive,
                                    byUser: user,
                                  );
                                },
                                child: Text(
                                  isActive ? 'Bloklash' : 'Faollashtirish',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
