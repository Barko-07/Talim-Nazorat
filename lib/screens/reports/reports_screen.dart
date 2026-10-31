import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../providers/app_provider.dart';
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
                    'Yonalishlar_jurnali.csv',
                    app.exportReferralsCsv(),
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
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
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
                borderRadius: 18,
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

    final scrollBody = SingleChildScrollView(
      child: ResponsivePageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              icon: LucideIcons.chartColumn,
              title: 'Hisobotlar va tahliliy yig‘ma',
              subtitle:
                  'Davlat ta’lim standartlari va pedagogik monitoring bo‘yicha rasmiy ko‘rsatkichlar',
              action: FilledButton.icon(
                icon: const Icon(LucideIcons.download, size: 16),
                label: const Text('CSV Eksport'),
                onPressed: () => _showCsvExportDialog(context),
              ),
            ),
            const SizedBox(height: 22),

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
                  caption: '100% inklyuziv qamrovda',
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

            // 2. ITR ijrosi jadvali
            SurfaceCard(
              borderRadius: 28,
              padding: const EdgeInsets.all(24),
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
                          borderRadius: 20,
                          padding: const EdgeInsets.all(16),
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
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.85),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.85),
                                  color: AppColors.primary,
                                  minHeight: 8.5,
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
      padding: const EdgeInsets.all(22),
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
}
