import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';

class AdminSpecialistsTab extends StatefulWidget {
  const AdminSpecialistsTab({super.key});

  @override
  State<AdminSpecialistsTab> createState() => _AdminSpecialistsTabState();
}

class _AdminSpecialistsTabState extends State<AdminSpecialistsTab> {
  String _search = '';
  UserRole? _filterRole;
  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final allSpecialists = app.specialists;
    final allStudents = app.students;
    final assessments = app.assessments;
    final sessions = app.sessions;

    final filtered =
        allSpecialists.where((s) {
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            final matchName = s.fullName.toLowerCase().contains(q);
            final matchSpec = (s.specialization ?? '').toLowerCase().contains(
              q,
            );
            final matchInst = (s.institutionName ?? '').toLowerCase().contains(
              q,
            );
            if (!matchName && !matchSpec && !matchInst) return false;
          }
          if (_filterRole != null && s.role != _filterRole) return false;
          if (_filterCategory != null &&
              _filterCategory!.isNotEmpty &&
              s.qualificationCategory != _filterCategory) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Mutaxassislar va Pedagogik Kadrlar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purpleBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '${filtered.length} ta mutaxassis',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Inklyuziv va maxsus ta’lim bo‘yicha psixologlar, logopedlar, defektologlar va o‘qituvchilar hisobi',
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
          const SizedBox(height: 20),

          // 2. FILTRLAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.cardGlassBorder, width: 1.0),
      ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v.trim()),
                      decoration: InputDecoration(
                        hintText:
                            'F.I.SH, ixtisoslik yoki muassasa bo‘yicha...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
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
                        labelText: 'Yo‘nalish / Rol',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Barcha mutaxassisliklar'),
                        ),
                        ...[
                          UserRole.psychologist,
                          UserRole.speechTherapist,
                          UserRole.specialEducation,
                          UserRole.specialEdTeacher,
                          UserRole.teacher,
                          UserRole.coordinator,
                        ].map(
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
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: _filterCategory,
                      decoration: InputDecoration(
                        labelText: 'Toifasi',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Barcha toifalar'),
                        ),
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
                      onChanged: (v) => setState(() => _filterCategory = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. MUTAXASSISLAR RO'YXATI
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final sp = filtered[i];
              final userAssessmentsCount =
                  assessments.where((a) => a.specialistId == sp.id).length;
              final userSessionsCount =
                  sessions.where((s) => s.specialistId == sp.id).length;

              // Biriktirilgan o'quvchilar
              final assignedStudents =
                  allStudents
                      .where(
                        (st) =>
                            st.assignedSpecialistIds.contains(sp.id) ||
                            sp.assignedStudentIds.contains(st.id),
                      )
                      .toList();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.cardGlassBorder, width: 1.0),
      ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final isCompact = cardConstraints.maxWidth < 560;

                      final avatar = CircleAvatar(
                        radius: 26,
                        backgroundColor: sp.role.color.withValues(alpha: 0.15),
                        child: Icon(
                          sp.role.icon,
                          color: sp.role.color,
                          size: 28,
                        ),
                      );

                      final specialistInfo = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                sp.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: sp.role.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sp.role.label,
                                  style: TextStyle(
                                    color: sp.role.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sp.qualificationCategory ?? 'Mutaxassis',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mutaxassislik: ${sp.specialization ?? sp.role.professionTitle} • Ish staji: ${sp.experienceYears} yil',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${sp.institutionName ?? 'Muassasa belgilanmagan'} (${sp.district ?? 'Namangan viloyati'})',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildMetricPill(
                                icon: LucideIcons.users,
                                label:
                                    '${assignedStudents.length} ta bola biriktirilgan',
                                color: AppColors.primary,
                              ),
                              _buildMetricPill(
                                icon: LucideIcons.clipboardCheck,
                                label:
                                    '$userAssessmentsCount ta baholash o‘tkazilgan',
                                color: AppColors.success,
                              ),
                              _buildMetricPill(
                                icon: LucideIcons.calendarCheck,
                                label:
                                    '$userSessionsCount ta korreksion mashg‘ulot',
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                        ],
                      );

                      final actionBtn = OutlinedButton.icon(
                        onPressed:
                            () => _showAssignedStudentsDialog(
                              context,
                              sp,
                              assignedStudents,
                              allStudents,
                              currentUser,
                            ),
                        icon: const Icon(LucideIcons.users, size: 16),
                        label: const Text('O‘quvchilar ro‘yxati'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                avatar,
                                const SizedBox(width: 14),
                                Expanded(child: specialistInfo),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(width: double.infinity, child: actionBtn),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          avatar,
                          const SizedBox(width: 16),
                          Expanded(child: specialistInfo),
                          const SizedBox(width: 16),
                          actionBtn,
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignedStudentsDialog(
    BuildContext context,
    UserModel specialist,
    List<StudentModel> assigned,
    List<StudentModel> allStudents,
    UserModel? byUser,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setSheetState) {
              final unassignedToThis =
                  allStudents
                      .where(
                        (st) =>
                            !st.assignedSpecialistIds.contains(specialist.id) &&
                            !specialist.assignedStudentIds.contains(st.id),
                      )
                      .toList();

              return AlertDialog(
                title: Text(
                  '${specialist.fullName}ga biriktirilgan o‘quvchilar',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: SizedBox(
                  width: 500,
                  height: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lavozimi: ${specialist.role.label} • Muassasa: ${specialist.institutionName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Joriy o‘quvchilar (${assigned.length}):',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (unassignedToThis.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                _showAssignStudentModal(
                                  ctx,
                                  specialist,
                                  unassignedToThis,
                                  byUser,
                                  onAssigned: () {
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text('Yangi bola biriktirish'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child:
                            assigned.isEmpty
                                ? Center(
                                  child: Text(
                                    'Hozircha o‘quvchi biriktirilmagan',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  itemCount: assigned.length,
                                  separatorBuilder:
                                      (_, _) => const Divider(height: 1),
                                  itemBuilder: (c, idx) {
                                    final st = assigned[idx];
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primaryLight,
                                        child: Text(
                                          '${idx + 1}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        st.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${st.grade} • ${st.primaryNeed}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Yopish'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showAssignStudentModal(
    BuildContext parentCtx,
    UserModel specialist,
    List<StudentModel> unassigned,
    UserModel? byUser, {
    required VoidCallback onAssigned,
  }) {
    final app = parentCtx.read<AppProvider>();
    StudentModel? selectedStudent = unassigned.first;

    showDialog(
      context: parentCtx,
      builder:
          (dlgCtx) => StatefulBuilder(
            builder:
                (context, setDlgState) => AlertDialog(
                  title: const Text('Mutaxassisga bola biriktirish'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<StudentModel>(
                        initialValue: selectedStudent,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'O‘quvchini tanlang',
                        ),
                        items:
                            unassigned
                                .map(
                                  (st) => DropdownMenuItem(
                                    value: st,
                                    child: Text(
                                      '${st.fullName} (${st.grade}, ${st.institutionName})',
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) setDlgState(() => selectedStudent = v);
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dlgCtx),
                      child: const Text('Bekor qilish'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      onPressed: () async {
                        if (selectedStudent != null) {
                          final nav = Navigator.of(dlgCtx);
                          await app.assignSpecialistToStudent(
                            selectedStudent!.id,
                            specialist.id,
                            byUser: byUser,
                          );
                          nav.pop();
                          onAssigned();
                        }
                      },
                      child: const Text('Biriktirish'),
                    ),
                  ],
                ),
          ),
    );
  }
}
