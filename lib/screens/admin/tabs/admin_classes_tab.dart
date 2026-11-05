import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/app_provider.dart';

class AdminClassesTab extends StatefulWidget {
  const AdminClassesTab({super.key});

  @override
  State<AdminClassesTab> createState() => _AdminClassesTabState();
}

class _AdminClassesTabState extends State<AdminClassesTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final classes = app.classesSummary;
    final allStudents = app.students;
    final teachers =
        app.allUsers.where((u) => u.role == UserRole.teacher).toList();

    final filtered =
        classes.where((cl) {
          final grade = (cl['grade'] as String).toLowerCase();
          final inst = (cl['institutionName'] as String).toLowerCase();
          final teacher = (cl['teacherName'] as String).toLowerCase();
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            if (!grade.contains(q) &&
                !inst.contains(q) &&
                !teacher.contains(q)) {
              return false;
            }
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
                            'Sinflar va Guruhlar Boshqaruvi',
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
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '${filtered.length} ta sinf / guruh',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ta’lim muassasalaridagi inklyuziv sinflar, bolalar tarkibi va biriktirilgan mas’ul o‘qituvchilar',
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

          // 2. QIDIRUV
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.cardGlassBorder, width: 1.0),
      ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.trim()),
                decoration: InputDecoration(
                  hintText:
                      'Sinf (masalan: 1-A, 4-B), maktab yoki mas’ul o‘qituvchi bo‘yicha...',
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
          ),
          const SizedBox(height: 16),

          // 3. SINFLAR JADVALI
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final cl = filtered[i];
              final grade = cl['grade'] as String;
              final instName = cl['institutionName'] as String;
              final studentsCount = cl['studentsCount'] as int;
              final teacherName = cl['teacherName'] as String;
              final needs = (cl['needs'] as Set<String>).toList();

              final classStudents =
                  allStudents
                      .where(
                        (s) =>
                            s.grade == grade && s.institutionName == instName,
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

                      final iconBadge = Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            grade,
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );

                      final classInfo = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '$grade sinf',
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
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$studentsCount nafar ATEB bola',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            instName,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mas’ul sinf rahbari: $teacherName',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (needs.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children:
                                  needs
                                      .map(
                                        (n) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceMuted,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            n,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ],
                      );

                      final actionBtn = OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          _showClassStudentsModal(
                            context,
                            grade,
                            instName,
                            teacherName,
                            classStudents,
                            teachers,
                          );
                        },
                        icon: const Icon(LucideIcons.users, size: 16),
                        label: const Text('O‘quvchilar ro‘yxati'),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                iconBadge,
                                const SizedBox(width: 14),
                                Expanded(child: classInfo),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(width: double.infinity, child: actionBtn),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          iconBadge,
                          const SizedBox(width: 16),
                          Expanded(child: classInfo),
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

  void _showClassStudentsModal(
    BuildContext context,
    String grade,
    String instName,
    String teacherName,
    List<dynamic> classStudents,
    List<UserModel> teachers,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              '$grade sinf tarkibi',
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SizedBox(
              width: 500,
              height: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muassasa: $instName\nMas’ul o‘qituvchi: $teacherName',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Divider(height: 16),
                  Text(
                    'Sinfdagi ATEB o‘quvchilar (${classStudents.length} nafar):',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child:
                        classStudents.isEmpty
                            ? Center(
                              child: Text(
                                'Bu sinfda o‘quvchi ro‘yxatga olinmagan',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                            : ListView.separated(
                              itemCount: classStudents.length,
                              separatorBuilder:
                                  (_, _) => const Divider(height: 1),
                              itemBuilder: (c, idx) {
                                final st = classStudents[idx];
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
                                    '${st.primaryNeed} • ${st.supportLevel}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: Text(
                                    '${st.assignedSpecialistIds.length} mutaxassis',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
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
          ),
    );
  }
}
