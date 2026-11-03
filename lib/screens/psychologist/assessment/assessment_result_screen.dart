import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/assessment_templates.dart';
import '../../../models/assessment_model.dart';
import '../../../providers/app_provider.dart';
import '../../../services/question_selection_service.dart';
import '../../referrals/referrals_screen.dart';
import 'assessment_compare_dialog.dart';

class AssessmentResultScreen extends StatelessWidget {
  final AssessmentModel assessment;

  const AssessmentResultScreen({super.key, required this.assessment});

  static void show(BuildContext context, AssessmentModel assessment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentResultScreen(assessment: assessment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy HH:mm');
    final app = context.watch<AppProvider>();
    final studentAssessments =
        app.assessments
            .where((a) => a.studentId == assessment.studentId)
            .toList();
    final comparableAssessments =
        studentAssessments
            .where(
              (candidate) =>
                  candidate.id != assessment.id &&
                  candidate.isCompleted &&
                  QuestionSelectionService().areComparable(
                    assessment,
                    candidate,
                  ),
            )
            .toList();

    final evaluatedResponses =
        assessment.responses.where((r) => r.isEvaluated).toList();
    final skippedResponses =
        assessment.responses.where((r) => !r.isEvaluated).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baholash natijalari'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
        actions: [
          if (comparableAssessments.isNotEmpty)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0062CC)),
              ),
              icon: const Icon(
                Icons.compare_arrows_rounded,
                size: 18,
                color: Color(0xFF0062CC),
              ),
              label: const Text(
                'Taqqoslash',
                style: TextStyle(color: Color(0xFF0062CC)),
              ),
              onPressed: () {
                AssessmentCompareDialog.show(
                  context,
                  currentAssessment: assessment,
                  studentAssessments: studentAssessments,
                );
              },
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BOLANING VA PROTOKOLNING PROFIL KARTASI
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFFEAF3FD),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: Color(0xFF0062CC),
                                size: 30,
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
                                        assessment.studentName,
                                        style: const TextStyle(
                                          fontSize: 18,
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
                                          color: const Color(0xFFEEF9EC),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          assessment.status == 'completed'
                                              ? 'Yakunlangan'
                                              : 'Qoralama',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF12803A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${assessment.title} • ${assessment.category}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'O‘tkazilgan sana: ${df.format(assessment.assessmentDate)} • Mutaxassis: ${assessment.specialistName}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Ball bloki
                            if (assessment.maxScore > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${assessment.percentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0062CC),
                                    ),
                                  ),
                                  Text(
                                    '${assessment.totalScore.toStringAsFixed(1)} / ${assessment.maxScore.toStringAsFixed(0)} ball',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (assessment.previousScore != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF9EC),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        assessment.trend,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF12803A),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(
                              'Jami savollar',
                              '${assessment.responses.length} ta',
                              Icons.quiz_outlined,
                            ),
                            _buildSummaryItem(
                              'Baholandi',
                              '${evaluatedResponses.length} ta',
                              Icons.check_circle_outline,
                            ),
                            _buildSummaryItem(
                              'Baholanmadi (O‘tkazildi)',
                              '${skippedResponses.length} ta',
                              Icons.remove_circle_outline,
                            ),
                            _buildSummaryItem(
                              'Protokol ID',
                              assessment.id.replaceAll('ass_psy_', '#'),
                              Icons.fingerprint,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Baholash xulosasidan yo‘naltirishni boshlash mumkin; qabul
                // qiluvchi xizmatni mutaxassis o‘zi tanlaydi.
                Card(
                  elevation: 0,
                  color: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Natija bo‘yicha psixolog, logoped, maxsus pedagog, ota-ona yoki tibbiyotga yo‘naltirish yarating.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FilledButton.icon(
                            onPressed: () {
                              final supporting = [
                                if (assessment.notes.trim().isNotEmpty)
                                  'Xulosa: ${assessment.notes.trim()}',
                                if (assessment.recommendations
                                    .trim()
                                    .isNotEmpty)
                                  'Tavsiya: ${assessment.recommendations.trim()}',
                              ].join('\n');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ReferralsScreen(
                                        initialStudentId: assessment.studentId,
                                        initialAssessmentId: assessment.id,
                                        initialReason:
                                            '${assessment.title} — ${assessment.category} baholash natijasi bo‘yicha mutaxassis ko‘rigi so‘raladi.',
                                        initialObservations: supporting,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.forward_to_inbox_outlined),
                            label: const Text('Yo‘naltirish'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // YONALISHLAR BO'YICHA TAQSIMOT
                if (assessment.domainScores != null &&
                    assessment.domainScores!.isNotEmpty) ...[
                  const Text(
                    'Baholash Yo‘nalishlari Bo‘yicha Natijalar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children:
                            assessment.domainScores!.entries.map((e) {
                              final domain = e.key;
                              final pct = e.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          domain,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${pct.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0062CC),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (pct / 100.0).clamp(0.0, 1.0),
                                        minHeight: 8,
                                        backgroundColor: const Color(
                                          0xFFE2E8F0,
                                        ),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF0062CC),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Mutaxassisning yakuniy xulosasi va tavsiyalari
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology_alt_outlined,
                              color: Color(0xFF0062CC),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${assessment.specialistRole} xulosasi',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          assessment.generalConclusion?.isNotEmpty == true
                              ? assessment.generalConclusion!
                              : (assessment.notes.isNotEmpty
                                  ? assessment.notes
                                  : 'Xulosa kiritilmagan'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (assessment.recommendations.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Color(0xFF12803A),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Keyingi ish bo‘yicha tavsiyalar:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF12803A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            assessment.recommendations,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0E6630),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (assessment.responses.isNotEmpty) ...[
                  // Savol-javob protokoli
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ishlatilgan Savollar va Javoblar Protokoli',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${assessment.responses.length} ta topshiriq',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...assessment.responses.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final r = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF3FD),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0062CC),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    (r.questionTitle != null &&
                                            r.questionTitle!.isNotEmpty)
                                        ? r.questionTitle!
                                        : r.questionText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                if (!r.isEvaluated)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Text(
                                      'Baholanmadi',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                  )
                                else if (r.questionType != 'open_text')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF9EC),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${(r.score ?? 0.0).toStringAsFixed((r.score ?? 0.0).truncateToDouble() == (r.score ?? 0.0) ? 0 : 1)} / ${(r.maxScore ?? 0.0).toStringAsFixed(0)} ball',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF12803A),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              r.questionText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Javob bloki
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Berilgan javob / Natija: ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      r.answer?.isNotEmpty == true
                                          ? r.answer!
                                          : (r.isEvaluated
                                              ? 'Javob qayd etilgan'
                                              : 'Baholanmadi / O‘tkazib yuborildi'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            r.answer?.isNotEmpty == true
                                                ? AppColors.textPrimary
                                                : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Psixolog kuzatuv izohi
                            if (r.psychologistNotes != null &&
                                r.psychologistNotes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.comment_outlined,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Psixolog kuzatuvi: ${r.psychologistNotes!}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ] else if (assessment.criteria.isNotEmpty) ...[
                  const Text(
                    'Baholangan mezonlar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...assessment.criteria.map((criterion) {
                    final ratio =
                        criterion.maxScore > 0
                            ? (criterion.score / criterion.maxScore).clamp(
                              0.0,
                              1.0,
                            )
                            : 0.0;
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    criterion.criterionName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${criterion.score.toStringAsFixed(1)} / ${criterion.maxScore.toStringAsFixed(1)} ball',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0062CC),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: ratio),
                            if (criterion.notes?.trim().isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Text(
                                criterion.notes!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),

                // Rasmiy ogohlantirish
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: Color(0xFFD97706),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AssessmentTemplates.disclaimerNotice,
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0062CC)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
