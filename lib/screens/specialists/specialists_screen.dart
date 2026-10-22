import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
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
          title: const Text('Yangi Xodim / Mutaxassis Qo‘shish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'F.I.SH (To‘liq) *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Lavozimi va Roli *'),
                  items: [
                    UserRole.psychologist,
                    UserRole.speechTherapist,
                    UserRole.specialEducation,
                    UserRole.teacher,
                    UserRole.coordinator,
                    UserRole.institutionAdmin,
                  ].map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
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
                  decoration: const InputDecoration(labelText: 'Mutaxassislik yo‘nalishi'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefon raqami *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Elektron pochta (Email)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Iltimos, xodimning to‘liq ismini kiriting!'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                final newStaff = UserModel(
                  id: 'usr_${const Uuid().v4().substring(0, 8)}',
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : '${phoneCtrl.text.replaceAll(RegExp(r'\D'), '')}@talim.uz',
                  phone: phoneCtrl.text.trim(),
                  role: selectedRole,
                  specialization: specCtrl.text.trim().isNotEmpty ? specCtrl.text.trim() : selectedRole.label,
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
                    const SnackBar(content: Text('Yangi xodim muvaffaqiyatli qo‘shildi! Boshlang‘ich parol: Parol2026!'), backgroundColor: AppColors.success),
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kadrlar va Mutaxassislar Boshqaruvi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Muassasa xodimlari, lavozimlar va yuklama hisobi (${staffList.length} nafar)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                if (canManage)
                  FilledButton.icon(
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Yangi xodim'),
                    onPressed: () => _showAddStaffDialog(context),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                itemCount: staffList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  final assignedCount = allStudents
                      .where((s) => s.assignedSpecialistIds.contains(staff.id))
                      .length;
                  final isActive = staff.isActive;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: staff.role.color.withValues(alpha: 0.15),
                            child: Icon(staff.role.icon, color: staff.role.color, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      staff.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.errorBg,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Bloklangan', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${staff.role.label} • ${staff.specialization ?? staff.role.professionTitle}',
                                  style: TextStyle(fontSize: 12, color: staff.role.color, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Muassasa: ${staff.institutionName ?? 'Belgilanmagan'} • Tel: ${staff.phone ?? ''}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$assignedCount',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                    ),
                                    const Text('o‘quvchi', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              if (canManage && staff.id != user?.id && staff.role != UserRole.superAdmin) ...[
                                const SizedBox(height: 6),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(60, 24),
                                    foregroundColor: isActive ? AppColors.error : AppColors.success,
                                  ),
                                  onPressed: () {
                                    app.toggleUserActive(staff.id, !isActive, byUser: user);
                                  },
                                  child: Text(isActive ? 'Bloklash' : 'Faollashtirish', style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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
