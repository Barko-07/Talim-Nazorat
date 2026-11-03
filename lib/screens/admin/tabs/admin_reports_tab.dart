import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/app_provider.dart';

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tizim Faoliyati va Davlat Hisobotlari',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F7F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00808A).withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          'RFC 4180 CSV / Excel Standarti',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00808A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Namangan viloyati maktabgacha va maktab ta’limi muassasalari bo‘yicha umumlashtirilgan pedagogik-statistik tahlillar',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. YIG'MA MA'MURIY KO'RSATKICHLAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Davlat Monitoringi Asosiy Ko‘rsatkichlari (KPI)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth >= 900
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
                            val: avgGrowth > 0
                                ? '+${avgGrowth.toStringAsFixed(1)} ball'
                                : '0.0 ball',
                            sub: '${assessments.length} ta baholash asosida',
                            color: const Color(0xFF12803A),
                          ),
                          _buildKpiCard(
                            label: 'Korreksion Mashg‘ulotlar',
                            val: '${sessions.length} ta dars',
                            sub:
                                '${sessions.where((s) => s.status == 'Bajarildi').length} ta tasdiqlangan',
                            color: const Color(0xFF7C3AED),
                          ),
                          _buildKpiCard(
                            label: 'Faol ITR Rejalari',
                            val:
                                '${iepPlans.where((p) => p.status == 'Faol').length} ta',
                            sub: '${iepPlans.length} ta jami reja',
                            color: const Color(0xFFD97706),
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
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.download_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Rasmiy CSV / Excel Eksport Fayllari (UTF-8 BOM)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Barcha ma’lumotlar davlat hisobotlari talablariga mos RFC 4180 formati hamda o‘zbekcha maxsus harflar (o‘, g‘, sh, ch) buzilmasligi uchun UTF-8 BOM bilan shakllantiriladi.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildExportBtn(
                        context,
                        title: 'O‘quvchilar reyestri CSV',
                        subtitle: '${students.length} ta yozuv',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.primary,
                        onExport: () => app.exportStudentsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Baholashlar dinamikasi CSV',
                        subtitle: '${assessments.length} ta baholash',
                        icon: Icons.assignment_turned_in_rounded,
                        color: const Color(0xFF12803A),
                        onExport: () => app.exportAssessmentsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Korreksion mashg‘ulotlar CSV',
                        subtitle: '${sessions.length} ta sessiya',
                        icon: Icons.calendar_today_rounded,
                        color: const Color(0xFF7C3AED),
                        onExport: () => app.exportSessionsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Individual ta’lim rejalari (ITR) CSV',
                        subtitle: '${iepPlans.length} ta reja',
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF00808A),
                        onExport: () => app.exportIepCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Monitoring signallari CSV',
                        subtitle: '${alerts.length} ta ogohlantirish',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFDC2626),
                        onExport: () => app.exportAlertsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Audit jurnali to‘liq CSV',
                        subtitle: '${app.auditLogs.length} ta yozuv',
                        icon: Icons.history_edu_rounded,
                        color: const Color(0xFF475569),
                        onExport: () => app.exportAuditLogsCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Svetofor va Dinamika hisoboti CSV',
                        subtitle: 'Oxirgi 30 kunlik monitoring',
                        icon: Icons.traffic_rounded,
                        color: const Color(0xFF0F766E),
                        onExport: () => app.exportMonitoringReportCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'Mutaxassislar faolligi CSV',
                        subtitle: '${app.specialists.length} nafar kadr qamrovi',
                        icon: Icons.verified_user_rounded,
                        color: const Color(0xFF0062CC),
                        onExport: () => app.exportSpecialistActivityCsv(),
                      ),
                      _buildExportBtn(
                        context,
                        title: 'To‘liq ma’lumotlar bazasi (JSON Backup)',
                        subtitle: '18 ta jadval zaxira nusxasi',
                        icon: Icons.storage_rounded,
                        color: const Color(0xFF1A2A4D),
                        onExport: () => app.exportDatabaseBackupJson(),
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
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Muassasalar Faoliyati Konsolidatsiyasi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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
                                    style: const TextStyle(
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${inst['specialistsCount']} mutaxassis',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${inst['activeIepCount']} faol ITR',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF12803A),
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
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
        final csv = onExport();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fayl muvaffaqiyatli tayyorlandi (RFC 4180 UTF-8 BOM). Quyida dastlabki qatorlar ko‘rinishi:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      csv.split('\n').take(6).join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title muvaffaqiyatli yuklab olindi.'),
                      backgroundColor: const Color(0xFF12803A),
                    ),
                  );
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Yuklab olish'),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
