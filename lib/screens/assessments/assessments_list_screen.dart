import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/assessment_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import 'new_assessment_screen.dart';

class AssessmentsListScreen extends StatefulWidget {
  const AssessmentsListScreen({super.key});

  @override
  State<AssessmentsListScreen> createState() => _AssessmentsListScreenState();
}

class _AssessmentsListScreenState extends State<AssessmentsListScreen> {
  String? _selectedCategory;

  final List<String> _categories = [
    'Barchasi',
    'Nutq va muloqot',
    'Kognitiv rivojlanish',
    'Sensorika va motorika',
    'Ijtimoiy-hissiy soha',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allAssessments = app.assessments;

    final filtered = _selectedCategory == null || _selectedCategory == 'Barchasi'
        ? allAssessments
        : allAssessments.where((a) => a.category == _selectedCategory).toList();

    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final currentRole = currentUser?.role ?? UserRole.psychologist;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Baholashlar va Diagnostika',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: currentRole.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(currentRole.icon, size: 12, color: currentRole.color),
                                const SizedBox(width: 4),
                                Text(
                                  currentRole.label,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentRole.color),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mutaxassislar tomonidan o‘tkazilgan pedagogik-psixologik monitoring testlari (${filtered.length} ta)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (currentRole.canCreateAssessments)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: currentRole.color),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: Text('Yangi ${currentRole.label} baholashi'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NewAssessmentScreen()),
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_rounded, size: 16, color: AppColors.textMuted),
                        SizedBox(width: 6),
                        Text('Faqat o‘qish rejimi', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Kategoriya chiplari
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = (_selectedCategory ?? 'Barchasi') == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textSecondary)),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      onSelected: (val) {
                        setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Ro'yxat
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.assignment_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('Ushbu toifada baholashlar topilmadi', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final a = filtered[index];
                        return _buildAssessmentCard(context, a);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context, AssessmentModel a) {
    final df = DateFormat('dd.MM.yyyy');
    final trendColor = a.trend == 'O‘sish'
        ? AppColors.success
        : a.trend == 'Pasayish'
            ? AppColors.error
            : AppColors.info;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.assignment_turned_in, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'O‘quvchi: ${a.studentName} • ${df.format(a.assessmentDate)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${a.totalScore.toInt()}/${a.maxScore.toInt()} ball',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xulosa: ${a.notes}', style: const TextStyle(fontSize: 13, height: 1.4)),
                  const SizedBox(height: 4),
                  Text('Tavsiya: ${a.recommendations}', style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Baholovchi: ${a.specialistName} (${a.specialistRole})',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Dinamika: ${a.trend}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: trendColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
