import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../assessment/assessment_compare_dialog.dart';
import '../assessment/create_assessment_flow.dart';
import '../../../core/widgets/glass_widgets.dart';

class PsychologistDevelopmentMapTab extends StatefulWidget {
  final StudentModel? initialStudent;

  const PsychologistDevelopmentMapTab({super.key, this.initialStudent});

  @override
  State<PsychologistDevelopmentMapTab> createState() =>
      _PsychologistDevelopmentMapTabState();
}

class _PsychologistDevelopmentMapTabState
    extends State<PsychologistDevelopmentMapTab> {
  StudentModel? _selectedStudent;

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.initialStudent;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final students = app.students;
    final df = DateFormat('dd.MM.yyyy');

    if (students.isEmpty) {
      return const Center(
        child: Text('Rivojlanish xaritasi uchun o‘quvchilar mavjud emas.'),
      );
    }

    final currentStudent =
        _selectedStudent != null &&
                students.any((s) => s.id == _selectedStudent!.id)
            ? _selectedStudent!
            : students.first;

    // Ushbu bolaning baholashlari, mashg'ulotlari va kuzatuvlari
    final completedAssessments =
        app.assessments
            .where(
              (a) =>
                  a.studentId == currentStudent.id && a.status == 'completed',
            )
            .toList()
          ..sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));

    final studentSessions =
        app.sessions.where((s) => s.studentId == currentStudent.id).toList();

    final studentObservations =
        app.observations
            .where((o) => o.studentId == currentStudent.id)
            .toList();

    // Haqiqiy ballar dinamikasini hisoblash
    final hasEnoughData = completedAssessments.length >= 2;
    double currentScore = 0.0;
    double baselineScore = 0.0;
    double scoreDiff = 0.0;
    int growthPercent = 0;

    if (completedAssessments.isNotEmpty) {
      currentScore = completedAssessments.first.totalScore;
      if (hasEnoughData) {
        baselineScore = completedAssessments[1].totalScore;
        scoreDiff = currentScore - baselineScore;
        growthPercent =
            baselineScore > 0 ? ((scoreDiff / baselineScore) * 100).round() : 0;
      } else if (completedAssessments.first.previousScore != null) {
        baselineScore = completedAssessments.first.previousScore!;
        scoreDiff = currentScore - baselineScore;
        growthPercent =
            baselineScore > 0 ? ((scoreDiff / baselineScore) * 100).round() : 0;
      }
    }

    // Eng so'nggi baholashning yo'nalishlar bo'yicha ko'rsatkichlari
    final latestAssessment =
        completedAssessments.isNotEmpty ? completedAssessments.first : null;
    final Map<String, double> realDomainScores = {};

    if (latestAssessment != null) {
      if (latestAssessment.domainScores != null &&
          latestAssessment.domainScores!.isNotEmpty) {
        realDomainScores.addAll(latestAssessment.domainScores!);
      } else if (latestAssessment.criteria.isNotEmpty) {
        for (final c in latestAssessment.criteria) {
          final pct = c.maxScore > 0 ? (c.score / c.maxScore) * 100.0 : 0.0;
          realDomainScores[c.criterionName] = pct;
        }
      }
    }

    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width < 600 ? 12.0 : 18.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        MediaQuery.paddingOf(context).top + (width >= 920 ? 82 : 74),
        horizontalPad,
        width < 920 ? (84 + MediaQuery.paddingOf(context).bottom) : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sarlavha va O'quvchini tanlash paneli (Minimalist Glassy Header)
          SurfaceCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: LayoutBuilder(
              builder: (context, c) {
                final isCompact = c.maxWidth < 640;
                final studentSelector = DropdownButtonFormField<StudentModel>(
                  initialValue: currentStudent,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'O‘quvchini tanlang',
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                  items:
                      students
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                '${s.fullName} (${s.grade})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedStudent = v);
                  },
                );

                final headerInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(
                      label: 'Dinamik monitoring',
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                      icon: LucideIcons.chartLine,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bolaning Psixologik Rivojlanish Xaritasi',
                      style: TextStyle(
                        fontSize: isCompact ? 18.5 : 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kuzatuv, diagnostika va korreksiya natijalarining vaqt davomidagi dinamikasi',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      headerInfo,
                      const SizedBox(height: 14),
                      studentSelector,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: headerInfo),
                    const SizedBox(width: 16),
                    SizedBox(width: 280, child: studentSelector),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // BOLANING PROFIL KARTASI
          SurfaceCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, cardConstraints) {
                final isCompact = cardConstraints.maxWidth < 600;

                final avatar = CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    currentStudent.firstName.isNotEmpty
                        ? currentStudent.firstName[0]
                        : 'B',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                );

                final studentInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          currentStudent.fullName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        StatusPill(
                          label:
                              '${currentStudent.grade} sinf • ${currentStudent.age} yosh',
                          color: AppColors.textSecondary,
                          backgroundColor: AppColors.surfaceMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Asosiy ehtiyoj: ${currentStudent.primaryNeed} • Qo‘llab-quvvatlash: ${currentStudent.supportLevel}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Muassasa: ${currentStudent.institutionName}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                );

                final rightAction =
                    completedAssessments.isNotEmpty
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                growthPercent >= 0
                                    ? AppColors.successBg
                                    : AppColors.errorBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  growthPercent >= 0
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${growthPercent >= 0 ? "+" : ""}$growthPercent%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      growthPercent >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              Text(
                                growthPercent >= 0
                                    ? 'Ijobiy o‘sish sur’ati'
                                    : 'Regressiya / Turg‘unlik',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      growthPercent >= 0
                                          ? AppColors.success
                                          : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        )
                        : HeaderActionButton(
                          label: 'Birinchi baholashni boshlash',
                          compactLabel: 'Baholashni boshlash',
                          icon: LucideIcons.listPlus,
                          onPressed:
                              () => CreateAssessmentFlow.start(
                                context,
                                initialStudent: currentStudent,
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
                          Expanded(child: studentInfo),
                        ],
                      ),
                      const SizedBox(height: 14),
                      rightAction,
                    ],
                  );
                }

                return Row(
                  children: [
                    avatar,
                    const SizedBox(width: 18),
                    Expanded(child: studentInfo),
                    const SizedBox(width: 16),
                    rightAction,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // SOHALAR KESIMIDA PSIXOLOGIK RIVOJLANISH KO'RSATKICHLARI
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Sohalar kesimida joriy psixologik ko‘rsatkichlar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (completedAssessments.length >= 2)
                HeaderActionButton(
                  label: 'Oldingi baholash bilan taqqoslash',
                  compactLabel: 'Taqqoslash',
                  icon: LucideIcons.arrowLeftRight,
                  variant: HeaderActionVariant.secondary,
                  onPressed: () {
                    AssessmentCompareDialog.show(
                      context,
                      currentAssessment: completedAssessments.first,
                      studentAssessments: completedAssessments,
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (realDomainScores.isEmpty)
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.chartLine,
                      size: 40,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ushbu o‘quvchida hali rasmiy baholash ma’lumotlari mavjud emas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tizim sun’iy yoki taxminiy ko‘rsatkichlarni yaratmaydi. '
                      'Haqiqiy tahlil uchun bolaga psixologik baholash o‘tkazing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    HeaderActionButton(
                      label: 'Baholash o‘tkazish',
                      icon: LucideIcons.listPlus,
                      onPressed:
                          () => CreateAssessmentFlow.start(
                            context,
                            initialStudent: currentStudent,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                children:
                    realDomainScores.entries.map((e) {
                      final dName = e.key;
                      final pct = e.value;
                      final normalizedVal = (pct / 100.0).clamp(0.0, 1.0);

                      Color color = AppColors.primary;
                      String statusText = 'Me’yoriy o‘sish dinamikasida';

                      if (pct >= 80) {
                        color = AppColors.success;
                        statusText = 'Yuqori o‘zlashtirish va barqarorlik';
                      } else if (pct < 50) {
                        color = AppColors.error;
                        statusText = 'Maxsus korreksion yordam talab etiladi';
                      } else {
                        color = AppColors.info;
                        statusText =
                            'Rivojlanish bosqichida / Qisman mustaqil';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDomainProgressRow(
                          title: dName,
                          value: normalizedVal,
                          percentLabel: '${pct.toStringAsFixed(0)}%',
                          color: color,
                          statusText: statusText,
                        ),
                      );
                    }).toList(),
              ),
            ),
          const SizedBox(height: 20),

          // VAQT DAVOMIDAGI DIAGNOSTIK BAHOLASHLAR VA KUZATUVLAR XRONOLOGIYASI
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 720;

              final historyCard = SurfaceCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.history,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'O‘tkazilgan baholashlar tarixi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (completedAssessments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Ushbu o‘quvchida hali rasmiy baholash o‘tkazilmagan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (
                            int i = 0;
                            i < completedAssessments.length;
                            i++
                          ) ...[
                            if (i > 0) const Divider(height: 16),
                            Builder(
                              builder: (ctx) {
                                final a = completedAssessments[i];
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${df.format(a.assessmentDate)} • ${a.category}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusPill(
                                      label:
                                          '${a.totalScore.toStringAsFixed(1)} ball (${a.percentage.toStringAsFixed(0)}%)',
                                      color: AppColors.primary,
                                      backgroundColor: AppColors.primaryLight,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              );

              final activityCard = SurfaceCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.timeline,
                          size: 20,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Faollik va kuzatuv xulosasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GlassWell(
                            padding: const EdgeInsets.all(14),
                            borderRadius: 12,
                            child: Column(
                              children: [
                                Text(
                                  '${studentSessions.length} ta',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mashg‘ulotlar',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassWell(
                            padding: const EdgeInsets.all(14),
                            borderRadius: 12,
                            child: Column(
                              children: [
                                Text(
                                  '${studentObservations.length} ta',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kuzatuv qaydlari',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        latestAssessment?.notes.isNotEmpty == true
                            ? 'So‘nggi baholash xulosasi: ${latestAssessment!.notes}'
                            : 'Psixologik xulosa: Bolaning rivojlanish ko‘rsatkichlari dinamikasi muntazam monitoring asosida tahlil qilinadi.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    historyCard,
                    const SizedBox(height: 12),
                    activityCard,
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: historyCard),
                    const SizedBox(width: 12),
                    Expanded(child: activityCard),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDomainProgressRow({
    required String title,
    required double value,
    required String percentLabel,
    required Color color,
    required String statusText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              percentLabel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: AppColors.border,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          statusText,
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
