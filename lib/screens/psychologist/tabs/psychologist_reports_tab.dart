import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/app_provider.dart';

class PsychologistReportsTab extends StatefulWidget {
  const PsychologistReportsTab({super.key});

  @override
  State<PsychologistReportsTab> createState() => _PsychologistReportsTabState();
}

class _PsychologistReportsTabState extends State<PsychologistReportsTab> {
  String _selectedPeriod = 'Joriy o‘quv yili (2024-2025)';

  final List<String> _periods = [
    'Joriy o‘quv yili (2024-2025)',
    'I yarim yillik',
    'II yarim yillik',
    'Oxirgi 30 kun',
  ];

  void _showExportPreview(
    BuildContext context, {
    required String title,
    required String filename,
    required String csvData,
  }) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.download, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        filename,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 650,
              height: 380,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.shield,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Hisobot UTF-8 BOM formati bilan tayyorlangan. Excel yoki Google Sheets dasturlarida to‘g‘ridan-to‘g‘ri ochiladi.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          csvData,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.border,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Yopish'),
              ),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.copy, size: 16),
                label: const Text('Nusxa olish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: csvData));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$filename mazmuni xotiraga nusxalandi!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final students = app.students;
    final assessments = app.assessments;
    final sessions = app.sessions;
    final observations = app.observations;

    final completedSessions = sessions.where((s) => s.isCompleted).length;
    final scheduledSessions = sessions.where((s) => s.isScheduled).length;

    // Dinamika hisoblash
    int improvingCount = 0;
    int stableCount = 0;
    int needsAttentionCount = 0;

    for (var a in assessments) {
      if (a.trend == 'Yaxshilanish') improvingCount++;
      if (a.trend == 'Barqaror') stableCount++;
      if (a.trend == 'Qo‘shimcha e’tibor talab') needsAttentionCount++;
    }

    final positiveDynamicsPercent =
        assessments.isNotEmpty
            ? ((improvingCount / assessments.length) * 100).toStringAsFixed(0)
            : '0';

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sarlavha va eksport tugmalari
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.barChart,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Psixologik faoliyat va rivojlanish monitoringi hisobotlari',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Maktab amaliyotchi psixologi faoliyat ko‘rsatkichlari, diagnostika natijalari va bolalar dinamikasi.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Davr tanlagich (aniq kenglik: ro'yxat qatorda o'lchanadi)
                  SizedBox(
                    width: 170,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedPeriod,
                          items:
                              _periods.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPeriod = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Maxfiylik va qonuniylik burchagi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryTint),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.shield,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Maxfiylik: bolalarning psixologik baholash va kuzatuv ma’lumotlari faqat bolaga biriktirilgan '
                      'mutaxassislarga ochiq. Maxfiy kuzatuvlarni faqat psixologlar ko‘radi.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Asosiy statistika kartalari (KPI)
            LayoutBuilder(
              builder: (context, c) {
                // KPI kartalari: telefonda 2 tadan, keng ekranda 4 tasi bir qatorda
                final columns = c.maxWidth >= 760 ? 4 : 2;
                const gap = 14.0;
                final w = (c.maxWidth - gap * (columns - 1)) / columns;
                final cards = [
                  _buildKpiCard(
                    title: 'Psixologik kuzatuvdagi bolalar',
                    value: '${students.length}',
                    subtext: 'Biriktirilgan o‘quvchilar',
                    icon: LucideIcons.users,
                    color: AppColors.primaryDark,
                    bgColor: AppColors.primaryLight,
                  ),
                  _buildKpiCard(
                    title: 'O‘tkazilgan baholashlar',
                    value: '${assessments.length}',
                    subtext: 'Standartlashtirilgan testlar',
                    icon: LucideIcons.clipboardCheck,
                    color: AppColors.brandTeal,
                    bgColor: AppColors.infoBg,
                  ),
                  _buildKpiCard(
                    title: 'Bajarilgan mashg‘ulotlar',
                    value: '$completedSessions',
                    subtext: 'Rejadagilar: $scheduledSessions ta',
                    icon: LucideIcons.brain,
                    color: AppColors.success,
                    bgColor: AppColors.successBg,
                  ),
                  _buildKpiCard(
                    title: 'Ijobiy dinamika ulushi',
                    value: '$positiveDynamicsPercent%',
                    subtext: '$improvingCount ta o‘quvchida o‘sish',
                    icon: LucideIcons.trendingUp,
                    color: AppColors.purple,
                    bgColor: AppColors.purpleBg,
                  ),
                ];
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final card in cards) SizedBox(width: w, child: card),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Dinamika taqsimoti va Eksport bloki (2 ustun)
            LayoutBuilder(
              builder: (context, c) {
                // Telefonda dinamika va eksport bloklari ustma-ust
                final dynamics = Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.chartPie,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Psixologik dinamika taqsimoti',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Yaxshilanish
                      _buildDynamicBar(
                        label: 'Ijobiy o‘sish (Yaxshilanish)',
                        count: improvingCount,
                        total: assessments.isEmpty ? 1 : assessments.length,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 12),

                      // Barqaror
                      _buildDynamicBar(
                        label: 'Barqaror (O‘zgarmagan)',
                        count: stableCount,
                        total: assessments.isEmpty ? 1 : assessments.length,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(height: 12),

                      // Qo'shimcha e'tibor talab
                      _buildDynamicBar(
                        label: 'Qo‘shimcha korreksiya talab etiladi',
                        count: needsAttentionCount,
                        total: assessments.isEmpty ? 1 : assessments.length,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 20),

                      // Qisqacha tahliliy matn
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Kuzatuv davrida jami ${assessments.length} ta psixologik diagnostika va ${observations.length} ta xulq-atvor kuzatuvi amalga oshirildi. '
                          'O‘tkazilgan korreksion mashg‘ulotlar natijasida bolalarning $positiveDynamicsPercent% qismida barqaror va ijobiy o‘sish dinamikasi qayd etildi.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                final exports = Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.download,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Hisobotlarni yuklab olish',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Excel (CSV UTF-8 BOM) formatida rasmiy ma’lumotlarni eksport qilish:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Baholashlar CSV
                      _buildExportButton(
                        title: 'Psixologik baholashlar hisoboti',
                        subtitle: '${assessments.length} ta baholash qaydlari',
                        icon: LucideIcons.fileQuestion,
                        onPressed: () {
                          final csv = app.exportAssessmentsCsv();
                          _showExportPreview(
                            context,
                            title: 'Psixologik baholashlar hisoboti',
                            filename:
                                'psixolog_baholashlar_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
                            csvData: csv,
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Kuzatuv jurnali CSV
                      _buildExportButton(
                        title: 'Kuzatuv jurnali hisoboti',
                        subtitle: '${observations.length} ta kuzatuv qaydlari',
                        icon: LucideIcons.bookOpen,
                        onPressed: () {
                          final csv = app.exportObservationsCsv();
                          _showExportPreview(
                            context,
                            title: 'Psixologik kuzatuvlar jurnali',
                            filename:
                                'psixolog_kuzatuvlar_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
                            csvData: csv,
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Mashg'ulotlar CSV
                      _buildExportButton(
                        title: 'Mashg‘ulotlar va davomat hisoboti',
                        subtitle:
                            '${sessions.length} ta rejalashtirilgan seanslar',
                        icon: LucideIcons.calendarDays,
                        onPressed: () {
                          final csv = app.exportSessionsCsv();
                          _showExportPreview(
                            context,
                            title: 'Psixologik mashg‘ulotlar hisoboti',
                            filename:
                                'psixolog_mashgulotlar_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
                            csvData: csv,
                          );
                        },
                      ),
                    ],
                  ),
                );
                if (c.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [dynamics, const SizedBox(height: 20), exports],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: dynamics),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: exports),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // O'quvchilar kesimida konsolidatsiyalangan psixologik ko'rsatkichlar jadvali
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.table,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'O‘quvchilar kesimida umumiy psixologik ko‘rsatkichlar',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          'Jami: ${students.length} nafar o‘quvchi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (students.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text('Kuzatuv ostida o‘quvchilar mavjud emas.'),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.surfaceMuted,
                        ),
                        headingTextStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        dataTextStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        columns: const [
                          DataColumn(label: Text('O‘quvchi F.I.SH')),
                          DataColumn(label: Text('Sinf')),
                          DataColumn(label: Text('Ehtiyoj toifasi')),
                          DataColumn(label: Text('Baholashlar soni')),
                          DataColumn(label: Text('Mashg‘ulotlar')),
                          DataColumn(label: Text('Kuzatuvlar')),
                          DataColumn(label: Text('Dinamika')),
                        ],
                        rows:
                            students.map((s) {
                              final studentAssessments =
                                  assessments
                                      .where((a) => a.studentId == s.id)
                                      .toList();
                              final studentSessions =
                                  sessions
                                      .where((sess) => sess.studentId == s.id)
                                      .toList();
                              final studentObs =
                                  observations
                                      .where((o) => o.studentId == s.id)
                                      .toList();

                              String trend = 'Barqaror';
                              if (studentAssessments.isNotEmpty) {
                                trend = studentAssessments.first.trend;
                              }

                              Color trendColor = AppColors.primaryDark;
                              if (trend == 'Yaxshilanish') {
                                trendColor = AppColors.success;
                              }
                              if (trend == 'Qo‘shimcha e’tibor talab') {
                                trendColor = AppColors.warning;
                              }

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          child: Text(
                                            s.fullName.isNotEmpty
                                                ? s.fullName[0]
                                                : 'O',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          s.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text('${s.grade}-sinf')),
                                  DataCell(Text(s.primaryNeed)),
                                  DataCell(
                                    Text('${studentAssessments.length} ta'),
                                  ),
                                  DataCell(
                                    Text('${studentSessions.length} ta'),
                                  ),
                                  DataCell(Text('${studentObs.length} ta')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: trendColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: trendColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        trend,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: trendColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final pct = total > 0 ? (count / total) : 0.0;
    final pctStr = (pct * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Flexible(
              child: Text(
                '$count ta ($pctStr%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.surfaceMuted,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
