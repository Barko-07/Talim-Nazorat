import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/app_provider.dart';
import '../../../core/widgets/glass_widgets.dart';

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

    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width < 600 ? 12.0 : 18.0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPad,
          MediaQuery.paddingOf(context).top + (width >= 920 ? 82 : 74),
          horizontalPad,
          width < 920 ? (84 + MediaQuery.paddingOf(context).bottom) : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sarlavha va davr tanlagich (Minimalist Glassy Header)
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: LayoutBuilder(
                builder: (context, c) {
                  final isCompact = c.maxWidth < 640;
                  final periodDropdown = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: isCompact,
                        value: _selectedPeriod,
                        items:
                            _periods.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p,
                                  style: const TextStyle(
                                    fontSize: 12.5,
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
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: StatusPill(
                              label: 'Tahlil va eksport',
                              color: AppColors.primary,
                              backgroundColor: AppColors.primaryLight,
                              icon: LucideIcons.barChart,
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 12),
                            periodDropdown,
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Psixologik faoliyat va rivojlanish monitoringi hisobotlari',
                        style: TextStyle(
                          fontSize: isCompact ? 18.5 : 21,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Maktab amaliyotchi psixologi faoliyat ko‘rsatkichlari, diagnostika natijalari va bolalar dinamikasi.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      if (isCompact) ...[
                        const SizedBox(height: 12),
                        periodDropdown,
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Maxfiylik va qonuniylik burchagi
            GlassWell(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 16,
              tintColor: AppColors.primaryLight.withValues(alpha: 0.65),
              borderColor: AppColors.primaryTint,
              child: Row(
                children: [
                  Icon(
                    LucideIcons.shield,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Maxfiylik: bolalarning psixologik baholash va kuzatuv ma’lumotlari faqat bolaga biriktirilgan '
                      'mutaxassislarga ochiq. Maxfiy kuzatuvlarni faqat psixologlar ko‘radi.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Asosiy statistika kartalari (KPI — bir xil balandlik va kenglikda)
            ResponsiveGlassGrid(
              mobileColumns: 2,
              tabletColumns: 2,
              desktopColumns: 4,
              spacing: 10,
              children: [
                _buildKpiCard(
                  title: 'Psixologik kuzatuvdagi bolalar',
                  value: '${students.length} nafar',
                  subtext: 'Biriktirilgan o‘quvchilar',
                  icon: LucideIcons.users,
                  color: AppColors.primary,
                ),
                _buildKpiCard(
                  title: 'O‘tkazilgan baholashlar',
                  value: '${assessments.length} ta',
                  subtext: 'Standartlashtirilgan testlar',
                  icon: LucideIcons.clipboardCheck,
                  color: AppColors.info,
                ),
                _buildKpiCard(
                  title: 'Bajarilgan mashg‘ulotlar',
                  value: '$completedSessions ta',
                  subtext: 'Rejadagilar: $scheduledSessions ta',
                  icon: LucideIcons.brain,
                  color: AppColors.success,
                ),
                _buildKpiCard(
                  title: 'Ijobiy dinamika ulushi',
                  value: '$positiveDynamicsPercent%',
                  subtext: '$improvingCount ta o‘quvchida o‘sish',
                  icon: LucideIcons.trendingUp,
                  color: AppColors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dinamika taqsimoti va Eksport bloki (2 ustun)
            LayoutBuilder(
              builder: (context, c) {
                final dynamics = SurfaceCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(20),
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
                          const SizedBox(width: 8),
                          Expanded(
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

                      _buildDynamicBar(
                        label: 'Ijobiy o‘sish (Yaxshilanish)',
                        count: improvingCount,
                        total: assessments.isEmpty ? 1 : assessments.length,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 12),

                      _buildDynamicBar(
                        label: 'Barqaror (O‘zgarmagan)',
                        count: stableCount,
                        total: assessments.isEmpty ? 1 : assessments.length,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),

                      _buildDynamicBar(
                        label: 'Qo‘shimcha korreksiya talab etiladi',
                        count: needsAttentionCount,
                        total: assessments.isEmpty ? 1 : assessments.length,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 18),

                      GlassWell(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 12,
                        child: Text(
                          'Kuzatuv davrida jami ${assessments.length} ta psixologik diagnostika va ${observations.length} ta xulq-atvor kuzatuvi amalga oshirildi. '
                          'O‘tkazilgan korreksion mashg‘ulotlar natijasida bolalarning $positiveDynamicsPercent% qismida barqaror va ijobiy o‘sish dinamikasi qayd etildi.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                final exports = SurfaceCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(20),
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
                          const SizedBox(width: 8),
                          Expanded(
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
                    children: [dynamics, const SizedBox(height: 12), exports],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: dynamics),
                      const SizedBox(width: 12),
                      Expanded(child: exports),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // O'quvchilar kesimida konsolidatsiyalangan psixologik ko'rsatkichlar jadvali
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                        ],
                      ),
                      StatusPill(
                        label: 'Jami: ${students.length} nafar',
                        color: AppColors.textSecondary,
                        backgroundColor: AppColors.surfaceMuted,
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

                              Color trendColor = AppColors.primary;
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
                                          backgroundColor:
                                              AppColors.primaryLight,
                                          child: Text(
                                            s.fullName.isNotEmpty
                                                ? s.fullName[0]
                                                : 'O',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
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
                                    StatusPill(
                                      label: trend,
                                      color: trendColor,
                                      backgroundColor: trendColor.withValues(
                                        alpha: 0.1,
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
  }) {
    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w600,
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
            const SizedBox(width: 8),
            Text(
              '$count ta ($pctStr%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
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
    return SurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onPressed,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
