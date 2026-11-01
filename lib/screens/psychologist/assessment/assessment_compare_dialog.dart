import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/assessment_model.dart';

class AssessmentCompareDialog extends StatefulWidget {
  final AssessmentModel currentAssessment;
  final List<AssessmentModel> studentAssessments;

  const AssessmentCompareDialog({
    super.key,
    required this.currentAssessment,
    required this.studentAssessments,
  });

  static Future<void> show(
    BuildContext context, {
    required AssessmentModel currentAssessment,
    required List<AssessmentModel> studentAssessments,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AssessmentCompareDialog(
        currentAssessment: currentAssessment,
        studentAssessments: studentAssessments,
      ),
    );
  }

  @override
  State<AssessmentCompareDialog> createState() =>
      _AssessmentCompareDialogState();
}

class _AssessmentCompareDialogState extends State<AssessmentCompareDialog> {
  late AssessmentModel _assessmentA;
  AssessmentModel? _assessmentB;

  @override
  void initState() {
    super.initState();
    _assessmentA = widget.currentAssessment;

    // Boshqa baholashlar ro'yxatidan eng yaqinini topish
    final others = widget.studentAssessments
        .where((a) => a.id != _assessmentA.id && a.status == 'completed')
        .toList();
    if (others.isNotEmpty) {
      _assessmentB = others.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    final others = widget.studentAssessments
        .where((a) => a.id != _assessmentA.id && a.status == 'completed')
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sarlavha
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baholash Natijalarini Taqqoslash',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Bitta bolaning turli sanalardagi diagnostika natijalari o‘rtasidagi dinamik farq',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              if (others.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.query_builder_rounded,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Taqqoslovchi boshqa yakunlangan baholash mavjud emas',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.currentAssessment.studentName} uchun kamida 2 ta yakunlangan baholash bo‘lishi lozim.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Taqqoslash tanlovi
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'A-Baholash (Asosiy):',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                    Text(
                                      _assessmentA.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${df.format(_assessmentA.assessmentDate)} • ${_assessmentA.percentage.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                size: 28,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Expanded(
                              child: DropdownButtonFormField<AssessmentModel>(
                                value: _assessmentB,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'B-Baholash (Taqqoslanuvchi)',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                                items: others
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a,
                                        child: Text(
                                          '${a.title} (${df.format(a.assessmentDate)})',
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _assessmentB = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        if (_assessmentB != null) ...[
                          _buildScoreComparisonCard(_assessmentA, _assessmentB!),
                          const SizedBox(height: 18),
                          _buildDomainComparisonTable(_assessmentA, _assessmentB!),
                          const SizedBox(height: 18),
                          _buildConclusionsComparison(_assessmentA, _assessmentB!),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreComparisonCard(AssessmentModel a, AssessmentModel b) {
    final diff = a.percentage - b.percentage;
    final isPositive = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreBadge(
            'A Natija',
            '${a.totalScore.toStringAsFixed(1)} / ${a.maxScore.toStringAsFixed(0)}',
            '${a.percentage.toStringAsFixed(0)}%',
            const Color(0xFF4F46E5),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: isPositive
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? "+" : ""}${diff.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isPositive ? 'Ijobiy o‘sish' : 'Pasayish / Regressiya',
                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
          _buildScoreBadge(
            'B Natija',
            '${b.totalScore.toStringAsFixed(1)} / ${b.maxScore.toStringAsFixed(0)}',
            '${b.percentage.toStringAsFixed(0)}%',
            const Color(0xFF0284C7),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(
    String label,
    String points,
    String percent,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          percent,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          points,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDomainComparisonTable(AssessmentModel a, AssessmentModel b) {
    // Ikkala baholashdagi yo'nalishlar
    final allDomains = {
      ...?a.domainScores?.keys,
      ...?b.domainScores?.keys,
    }.toList();

    if (allDomains.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yo‘nalishlar bo‘yicha o‘zgarish dinamikasi:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...allDomains.map((domain) {
              final scoreA = a.domainScores?[domain] ?? 0.0;
              final scoreB = b.domainScores?[domain] ?? 0.0;
              final diff = scoreA - scoreB;
              final isPos = diff >= 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        domain,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'A: ${scoreA.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'B: ${scoreB.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${isPos ? "+" : ""}${diff.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPos
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildConclusionsComparison(AssessmentModel a, AssessmentModel b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Psixolog xulosalari taqqoslashi:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A-Baholash Xulosasi:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.generalConclusion?.isNotEmpty == true
                          ? a.generalConclusion!
                          : a.notes,
                      style: const TextStyle(fontSize: 12),
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
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'B-Baholash Xulosasi:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.generalConclusion?.isNotEmpty == true
                          ? b.generalConclusion!
                          : b.notes,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
