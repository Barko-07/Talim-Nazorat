import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/iep_model.dart';
import '../../models/student_model.dart';

class IepPrintScreen extends StatelessWidget {
  final IndividualEducationPlanModel plan;
  final StudentModel student;

  const IepPrintScreen({super.key, required this.plan, required this.student});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy');
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Rasmiy ITR Blanki (A4)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              icon: const Icon(LucideIcons.printer, size: 16),
              label: Text(
                isMobile ? 'Chop etish' : 'Chop etish (A4)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hujjat printerga yuborildi (A4 formati)'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: AmbientMeshBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 24,
            vertical: isMobile ? 16 : 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 20 : 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.elevatedShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vazirlik va Muassasa
                    const Text(
                      'O‘ZBEKISTON RESPUBLIKASI MAKTABGACHA VA MAKTAB TA’LIMI VAZIRLIGI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.institutionName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1.6, color: Colors.black87),
                    const SizedBox(height: 12),

                    Text(
                      'INDIVIDUAL TA’LIM REJASI (ITR)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plan.academicYear} o‘quv yili uchun',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 1. O'quvchi haqida ma'lumotlar jadvali
                    _buildSectionHeader('1. O‘QUVCHI HAQIDA UMUMIY MA’LUMOT'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'O‘quvchining to‘liq F.I.Sh.:',
                      student.fullName,
                      isMobile,
                    ),
                    _buildInfoRow(
                      'Tug‘ilgan sanasi:',
                      '${df.format(student.dateOfBirth)} (${student.age} yosh)',
                      isMobile,
                    ),
                    _buildInfoRow('Sinfi / Guruhi:', student.grade, isMobile),
                    _buildInfoRow(
                      'Asosiy ta’limiy ehtiyoj:',
                      student.primaryNeed,
                      isMobile,
                    ),
                    _buildInfoRow(
                      'Yordam darajasi:',
                      student.supportLevel,
                      isMobile,
                    ),
                    _buildInfoRow(
                      'Qonuniy vasiysi:',
                      student.guardians.isNotEmpty
                          ? '${student.guardians.first.fullName} (${student.guardians.first.relationship}), Tel: ${student.guardians.first.phone}'
                          : 'Mavjud emas',
                      isMobile,
                    ),
                    const SizedBox(height: 18),

                    // 2. Boshlang'ich daraja
                    _buildSectionHeader(
                      '2. BOSHLANG‘ICH RIVOJLANISH DARAJASI (BASELINE)',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.baselineSummary,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. Uzoq muddatli maqsadlar
                    _buildSectionHeader('3. UZOQ MUDDATLI PEDAGOGIK MAQSADLAR'),
                    const SizedBox(height: 8),
                    Text(
                      plan.longTermGoals,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. Maqsadlar jadvali
                    _buildSectionHeader(
                      '4. REJALASHTIRILGAN O‘LCHANADIGAN MAQSADLAR VA IJRO MEZONLARI',
                    ),
                    const SizedBox(height: 8),
                    Table(
                      border: TableBorder.all(color: Colors.black45),
                      columnWidths: {
                        0: FixedColumnWidth(isMobile ? 24 : 32),
                        1: const FlexColumnWidth(4),
                        2: const FlexColumnWidth(2),
                        3: const FlexColumnWidth(2),
                        4: const FlexColumnWidth(2),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(6),
                              child: Text(
                                '№',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(6),
                              child: Text(
                                'Maqsad mazmuni',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(6),
                              child: Text(
                                'Soha',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(6),
                              child: Text(
                                'Muddat',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(6),
                              child: Text(
                                'Ijro (%)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...List.generate(plan.objectives.length, (idx) {
                          final obj = plan.objectives[idx];
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  '${idx + 1}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  '${obj.title}\n(${obj.successCriteria ?? ''})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  obj.domain,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  df.format(obj.targetDate),
                                  style: const TextStyle(fontSize: 10.5),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  '${obj.progressPercent}% (${obj.status})',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Imzo bloklari (iPhone va Desktop uchun moslashuvchan)
                    const Text(
                      'TASDIQLAYMAN:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 32,
                      runSpacing: 18,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mas’ul o‘qituvchi: ${plan.responsibleTeacherName}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Imzo: ___________________',
                              style: TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sana: ${df.format(DateTime.now())}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maktab direktori / O‘IBDO‘:',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Imzo: ___________________',
                              style: TextStyle(fontSize: 11),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'M.O‘. (Muhr o‘rni)',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ota-ona (Qonuniy vasiy) ITR bilan tanishdi va rozi bo‘ldi: _____________________ (Imzo)',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.4,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
            children: [
              TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 195,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
