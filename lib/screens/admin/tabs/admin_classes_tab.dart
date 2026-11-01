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
    final teachers = app.allUsers.where((u) => u.role == UserRole.teacher).toList();

    final filtered = classes.where((cl) {
      final grade = (cl['grade'] as String).toLowerCase();
      final inst = (cl['institutionName'] as String).toLowerCase();
      final teacher = (cl['teacherName'] as String).toLowerCase();
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!grade.contains(q) && !inst.contains(q) && !teacher.contains(q)) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Sinflar va Guruhlar Boshqaruvi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD97706).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${filtered.length} ta sinf / guruh',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ta’lim muassasalaridagi inklyuziv sinflar, bolalar tarkibi va biriktirilgan mas’ul o‘qituvchilar',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. QIDIRUV
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Sinf (masalan: 1-A, 4-B), maktab yoki mas’ul o‘qituvchi bo‘yicha...',
                  prefixIcon: const Icon(Icons.search, size: 20),
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

              final classStudents = allStudents
                  .where((s) => s.grade == grade && s.institutionName == instName)
                  .toList();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD97706).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            grade,
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$grade sinf',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
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
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$studentsCount nafar ATEB bola',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🏛️ $instName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '👩‍🏫 Mas’ul sinf rahbari: $teacherName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (needs.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: needs
                                    .map(
                                      (n) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          n,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
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
                        icon: const Icon(Icons.people_outline, size: 16),
                        label: const Text('O‘quvchilar ro‘yxati'),
                      ),
                    ],
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
      builder: (ctx) => AlertDialog(
        title: Text(
          '$grade sinf tarkibi',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 500,
          height: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Muassasa: $instName\nMas’ul o‘qituvchi: $teacherName',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const Divider(height: 16),
              Text(
                'Sinfdagi ATEB o‘quvchilar (${classStudents.length} nafar):',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: classStudents.isEmpty
                    ? const Center(
                        child: Text(
                          'Bu sinfda o‘quvchi ro‘yxatga olinmagan',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: classStudents.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
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
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              st.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${st.primaryNeed} • ${st.supportLevel}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              '${st.assignedSpecialistIds.length} mutaxassis',
                              style: const TextStyle(
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
