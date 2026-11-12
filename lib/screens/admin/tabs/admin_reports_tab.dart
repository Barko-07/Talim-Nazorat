import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/app_provider.dart';
import '../../../services/file_download_service.dart';
import '../../../services/xlsx_export.dart';

class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final students = app.students;
    final allStudents = app.allStudentsIncludingArchived;
    final assessments = app.assessments;
    final sessions = app.sessions;
    final iepPlans = app.iepPlans;
    final alerts = app.alerts;
    final institutions = app.institutionsSummary;
    final avgGrowth = app.averageDevelopmentGrowth;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Tahliliy hisobotlar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Muassasalar bo‘yicha ko‘rsatkichlar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. YIG'MA MA'MURIY KO'RSATKICHLAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.cardGlassBorder, width: 1.0),
      ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Davlat Monitoringi Asosiy Ko‘rsatkichlari (KPI)',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols =
                          constraints.maxWidth >= 900
                              ? 4
                              : constraints.maxWidth >= 500
                              ? 2
                              : 1;
                      return GridView.count(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.2,
                        children: [
                          _buildKpiCard(
                            label: 'Faol O‘quvchilar Qamrovi',
                            val: '${students.length} nafar',
                            sub: '${allStudents.length} jami ro‘yxatda',
                            color: AppColors.primary,
                          ),
                          _buildKpiCard(
                            label: 'O‘rtacha Rivojlanish O‘sishi',
                            val:
                                avgGrowth > 0
                                    ? '+${avgGrowth.toStringAsFixed(1)} ball'
                                    : '0.0 ball',
                            sub: '${assessments.length} ta baholash asosida',
                            color: AppColors.success,
                          ),
                          _buildKpiCard(
                            label: 'Korreksion Mashg‘ulotlar',
                            val: '${sessions.length} ta dars',
                            sub:
                                '${sessions.where((s) => s.status == 'Bajarildi').length} ta tasdiqlangan',
                            color: AppColors.purple,
                          ),
                          _buildKpiCard(
                            label: 'Faol ITR Rejalari',
                            val:
                                '${iepPlans.where((p) => p.status == 'Faol').length} ta',
                            sub: '${iepPlans.length} ta jami reja',
                            color: AppColors.warning,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. EXCEL / CSV EKSPORT TUGMALARI BLOKI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.cardGlassBorder, width: 1.0),
      ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.download, color: AppColors.primary),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Excel’ga yuklash',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildExportBtn(
                        context,
                        title: 'Bolalar',
                        subtitle: '${students.length} ta yozuv',
                        icon: LucideIcons.users,
                        color: AppColors.primary,
                        onExport: () => app.exportStudentsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Baholashlar',
                        subtitle: '${assessments.length} ta baholash',
                        icon: LucideIcons.clipboardCheck,
                        color: AppColors.success,
                        onExport: () => app.exportAssessmentsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Darslar',
                        subtitle: '${sessions.length} ta dars',
                        icon: LucideIcons.calendar,
                        color: AppColors.purple,
                        onExport: () => app.exportSessionsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'ITR rejalari',
                        subtitle: '${iepPlans.length} ta reja',
                        icon: LucideIcons.bookOpen,
                        color: AppColors.info,
                        onExport: () => app.exportIepCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Ogohlantirishlar',
                        subtitle: '${alerts.length} ta ogohlantirish',
                        icon: LucideIcons.triangleAlert,
                        color: AppColors.error,
                        onExport: () => app.exportAlertsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Audit jurnali',
                        subtitle: '${app.auditLogs.length} ta yozuv',
                        icon: LucideIcons.scrollText,
                        color: AppColors.textSecondary,
                        onExport: () => app.exportAuditLogsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Bolalar holati va o‘zgarish',
                        subtitle: 'So‘nggi 30 kun',
                        icon: LucideIcons.activity,
                        color: AppColors.info,
                        onExport: () => app.exportMonitoringReportCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Mutaxassislar ishi',
                        subtitle: '${app.specialists.length} nafar',
                        icon: LucideIcons.shieldCheck,
                        color: AppColors.primary,
                        onExport: () => app.exportSpecialistActivityCsv(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. MUASSASALAR BO'YICHA YIG'MA HISOBOT JADVALI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.cardGlassBorder, width: 1.0),
      ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muassasalar',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: institutions.take(8).length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final inst = institutions[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              '${idx + 1}.',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inst['name'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${inst['district']} • ${inst['type']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${inst['studentsCount']} bola',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${inst['specialistsCount']} mutaxassis',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${inst['activeIepCount']} faol ITR',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String val,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(sub, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildExportBtn(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String Function() onExport,
  }) {
    return InkWell(
      onTap: () {
        final now = DateTime.now();
        final name = title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
        final file =
            '${name}_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.xlsx';
        downloadBytes(
          file,
          csvToXlsx(onExport(), sheetName: title),
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Yuklab olindi: $file')));
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
