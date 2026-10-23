import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _showCsvExportDialog(BuildContext context) {
    final app = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Excel / CSV Formatida Eksport',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Qaysi toifadagi hisobotni eksport qilmoqchisiz? Barcha ma’lumotlar UTF-8 BOM bilan rasmiylashtiriladi (Excel o‘zbekcha harflarni to‘g‘ri ochadi).',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              ctx,
              icon: Icons.people_outline_rounded,
              title: 'O‘quvchilar ro‘yxati (${app.students.length} ta)',
              onTap: () => _displayCsvPreview(
                context,
                'O‘quvchilar_hisoboti.csv',
                app.exportStudentsCsv(),
              ),
            ),
            _buildExportOption(
              ctx,
              icon: Icons.assignment_outlined,
              title: 'Baholashlar hisoboti (${app.assessments.length} ta)',
              onTap: () => _displayCsvPreview(
                context,
                'Baholashlar_hisoboti.csv',
                app.exportAssessmentsCsv(),
              ),
            ),
            _buildExportOption(
              ctx,
              icon: Icons.calendar_today_outlined,
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
              icon: Icons.menu_book_outlined,
              title: 'ITR rejalari va maqsadlar (${app.iepPlans.length} ta)',
              onTap: () => _displayCsvPreview(
                context,
                'ITR_rejalari.csv',
                app.exportIepCsv(),
              ),
            ),
            _buildExportOption(
              ctx,
              icon: Icons.shield_outlined,
              title: 'Monitoring signallari (${app.alerts.length} ta)',
              onTap: () => _displayCsvPreview(
                context,
                'Monitoring_signallari.csv',
                app.exportAlertsCsv(),
              ),
            ),
            _buildExportOption(
              ctx,
              icon: Icons.alt_route_rounded,
              title: 'Yo‘naltirishlar jurnali (${app.referrals.length} ta)',
              onTap: () => _displayCsvPreview(
                context,
                'Yonalishlar_jurnali.csv',
                app.exportReferralsCsv(),
              ),
            ),
          ],
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
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
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
          'CSV Fayli Tayyor: $filename',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fayl mazmuni muvaffaqiyatli shakllantirildi. Ma’lumotlarni nusxalab olishingiz yoki Excel dasturida saqlashingiz mumkin:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvData,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
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
            icon: const Icon(Icons.copy_rounded, size: 16),
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

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Hisobotlar va Tahliliy Yig‘ma',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Davlat ta’lim standartlari va pedagogik monitoring bo‘yicha hisobotlar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('CSV Eksport'),
                  onPressed: () => _showCsvExportDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. STATISTIKA KARTALARI
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jami ro‘yxatdagi bolalar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${students.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            '100% inklyuziv qamrov',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'O‘tkazilgan baholashlar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${assessments.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                          const Text(
                            'Barcha yo‘nalishlar',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Korreksion darslar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${sessions.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple,
                            ),
                          ),
                          const Text(
                            'Davomat nazoratida',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. ITR IJROSI JADVALI
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Individual Ta’lim Rejalari (ITR) monitoring hisoboti',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (plans.isEmpty)
                      const Text('ITR rejalari mavjud emas.')
                    else
                      ...plans.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${p.studentName} (${p.studentGrade})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'O‘rtacha ijro: ${p.averageProgress.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: (p.averageProgress / 100).clamp(
                                  0.0,
                                  1.0,
                                ),
                                backgroundColor: AppColors.borderLight,
                                color: AppColors.primary,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
