import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../providers/app_provider.dart';
import '../../core/widgets/status_badge.dart';
import '../../services/child_changes.dart';
import '../../services/child_status_service.dart';
import '../../services/dynamics_service.dart';
import '../../services/report_service.dart';
import '../../services/file_download_service.dart';
import '../../services/xlsx_export.dart';
import '../students/student_detail_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _showExcelDialog(BuildContext context) {
    final app = context.read<AppProvider>();
    final options = <(IconData, String, String, String Function())>[
      (LucideIcons.users, 'Bolalar ro‘yxati', 'Bolalar', app.exportStudentsCsv),
      (
        LucideIcons.clipboardCheck,
        'Baholashlar',
        'Baholashlar',
        app.exportAssessmentsCsv,
      ),
      (
        LucideIcons.calendarDays,
        'Darslar va davomat',
        'Darslar',
        app.exportSessionsCsv,
      ),
      (LucideIcons.bookOpenCheck, 'ITR rejalari', 'ITR', app.exportIepCsv),
      (
        LucideIcons.activity,
        'Bolalar holati va o‘zgarish',
        'Holat',
        app.exportMonitoringReportCsv,
      ),
      (
        LucideIcons.shieldAlert,
        'Ogohlantirishlar',
        'Ogohlantirishlar',
        app.exportAlertsCsv,
      ),
      (
        LucideIcons.send,
        'Mutaxassisga yuborishlar',
        'Yuborishlar',
        app.exportReferralsCsv,
      ),
      (
        LucideIcons.userCheck,
        'Mutaxassislar ishi',
        'Mutaxassislar',
        app.exportSpecialistActivityCsv,
      ),
    ];
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excel’ga yuklash'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final o in options)
                      _buildExportOption(
                        ctx,
                        icon: o.$1,
                        title: o.$2,
                        onTap: () => _downloadExcel(context, o.$3, o.$4()),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Yopish'),
              ),
            ],
          ),
    );
  }

  static Widget _buildExportOption(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
            Icon(LucideIcons.download, size: 16, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }

  void _downloadExcel(BuildContext context, String name, String csv) {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final file = '${name}_$date.xlsx';
    downloadBytes(
      file,
      csvToXlsx(csv, sheetName: name),
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Yuklab olindi: $file')));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final students = app.students;
    final assessments = app.assessments;
    final sessions = app.sessions;
    final plans = app.iepPlans;
    final canPop = Navigator.canPop(context);
    MonitoringReport? report;
    try {
      report = app.buildReport();
    } catch (_) {
      report = null;
    }

    final scrollBody = SingleChildScrollView(
      child: ResponsivePageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              art: PageArtKind.reports,
              title: 'Hisobotlar',
              icon: LucideIcons.chartBar,
              subtitle: 'Ko‘rsatkichlar va Excel',
              action: HeaderActionButton(
                icon: LucideIcons.fileSpreadsheet,
                label: 'Excel’ga yuklash',
                onPressed: () => _showExcelDialog(context),
              ),
            ),
            const SizedBox(height: 18),

            // 1. Moslashuvchan statistika kartalari (0% overflow, erkin ikonkalar va kesib olingan shisha)
            ResponsiveGlassGrid(
              mobileColumns: 3,
              tabletColumns: 3,
              desktopColumns: 3,
              spacing: 12,
              children: [
                _buildSummaryStatCard(
                  label: 'Bolalar',
                  value: '${students.length}',
                  caption:
                      report != null
                          ? '${report.childrenWorkedWith} tasi bilan ish qilingan'
                          : '',
                  icon: LucideIcons.users,
                  accent: AppColors.primary,
                ),
                _buildSummaryStatCard(
                  label: 'Baholashlar',
                  value: '${assessments.length}',
                  caption: '',
                  icon: LucideIcons.clipboardCheck,
                  accent: AppColors.info,
                ),
                _buildSummaryStatCard(
                  label: 'Darslar',
                  value: '${sessions.length}',
                  caption: '',
                  icon: LucideIcons.calendarCheck2,
                  accent: AppColors.purple,
                ),
              ],
            ),
            const SizedBox(height: 22),

            if (report != null) ...[
              _buildMonitoringReportSection(
                context,
                report,
                childChanges(assessments),
              ),
              const SizedBox(height: 22),
              _buildSpecialistActivitySection(report),
              const SizedBox(height: 22),
            ],

            // 2. ITR ijrosi jadvali
            SurfaceCard(
              borderRadius: 26,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.bookOpenCheck,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ITR rejalari',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (plans.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'Reja yo‘q',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    ...plans.map((p) {
                      final progress = (p.averageProgress / 100).clamp(
                        0.0,
                        1.0,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SurfaceCard(
                          elevated: false,
                          borderRadius: 12,
                          padding: const EdgeInsets.all(15),
                          backgroundColor: AppColors.glassWellFill,
                          borderColor: AppColors.glassInnerBorder,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => StudentDetailScreen(
                                      studentId: p.studentId,
                                    ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${p.studentName} (${p.studentGrade})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  StatusPill(
                                    label:
                                        '${p.averageProgress.toStringAsFixed(1)}%',
                                    color: AppColors.primary,
                                    backgroundColor: AppColors.primaryLight,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 11),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppColors.border,
                                  color: AppColors.primary,
                                  minHeight: 7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Hisobotlar')) : null,
      body: canPop ? AmbientMeshBackground(child: scrollBody) : scrollBody,
    );
  }

  /// Ikonka, nom, katta raqam: telefonda ham uchtasi bir qatorda sig'adi.
  Widget _buildSummaryStatCard({
    required String label,
    required String value,
    required String caption,
    required IconData icon,
    required Color accent,
  }) {
    return SurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonitoringReportSection(
    BuildContext context,
    MonitoringReport report,
    List<ChildChange> changes,
  ) {
    Widget countRow(Widget label, int n) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          label,
          const Spacer(),
          Text(
            '$n',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    Widget subTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        t,
        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
    );

    final holat = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        subTitle('Holat'),
        for (final c in StatusColor.values)
          countRow(ChildStatusLabel(c), report.statusCounts[c] ?? 0),
      ],
    );
    final ozgarish = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        subTitle('O‘zgarish'),
        countRow(
          const DynamicsLabel(DynamicsStatus.growth),
          report.dynamicsCounts[DynamicsStatus.growth] ?? 0,
        ),
        countRow(
          const DynamicsLabel(DynamicsStatus.stable),
          report.dynamicsCounts[DynamicsStatus.stable] ?? 0,
        ),
        countRow(
          const DynamicsLabel(DynamicsStatus.decline),
          report.dynamicsCounts[DynamicsStatus.decline] ?? 0,
        ),
        countRow(
          const DynamicsLabel(DynamicsStatus.ineffective),
          report.dynamicsCounts[DynamicsStatus.ineffective] ?? 0,
        ),
      ],
    );
    final withChange =
        changes.where((c) => c.percent != null).take(10).toList();

    return SurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bolalar holati va o‘zgarish',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'So‘nggi 30 kun',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder:
                (context, c) =>
                    c.maxWidth < 560
                        ? Column(
                          children: [
                            holat,
                            const SizedBox(height: 16),
                            ozgarish,
                          ],
                        )
                        : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: holat),
                            const SizedBox(width: 32),
                            Expanded(child: ozgarish),
                          ],
                        ),
          ),
          if (withChange.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            subTitle('Bolalar bo‘yicha'),
            for (final ch in withChange) _changeLine(context, ch),
          ],
          if (report.notWorkedWithNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '30 kunda ish qayd etilmagan: ${report.notWorkedWithNames.join(", ")}',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _changeLine(BuildContext context, ChildChange ch) {
    final pct = ch.percent!;
    final st = ch.result.status;
    final color =
        st == DynamicsStatus.growth
            ? const Color(0xFF1F8A55)
            : st == DynamicsStatus.decline
            ? const Color(0xFFD23C41)
            : AppColors.textMuted;
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: ch.last.studentId),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: ch.last.studentName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: '  ·  ${ch.last.category}',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              '${pct >= 0 ? '▲' : '▼'} ${pct.abs().round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistActivitySection(MonitoringReport report) {
    return SurfaceCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.userCheck, size: 20, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mutaxassislar ishi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (report.specialists.isEmpty)
            Text('Ma’lumot yo‘q', style: TextStyle(color: AppColors.textMuted))
          else
            ...report.specialists.map((sp) {
              final pct = (sp.coverage * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  elevated: false,
                  borderRadius: 12,
                  padding: const EdgeInsets.all(14),
                  backgroundColor: AppColors.glassWellFill,
                  borderColor: AppColors.glassInnerBorder,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sp.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${sp.role} · ${sp.childrenWorkedWith} / ${sp.childrenAssigned} bola bilan ishlagan · ${sp.totalRecords} ta yozuv',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (sp.childrenAssigned == 0)
                        Text('—', style: TextStyle(color: AppColors.textMuted))
                      else
                        StatusPill(
                          label: '$pct%',
                          color:
                              pct >= 70
                                  ? AppColors.success
                                  : pct >= 30
                                  ? AppColors.warning
                                  : AppColors.error,
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
