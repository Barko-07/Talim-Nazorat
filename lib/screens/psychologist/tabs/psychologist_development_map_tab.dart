import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../assessment/assessment_compare_dialog.dart';
import '../assessment/create_assessment_flow.dart';

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

    final currentStudent = _selectedStudent != null &&
            students.any((s) => s.id == _selectedStudent!.id)
        ? _selectedStudent!
        : students.first;

    // Ushbu bolaning baholashlari, mashg'ulotlari va kuzatuvlari
    final completedAssessments = app.assessments
        .where((a) => a.studentId == currentStudent.id && a.status == 'completed')
        .toList()
      ..sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));

    final studentSessions = app.sessions
        .where((s) => s.studentId == currentStudent.id)
        .toList();

    final studentObservations = app.observations
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
        growthPercent = baselineScore > 0
            ? ((scoreDiff / baselineScore) * 100).round()
            : 0;
      } else if (completedAssessments.first.previousScore != null) {
        baselineScore = completedAssessments.first.previousScore!;
        scoreDiff = currentScore - baselineScore;
        growthPercent = baselineScore > 0
            ? ((scoreDiff / baselineScore) * 100).round()
            : 0;
      }
    }

    // Eng so'nggi baholashning yo'nalishlar bo'yicha ko'rsatkichlari
    final latestAssessment =
        completedAssessments.isNotEmpty ? completedAssessments.first : null;
    final Map<String, double> realDomainScores = {};

    if (latestAssessment != null) {
      if (latestAssessment.domainScores != null && latestAssessment.domainScores!.isNotEmpty) {
        realDomainScores.addAll(latestAssessment.domainScores!);
      } else if (latestAssessment.criteria.isNotEmpty) {
        for (final c in latestAssessment.criteria) {
          final pct = c.maxScore > 0 ? (c.score / c.maxScore) * 100.0 : 0.0;
          realDomainScores[c.criterionName] = pct;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha va O'quvchini tanlash paneli
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bolaning Psixologik Rivojlanish Xaritasi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kuzatuv, diagnostika va korreksiya natijalarining vaqt davomidagi dinamikasi',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              // O'quvchini tanlash
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<StudentModel>(
                  value: currentStudent,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'O‘quvchini tanlang',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: students
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // BOLANING PROFIL KARTASI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      currentStudent.firstName.isNotEmpty
                          ? currentStudent.firstName[0]
                          : 'B',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              currentStudent.fullName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
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
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${currentStudent.grade} sinf • ${currentStudent.age} yosh',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Asosiy ehtiyoj: ${currentStudent.primaryNeed} • Qo‘llab-quvvatlash: ${currentStudent.supportLevel}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Muassasa: ${currentStudent.institutionName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dinamika xulosasi yoki Baholash chaqiruvi
                  if (completedAssessments.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: growthPercent >= 0
                            ? AppColors.successBg
                            : AppColors.errorBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: growthPercent >= 0
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${growthPercent >= 0 ? "+" : ""}$growthPercent%',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: growthPercent >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          Text(
                            growthPercent >= 0
                                ? 'Ijobiy o‘sish sur’ati'
                                : 'Regressiya / Turg‘unlik',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: growthPercent >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('Birinchi baholashni boshlash'),
                      onPressed: () => CreateAssessmentFlow.start(
                        context,
                        initialStudent: currentStudent,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // SOHALAR KESIMIDA PSIXOLOGIK RIVOJLANISH KO'RSATKICHLARI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                OutlinedButton.icon(
                  icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                  label: const Text('Oldingi baholash bilan taqqoslash'),
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
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 40,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ushbu o‘quvchida hali rasmiy baholash ma’lumotlari mavjud emas',
                    style: TextStyle(
                      fontSize: 14,
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
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 16),
                    label: const Text('Baholash o‘tkazish'),
                    onPressed: () => CreateAssessmentFlow.start(
                      context,
                      initialStudent: currentStudent,
                    ),
                  ),
                ],
              ),
            )
          else
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: realDomainScores.entries.map((e) {
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
                      statusText = 'Rivojlanish bosqichida / Qisman mustaqil';
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
            ),
          const SizedBox(height: 24),

          // VAQT DAVOMIDAGI DIAGNOSTIK BAHOLASHLAR VA KUZATUVLAR XRONOLOGIYASI
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baholashlar tarixi
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'O‘tkazilgan baholashlar tarixi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (completedAssessments.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
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
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: completedAssessments.length,
                            separatorBuilder: (_, _) => const Divider(height: 16),
                            itemBuilder: (ctx, i) {
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${a.totalScore.toStringAsFixed(1)} ball (${a.percentage.toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Kuzatuv va mashg'ulotlar faolligi
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timeline_rounded,
                              size: 20,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Faollik va kuzatuv xulosasi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${studentSessions.length} ta',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Mashg‘ulotlar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${studentObservations.length} ta',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Kuzatuv qaydlari',
                                      style: TextStyle(
                                        fontSize: 11,
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
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.success
                                  .withValues(alpha: 0.2),
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
                  ),
                ),
              ),
            ],
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
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
