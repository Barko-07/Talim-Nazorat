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
    final width = MediaQuery.sizeOf(context).width;
    final mediaPadding = MediaQuery.paddingOf(context);

    final pageBody = ResponsivePageContainer(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptivePageHeader(
            title: 'Kasbiy baholashlar',
            subtitle:
                '${currentRole.label} • ${filtered.length} ta diagnostik qayd',
            action: currentRole.canCreateAssessments
                ? HeaderActionButton(
                    icon: LucideIcons.plus,
                    label: 'Yangi baholash',
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
                    label: 'Ko‘rish rejimi',
                    color: AppColors.textMuted,
                    backgroundColor: Colors.white,
                    borderColor: AppColors.border,
                    icon: LucideIcons.eye,
                  ),
          ),
          const SizedBox(height: 9),

          ModernPillFilterBar(
            items: _categories,
            selectedItem: _selectedCategory,
            onSelected: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 9),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: SurfaceCard(
                      borderRadius: 26,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 36,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.clipboardList,
                            size: 34,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Baholashlar topilmadi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Boshqa yo‘nalishni tanlang yoki yangi baholash kiriting',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      width < 920 ? (84.0 + mediaPadding.bottom) : 24.0,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildAssessmentCard(context, filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Baholashlar')) : null,
      body: canPop ? AmbientMeshBackground(child: pageBody) : pageBody,
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
      borderRadius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(studentId: a.studentId),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 430;

          final scorePill = StatusPill(
            label: '${a.totalScore.toInt()}/${a.maxScore.toInt()} ball',
            color: AppColors.success,
            backgroundColor: AppColors.successBg,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.clipboardCheck,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.25,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${a.studentName} • ${df.format(a.assessmentDate)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            if (isNarrow) scorePill,
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 12),
                    scorePill,
                  ],
                ],
              ),
              const SizedBox(height: 16),
              GlassWell(
                borderRadius: 12,
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.notes,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (a.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              LucideIcons.sparkles,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Tavsiya: ${a.recommendations}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    LucideIcons.userCheck,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${a.specialistName} • ${a.specialistRole}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusPill(
                    label: a.trend,
                    color: trendColor,
                    showDot: true,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
