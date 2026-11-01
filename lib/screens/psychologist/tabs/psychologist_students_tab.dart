import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/student_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../students/student_detail_screen.dart';

class PsychologistStudentsTab extends StatefulWidget {
  final Function(StudentModel student)? onSelectStudentForObservation;
  final Function(StudentModel student)? onSelectStudentForAssessment;
  final Function(StudentModel student)? onSelectStudentForSession;

  const PsychologistStudentsTab({
    super.key,
    this.onSelectStudentForObservation,
    this.onSelectStudentForAssessment,
    this.onSelectStudentForSession,
  });

  @override
  State<PsychologistStudentsTab> createState() =>
      _PsychologistStudentsTabState();
}

class _PsychologistStudentsTabState extends State<PsychologistStudentsTab> {
  String _search = '';
  String? _gradeFilter;
  String? _levelFilter;
  bool _onlyAssignedToMe = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final currentUser = auth.currentUser;
    final allAllowedStudents = app.students;
    final df = DateFormat('dd.MM.yyyy');

    // Filtrlash (Psixolog vakolati doirasida)
    final filtered = allAllowedStudents.where((s) {
      if (_onlyAssignedToMe && currentUser != null) {
        final isAssigned = s.assignedSpecialistIds.contains(currentUser.id) ||
            currentUser.assignedStudentIds.contains(s.id);
        if (!isAssigned) return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final mName = s.fullName.toLowerCase().contains(q);
        final mNeed = s.primaryNeed.toLowerCase().contains(q);
        if (!mName && !mNeed) return false;
      }
      if (_gradeFilter != null && s.grade != _gradeFilter) return false;
      if (_levelFilter != null && !s.supportLevel.contains(_levelFilter!)) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha va vakolat eslatmasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Psixologik hisobdagi o‘quvchilar',
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
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${filtered.length} nafar bola',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kasbiy psixologik diagnostika va korreksiya uchun biriktirilgan o‘quvchilar reyestri',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              // Maxfiylik nishoni
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Maxfiy psixologik ma’lumot',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // FILTRLAR PANELI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
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
                            hintText: 'Ism-familiya yoki ehtiyoj toifasi...',
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
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String?>(
                          value: _gradeFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Sinfi',
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
                              child: Text('Barcha sinflar'),
                            ),
                            DropdownMenuItem(value: '1-A', child: Text('1-A sinf')),
                            DropdownMenuItem(value: '2-B', child: Text('2-B sinf')),
                            DropdownMenuItem(value: '3-A', child: Text('3-A sinf')),
                            DropdownMenuItem(value: '4-A', child: Text('4-A sinf')),
                            DropdownMenuItem(value: '5-A', child: Text('5-A sinf')),
                          ],
                          onChanged: (v) => setState(() => _gradeFilter = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String?>(
                          value: _levelFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Yordam darajasi',
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
                              child: Text('Barcha darajalar'),
                            ),
                            DropdownMenuItem(
                              value: '1-daraja',
                              child: Text('1-daraja (Yengil)'),
                            ),
                            DropdownMenuItem(
                              value: '2-daraja',
                              child: Text('2-daraja (O‘rta)'),
                            ),
                            DropdownMenuItem(
                              value: '3-daraja',
                              child: Text('3-daraja (Intensiv)'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _levelFilter = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilterChip(
                        selected: _onlyAssignedToMe,
                        label: const Text('Faqat menga biriktirilgan bolalar'),
                        avatar: Icon(
                          _onlyAssignedToMe
                              ? Icons.check_circle_rounded
                              : Icons.person_pin_circle_outlined,
                          size: 16,
                          color: _onlyAssignedToMe ? Colors.white : AppColors.primary,
                        ),
                        selectedColor: const Color(0xFF4F46E5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: _onlyAssignedToMe ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (val) =>
                            setState(() => _onlyAssignedToMe = val),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _search = '';
                            _gradeFilter = null;
                            _levelFilter = null;
                            _onlyAssignedToMe = false;
                          });
                        },
                        child: const Text('Filtrlarni tozalash', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // BOLALAR RO'YXATI
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'Mos keluvchi o‘quvchilar topilmadi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Qidiruv so‘zini o‘zgartiring yoki filtrlarni tozalang',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final s = filtered[i];
                final isAssigned = currentUser != null &&
                    (s.assignedSpecialistIds.contains(currentUser.id) ||
                        currentUser.assignedStudentIds.contains(s.id));

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFEEF2FF),
                              child: Text(
                                s.firstName.isNotEmpty ? s.firstName[0] : 'O',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        s.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${s.grade} • ${s.age} yosh',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (isAssigned) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFF059669).withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Text(
                                            'Sizga biriktirilgan',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ehtiyoj: ${s.primaryNeed} • ${s.supportLevel}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Harakatlar
                            Row(
                              children: [
                                IconButton.outlined(
                                  tooltip: 'Kuzatuv qayd etish',
                                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                                  onPressed: () => widget.onSelectStudentForObservation?.call(s),
                                ),
                                const SizedBox(width: 6),
                                IconButton.outlined(
                                  tooltip: 'Diagnostika o‘tkazish',
                                  icon: const Icon(Icons.psychology_outlined, size: 18),
                                  onPressed: () => widget.onSelectStudentForAssessment?.call(s),
                                ),
                                const SizedBox(width: 6),
                                IconButton.outlined(
                                  tooltip: 'Mashg‘ulot rejalashtirish',
                                  icon: const Icon(Icons.alarm_add_rounded, size: 18),
                                  onPressed: () => widget.onSelectStudentForSession?.call(s),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentDetailScreen(
                                          studentId: s.id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Profil', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
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
}
