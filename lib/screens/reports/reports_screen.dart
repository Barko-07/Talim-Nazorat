import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../providers/app_provider.dart';
import '../../services/child_status_service.dart';
import '../../services/dynamics_service.dart';
import '../../services/report_service.dart';
import '../students/student_detail_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _showCsvExportDialog(BuildContext context) {
    final app = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              LucideIcons.fileSpreadsheet,
              color: AppColors.primary,
              size: 21,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Excel / CSV formatida eksport',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Qaysi toifadagi hisobotni eksport qilmoqchisiz? Barcha ma’lumotlar UTF-8 BOM bilan rasmiylashtiriladi (Excel o‘zbekcha harflarni to‘g‘ri ochadi).',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildExportOption(
                  ctx,
                  icon: LucideIcons.users,
                  title: 'O‘quvchilar ro‘yxati (${app.students.length} ta)',
                  onTap: () => _displayCsvPreview(
                    context,
                    'O‘quvchilar_hisoboti.csv',
                    app.exportStudentsCsv(),
                  ),
                ),
                _buildExportOption(
                  ctx,
                  icon: LucideIcons.clipboardCheck,
                  title:
                      'Baholashlar hisoboti (${app.assessments.length} ta)',
                  onTap: () => _displayCsvPreview(
                    context,
                    'Baholashlar_hisoboti.csv',
                    app.exportAssessmentsCsv(),
                  ),
                ),
                _buildExportOption(
                  ctx,
                  icon: LucideIcons.calendarDays,
                  title:
                      'Korreksion darslar va davomat (${app.sessions.length} ta)',
                  onTap: () => _displayCsvPreview(
                    context,
                    'Mashgulotlar_davomat.csv',
                    app.exportSessionsCsv(),
                  ),
                ),
                _buildExportOption(
                  ctx,
                  icon: LucideIcons.bookOpenCheck,
                  title:
                      'ITR rejalari va maqsadlar (${app.iepPlans.length} ta)',
                  onTap: () => _displayCsvPreview(
                    context,
                    'ITR_rejalari.csv',
                    app.exportIepCsv(),
                  ),
                ),
                _buildExportOption(
                  ctx,
                  icon: LucideIcons.shieldAlert,
                  title: 'Monitoring signallari (${app.alerts.length} ta)',
                  onTap: () => _displayCsvPreview(
                    context,
                    'Monitoring_signallari.csv',
                    app.exportAlertsCsv(),
                  ),
                ),
                _buildExportOption(
                  ctx,
                  icon: LucideIcons.arrowLeftRight,
                  title: 'Yo‘naltirishlar jurnali (${app.referrals.length} ta)',
                  onTap: () => _displayCsvPreview(
                    context,
                    'Yonaltirishlar_jurnali.csv',
                    app.exportReferralsCsv(),
                  ),
                ),
                _buildExportOption(
                  ctx,
                  icon: LucideIcons.activity,
                  title: 'Monitoring va Svetofor hisoboti (Oxirgi 30 kun CSV)',
                  onTap: () => _displayCsvPreview(
                    context,
                    'Monitoring_va_Svetofor_hisoboti.csv',
                    app.exportMonitoringReportCsv(),
                  ),
                ),
                _buildExportOption(
                  ctx,
                  icon: LucideIcons.userCheck,
                  title: 'Mutaxassislar faolligi va qamrov jadvali (CSV)',
                  onTap: () => _displayCsvPreview(
                    context,
                    'Mutaxassislar_faolligi.csv',
                    app.exportSpecialistActivityCsv(),
                  ),
                ),
                _buildExportOption(
                  ctx,
                  icon: LucideIcons.databaseBackup,
                  title: 'To‘liq ma’lumotlar bazasi zaxirasi (JSON Backup)',
                  onTap: () => _displayCsvPreview(
                    context,
                    'database_backup.json',
                    app.exportDatabaseBackupJson(),
                  ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SurfaceCard(
        elevated: false,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: AppColors.glassWellFill,
        borderColor: AppColors.glassInnerBorder,
        onTap: () {
          Navigator.pop(ctx);
          onTap();
        },
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textSubtle,
            ),
          ],
        ),
      ),
    );
  }

  void _displayCsvPreview(
    BuildContext context,
    String filename,
    String csvData,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'CSV fayli tayyor: $filename',
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fayl mazmuni muvaffaqiyatli shakllantirildi. Ma’lumotlarni xotiraga nusxalab Excel dasturida ochishingiz mumkin:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              GlassWell(
                borderRadius: 12,
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  height: 220,
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Text(
                      csvData,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        height: 1.4,
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
          FilledButton.icon(
            icon: const Icon(LucideIcons.copy, size: 15),
            label: const Text('Nusxa olish'),
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
              title: 'Tahliliy hisobotlar',
              subtitle:
                  'Pedagogik monitoring bo‘yicha rasmiy ko‘rsatkichlar',
              action: HeaderActionButton(
                icon: LucideIcons.download,
                label: 'CSV / JSON eksport',
                onPressed: () => _showCsvExportDialog(context),
              ),
            ),
            const SizedBox(height: 18),

            // 1. Moslashuvchan statistika kartalari (0% overflow, erkin ikonkalar va kesib olingan shisha)
            ResponsiveGlassGrid(
              mobileColumns: 1,
              tabletColumns: 3,
              desktopColumns: 3,
              spacing: 16,
              children: [
                _buildSummaryStatCard(
                  label: 'Jami ro‘yxatdagi bolalar',
                  value: '${students.length}',
                  caption: report != null
                      ? '${report.childrenWorkedWith} tasi bilan ishlangan • ${report.childrenNotWorkedWith} tasi kutilmoqda'
                      : '100% inklyuziv qamrovda',
                  icon: LucideIcons.users,
                  accent: AppColors.primary,
                ),
                _buildSummaryStatCard(
                  label: 'O‘tkazilgan baholashlar',
                  value: '${assessments.length}',
                  caption: 'Barcha diagnostik yo‘nalishlar',
                  icon: LucideIcons.clipboardCheck,
                  accent: AppColors.info,
                ),
                _buildSummaryStatCard(
                  label: 'Korreksion darslar',
                  value: '${sessions.length}',
                  caption: 'Davomat va kuzatuv nazoratida',
                  icon: LucideIcons.calendarCheck2,
                  accent: AppColors.purple,
                ),
              ],
            ),
            const SizedBox(height: 22),

            if (report != null) ...[
              _buildMonitoringReportSection(report),
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
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.bookOpenCheck,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Individual ta’lim rejalari (ITR) monitoring hisoboti',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (plans.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'ITR rejalari mavjud emas.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    ...plans.map((p) {
                      final progress =
                          (p.averageProgress / 100).clamp(0.0, 1.0);
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
                                builder: (_) => StudentDetailScreen(
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
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

  Widget _buildSummaryStatCard({
    required String label,
    required String value,
    required String caption,
    required IconData icon,
    required Color accent,
  }) {
    return SurfaceCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: accent, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: -0.8,
              height: 1.05,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringReportSection(MonitoringReport report) {
    final redCount = report.statusCounts[StatusColor.red] ?? 0;
    final yellowCount = report.statusCounts[StatusColor.yellow] ?? 0;
    final greenCount = report.statusCounts[StatusColor.green] ?? 0;
    final growthCount = report.dynamicsCounts[DynamicsStatus.growth] ?? 0;
    final stagnantCount = report.dynamicsCounts[DynamicsStatus.stable] ?? 0;
    final declineCount = report.dynamicsCounts[DynamicsStatus.decline] ?? 0;
    final ineffectiveCount =
        report.dynamicsCounts[DynamicsStatus.ineffective] ?? 0;

    return SurfaceCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.activity, size: 20, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Svetofor holati va rivojlanish dinamikasi hisoboti (oxirgi 30 kun)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusPill(
                label: '🔴 Qizil (Ishlanmagan): $redCount ta',
                color: const Color(0xFFDC2626),
                backgroundColor: const Color(0xFFFEE2E2),
              ),
              StatusPill(
                label: '🟡 Sariq (E’tibor talab): $yellowCount ta',
                color: const Color(0xFFD97706),
                backgroundColor: const Color(0xFFFEF3C7),
              ),
              StatusPill(
                label: '🟢 Yashil (Ijobiy natija): $greenCount ta',
                color: const Color(0xFF16A34A),
                backgroundColor: const Color(0xFFDCFCE7),
              ),
              StatusPill(
                label: '📈 O‘sish: $growthCount',
                color: AppColors.success,
              ),
              StatusPill(
                label: '⏸ Barqaror: $stagnantCount',
                color: AppColors.warning,
              ),
              StatusPill(
                label: '📉 Pasayish / Samarasiz: ${declineCount + ineffectiveCount}',
                color: AppColors.error,
              ),
            ],
          ),
          if (report.notWorkedWithNames.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '🔴 Oxirgi 30 kunda hech qanday ish qayd etilmagan o‘quvchilar (${report.notWorkedWithNames.length} nafar): ${report.notWorkedWithNames.join(", ")}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
          ],
        ],
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
          const Row(
            children: [
              Icon(LucideIcons.userCheck, size: 20, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mutaxassislar faolligi va qamrov jadvali',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (report.specialists.isEmpty)
            const Text(
              'Mutaxassislar ma’lumotlari topilmadi.',
              style: TextStyle(color: AppColors.textMuted),
            )
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${sp.role} • Biriktirilgan: ${sp.childrenAssigned} nafar • Ishlangan: ${sp.childrenWorkedWith} nafar • Jami yozuvlar: ${sp.totalRecords} ta',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusPill(
                        label: 'Qamrov: $pct%',
                        color: pct >= 70
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
