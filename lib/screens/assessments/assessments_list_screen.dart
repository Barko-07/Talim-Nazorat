import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/assessment_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../students/student_detail_screen.dart';
import 'new_assessment_screen.dart';

class AssessmentsListScreen extends StatefulWidget {
  const AssessmentsListScreen({super.key});

  @override
  State<AssessmentsListScreen> createState() => _AssessmentsListScreenState();
}

class _AssessmentsListScreenState extends State<AssessmentsListScreen> {
  String _selectedCategory = 'Barchasi';

  static const List<String> _categories = [
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

    final filtered = _selectedCategory == 'Barchasi'
        ? allAssessments
        : allAssessments
            .where((a) => a.category == _selectedCategory)
            .toList();

    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final currentRole = currentUser?.role ?? UserRole.psychologist;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Baholashlar')) : null,
      body: ResponsivePageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              icon: LucideIcons.clipboardCheck,
              title: 'Kasbiy baholashlar jurnali',
              subtitle:
                  '${currentRole.label} • Jami ${filtered.length} ta diagnostik monitoring qaydi',
              action: currentRole.canCreateAssessments
                  ? FilledButton.icon(
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Yangi baholash'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NewAssessmentScreen(),
                          ),
                        );
                      },
                    )
                  : const StatusPill(
                      label: 'Faqat ko‘rish rejimi',
                      color: AppColors.textMuted,
                      backgroundColor: Colors.white,
                      icon: LucideIcons.eye,
                    ),
            ),
            const SizedBox(height: 16),

            ModernPillFilterBar(
              items: _categories,
              selectedItem: _selectedCategory,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.hairlineBorder),
                            ),
                            child: const Icon(
                              LucideIcons.clipboardList,
                              size: 26,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Baholashlar topilmadi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Boshqa yo‘nalishni tanlang yoki yangi baholash kiriting',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildAssessmentCard(context, filtered[index]);
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

    return SurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(studentId: a.studentId),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  LucideIcons.clipboardCheck,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${a.studentName} • ${df.format(a.assessmentDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: '${a.totalScore.toInt()}/${a.maxScore.toInt()} ball',
                color: AppColors.success,
                backgroundColor: AppColors.successBg,
                borderColor: AppColors.successBorder,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.hairlineBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.notes,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (a.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          LucideIcons.sparkles,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tavsiya: ${a.recommendations}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                LucideIcons.userCheck,
                size: 13.5,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${a.specialistName} • ${a.specialistRole}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: a.trend,
                color: trendColor,
                showDot: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
