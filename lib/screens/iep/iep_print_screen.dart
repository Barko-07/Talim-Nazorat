import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/iep_model.dart';
import '../../models/student_model.dart';
import '../../services/file_download_service.dart';

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
          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primaryDark,
                side: BorderSide(color: AppColors.border, width: 1.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
              ),
              icon: const Icon(LucideIcons.printer, size: 16),
              label: Text(
                isMobile ? 'Chop etish' : 'Chop etish (A4)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                triggerBrowserPrint();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Chop etish darchasi ochildi (A4 formati)'),
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
            horizontal: isMobile ? 16 : 26,
            vertical: isMobile ? 18 : 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 22 : 38),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.0),
                  boxShadow: AppColors.elevatedShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vazirlik va Muassasa
                    Text(
                      'O‘ZBEKISTON RESPUBLIKASI MAKTABGACHA VA MAKTAB TA’LIMI VAZIRLIGI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.institutionName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1.5, color: Colors.black87),
                    const SizedBox(height: 12),

                    Text(
                      'INDIVIDUAL TA’LIM REJASI (ITR)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plan.academicYear} o‘quv yili uchun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 1. O'quvchi haqida ma'lumotlar jadvali
                    _buildSectionHeader('1. O‘QUVCHI HAQIDA UMUMIY MA’LUMOT'),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 20),

                    // 2. Boshlang'ich daraja
                    _buildSectionHeader(
                      '2. BOSHLANG‘ICH RIVOJLANISH DARAJASI (BASELINE)',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.baselineSummary,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Uzoq muddatli maqsadlar
                    _buildSectionHeader('3. UZOQ MUDDATLI PEDAGOGIK MAQSADLAR'),
                    const SizedBox(height: 8),
                    Text(
                      plan.longTermGoals,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Maqsadlar jadvali (Mobilda matn ustundan chiqib ketmasligi uchun moslashuvchan)
                    _buildSectionHeader(
                      '4. REJALASHTIRILGAN O‘LCHANADIGAN MAQSADLAR VA IJRO MEZONLARI',
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final table = _buildObjectivesTable(df);
                        if (constraints.maxWidth < 500) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(width: 520, child: table),
                          );
                        }
                        return table;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Imzo bloklari (iPhone va Desktop uchun moslashuvchan)
                    const Text(
                      'TASDIQLAYMAN:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                    Text(
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

  Widget _buildObjectivesTable(DateFormat df) {
    return Table(
      border: TableBorder.all(color: Colors.black45),
      columnWidths: const {
        0: FixedColumnWidth(32),
        1: FlexColumnWidth(4),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppColors.surfaceMuted),
          children: [
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(
                '№',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(
                'Maqsad mazmuni',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(
                'Soha',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(
                'Muddat',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(
                'Ijro (%)',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),
          ],
        ),
        ...List.generate(plan.objectives.length, (idx) {
          final obj = plan.objectives[idx];
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(7),
                child: Text(
                  '${idx + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(7),
                child: Text(
                  '${obj.title}\n(${obj.successCriteria ?? ''})',
                  style: const TextStyle(fontSize: 11, height: 1.35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(7),
                child: Text(obj.domain, style: const TextStyle(fontSize: 11)),
              ),
              Padding(
                padding: const EdgeInsets.all(7),
                child: Text(
                  df.format(obj.targetDate),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(7),
                child: Text(
                  '${obj.progressPercent}% (${obj.status})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.glassWellFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.85),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.4,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 195,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
