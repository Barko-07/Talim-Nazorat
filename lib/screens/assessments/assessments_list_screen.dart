import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../services/dynamics_service.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/assessment_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../psychologist/tabs/psychologist_assessments_tab.dart';
import '../students/student_detail_screen.dart';
import 'new_assessment_screen.dart';

/// "Baholash": foydalanuvchining sohasiga mos baholashlar ro'yxati. Yangi
/// baholash shu sohaning mezonlari bilan ochiladi (NewAssessmentScreen).
class AssessmentsListScreen extends StatelessWidget {
  const AssessmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final me = context.watch<AuthProvider>().currentUser;
    final role = me?.role ?? UserRole.psychologist;

    // Psixolog o'z kabinetidagi baholash bo'limida ishlaydi
    if (role == UserRole.psychologist) {
      return const PsychologistAssessmentsTab();
    }

    final items = [...app.assessments]
      ..sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
    final canPop = Navigator.canPop(context);
    final width = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    void openNew() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewAssessmentScreen()),
    );

    final body = ResponsivePageContainer(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptivePageHeader(
            title: 'Baholash',
            icon: LucideIcons.clipboardCheck,
            subtitle: '${items.length} ta',
            action:
                role.canCreateAssessments
                    ? HeaderActionButton(
                      icon: LucideIcons.plus,
                      label: 'Yangi baholash',
                      onPressed: openNew,
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SurfaceCard(
              borderRadius: 20,
              padding: EdgeInsets.zero,
              child:
                  items.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.clipboardList,
                                size: 32,
                                color: AppColors.textSubtle,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hali baholash yo‘q',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Baholashlar shu yerda ko‘rinadi',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListView.separated(
                        padding: EdgeInsets.only(
                          bottom: width < 920 ? 84 + bottomInset : 8,
                        ),
                        itemCount: items.length,
                        separatorBuilder:
                            (_, _) => Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, i) => _AssessmentRow(items[i]),
                      ),
            ),
          ),
          SizedBox(height: width < 920 ? 0 : 16),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Baholash')) : null,
      body: canPop ? AmbientMeshBackground(child: body) : body,
    );
  }
}

class _AssessmentRow extends StatelessWidget {
  final AssessmentModel a;
  const _AssessmentRow(this.a);

  @override
  Widget build(BuildContext context) {
    final pct = a.maxScore > 0 ? (a.totalScore / a.maxScore * 100).round() : 0;
    final dyn = DynamicsIcon.fromTrend(a.trend);
    final dynText =
        dyn == DynamicsStatus.insufficientData ? 'Birinchi' : DynamicsIcon.shortLabel(dyn);
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: a.studentId),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${a.title} · ${DateFormat('dd.MM.yyyy').format(a.assessmentDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DynamicsIcon(dyn, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      dynText,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }
}
