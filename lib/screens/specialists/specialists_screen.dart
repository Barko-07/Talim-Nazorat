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
import '../../services/password_hasher.dart';

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
                      UserRole.specialEdTeacher,
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

                final tempPassword = PasswordHasher.generateTemporary();
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
                  password: tempPassword,
                  isActive: true,
                );

                await app.addUser(newStaff, byUser: user);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Yangi xodim muvaffaqiyatli qo‘shildi! Vaqtinchalik parol: $tempPassword',
                      ),
                      duration: const Duration(seconds: 12),
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
    final width = MediaQuery.sizeOf(context).width;
    final mediaPadding = MediaQuery.paddingOf(context);

    final pageBody = ResponsivePageContainer(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptivePageHeader(
            title: 'Mutaxassislar shtati',
            subtitle:
                'Muassasa kadrlari va yuklamasi • ${staffList.length} nafar',
            action: canManage
                ? HeaderActionButton(
                    icon: LucideIcons.userPlus,
                    label: 'Yangi xodim',
                    onPressed: () => _showAddStaffDialog(context),
                  )
                : null,
          ),
          const SizedBox(height: 9),

          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                width < 920 ? (84.0 + mediaPadding.bottom) : 24.0,
              ),
              itemCount: staffList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final staff = staffList[index];
                final assignedCount = allStudents
                    .where((s) => s.assignedSpecialistIds.contains(staff.id))
                    .length;
                final isActive = staff.isActive;
                final showToggle = canManage &&
                    staff.id != user.id &&
                    staff.role != UserRole.superAdmin;

                return SurfaceCard(
                  borderRadius: 26,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 20,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 480;

                      final mainInfo = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              premiumRoleIcon(staff.role),
                              color: staff.role.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      staff.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        color: isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textMuted,
                                        letterSpacing: -0.2,
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
                                const SizedBox(height: 5),
                                Text(
                                  staff.roleTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: staff.role.color,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${staff.institutionName ?? 'Belgilanmagan'}${staff.phone != null && staff.phone!.isNotEmpty ? ' • ${staff.phone}' : ''}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final toggleButton = showToggle
                          ? TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(0, 30),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null;

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            mainInfo,
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  StatusPill(
                                    label: '$assignedCount ta o‘quvchi',
                                    color: AppColors.primary,
                                    backgroundColor: AppColors.primaryLight,
                                    icon: LucideIcons.users,
                                  ),
                                  if (toggleButton != null) toggleButton,
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: mainInfo),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GlassWell(
                                borderRadius: 12,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$assignedCount',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                        color: AppColors.primary,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      'o‘quvchi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (toggleButton != null) ...[
                                const SizedBox(height: 6),
                                toggleButton,
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Mutaxassislar')) : null,
      body: canPop ? AmbientMeshBackground(child: pageBody) : pageBody,
    );
  }
}
