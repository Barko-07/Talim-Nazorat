import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/child_status_service.dart';

class AdminOverviewTab extends StatelessWidget {
  final Function(int) onNavigateTab;

  const AdminOverviewTab({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final df = DateFormat('dd.MM.yyyy HH:mm');

    final totalStudents = app.allStudentsIncludingArchived.length;
    final activeStudents = app.students.length;
    final archivedStudents = totalStudents - activeStudents;
    final specialists = app.specialists;
    final users = app.allUsers;
    final activeUsers = users.where((u) => u.isActive).length;
    final blockedUsers = users.where((u) => !u.isActive).length;
    final alerts = app.alerts;
    final unresolvedAlerts = app.unresolvedAlerts;
    final highAlerts = unresolvedAlerts.where((a) => a.severity == 'XAVF').length;
    final iepPlans = app.iepPlans;
    final activeIep = iepPlans.where((p) => p.status == 'Faol').length;
    final auditLogs = app.auditLogs;
    final institutions = app.institutionsSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DAVLAT AXBOROT TIZIMI BOSH SHAPKA BANNERI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF073A82), Color(0xFF0052CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'YAGONA DAVLAT REYESTRI • HUDUDIY MONITORING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NAMANGAN VILOYATI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'TA’LIM NAZORAT — Boshqaruv Markazi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alohida ta’lim ehtiyojlari bo‘lgan bolalar monitoringi, kadrlar hisobi va muassasalar faoliyati bo‘yicha kompleks ma’muriy tahlil. Administrator: ${user?.fullName ?? 'Boshqaruvchi'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Tizim faol: Oflayn DB',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rollar bo‘yicha himoyalangan tizim',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. ASOSIY STATISTIK KO'RSATKICHLAR (KPI BLOKLARI)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.1,
                children: [
                  _buildStatCard(
                    title: 'JAMI FOYDALANUVCHILAR',
                    value: users.length.toString(),
                    subtitle: '$activeUsers faol • $blockedUsers bloklangan',
                    icon: Icons.manage_accounts_rounded,
                    color: const Color(0xFF0052CC),
                    bgColor: const Color(0xFFEFF6FF),
                    onTap: () => onNavigateTab(1), // Foydalanuvchilar
                  ),
                  _buildStatCard(
                    title: 'PEDAGOG-MUTAXASSISLAR',
                    value: specialists.length.toString(),
                    subtitle: 'Psixolog, logoped, defektolog',
                    icon: Icons.psychology_rounded,
                    color: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF5F3FF),
                    onTap: () => onNavigateTab(2), // Mutaxassislar
                  ),
                  _buildStatCard(
                    title: 'ATEB O‘QUVCHILAR',
                    value: activeStudents.toString(),
                    subtitle: '$totalStudents jami ro‘yxatda • $archivedStudents arxiv',
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                    onTap: () => onNavigateTab(3), // O'quvchilar
                  ),
                  _buildStatCard(
                    title: 'MONITORING SIGNALLARI',
                    value: unresolvedAlerts.length.toString(),
                    subtitle: '$highAlerts ta yuqori xavf • ${alerts.length} jami',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                    onTap: () => onNavigateTab(8), // Monitoring
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1000
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.1,
                children: [
                  _buildStatCard(
                    title: 'TA’LIM MUASSASALARI',
                    value: institutions.length.toString(),
                    subtitle: 'Maktab, internat, tayanch markazlar',
                    icon: Icons.apartment_rounded,
                    color: const Color(0xFF0F766E),
                    bgColor: const Color(0xFFF0FDFA),
                    onTap: () => onNavigateTab(4), // Muassasalar
                  ),
                  _buildStatCard(
                    title: 'SINFLAR VA GURUHLAR',
                    value: app.classesSummary.length.toString(),
                    subtitle: 'Inklyuziv va maxsus sinflar',
                    icon: Icons.school_rounded,
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                    onTap: () => onNavigateTab(5), // Sinflar
                  ),
                  _buildStatCard(
                    title: 'FAOL ITR REJALARI',
                    value: activeIep.toString(),
                    subtitle: '${iepPlans.length} ta umumiy individual reja',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFF0F9FF),
                    onTap: () => onNavigateTab(7), // Hisobotlar
                  ),
                  _buildStatCard(
                    title: 'AUDIT JURNALI',
                    value: auditLogs.length.toString(),
                    subtitle: 'Qayd etilgan o‘zgarishlar va amallar',
                    icon: Icons.history_edu_rounded,
                    color: const Color(0xFF475569),
                    bgColor: const Color(0xFFF8FAFC),
                    onTap: () => onNavigateTab(10), // Audit jurnali
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // 2.5. SVETOFOR VA ISHLANMAGAN BOLALAR NAZORATI
          Builder(
            builder: (context) {
              final summary = app.monitoringSummary;
              final redCount = summary?.count(StatusColor.red) ?? 0;
              final yellowCount = summary?.count(StatusColor.yellow) ?? 0;
              final greenCount = summary?.count(StatusColor.green) ?? 0;
              final unassignedCount = app.students
                  .where((s) => s.assignedSpecialistIds.isEmpty)
                  .length;
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bolalar bilan ishlash holati (Svetofor monitoringi)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => onNavigateTab(3),
                            child: const Text(
                              'O‘quvchilar reyestriga o‘tish →',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _buildBadge(
                            label: '🔴 Qizil (Ishlanmagan / kechikkan): $redCount nafar',
                            color: const Color(0xFFDC2626),
                            bgColor: const Color(0xFFFEE2E2),
                          ),
                          _buildBadge(
                            label: '🟡 Sariq (E’tibor talab): $yellowCount nafar',
                            color: const Color(0xFFD97706),
                            bgColor: const Color(0xFFFEF3C7),
                          ),
                          _buildBadge(
                            label: '🟢 Yashil (Ijobiy natija): $greenCount nafar',
                            color: const Color(0xFF16A34A),
                            bgColor: const Color(0xFFDCFCE7),
                          ),
                          _buildBadge(
                            label: '⚠ Mutaxassis biriktirilmagan: $unassignedCount nafar',
                            color: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFF5F3FF),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. TAQSIMOT VA TEZKOR MA'MURIY BLOKLAR
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CHAP QISM: HUDUDLAR VA MUASSASALAR BO'YICHA TAHLIL
              Expanded(
                flex: 3,
                child: Card(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.account_tree_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Muassasalar bo‘yicha O‘quvchi va Kadrlar Taqsimoti',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => onNavigateTab(4),
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: const Text(
                                'Barchasi',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: institutions.take(5).length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final inst = institutions[index];
                            final stCount = inst['studentsCount'] as int;
                            final spCount = inst['specialistsCount'] as int;
                            final iepCount = inst['activeIepCount'] as int;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          inst['name'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
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
                                  const SizedBox(width: 12),
                                  _buildBadge(
                                    label: '$stCount bola',
                                    color: AppColors.primary,
                                    bgColor: AppColors.primaryLight,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildBadge(
                                    label: '$spCount mutaxassis',
                                    color: const Color(0xFF7C3AED),
                                    bgColor: const Color(0xFFF5F3FF),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildBadge(
                                    label: '$iepCount ITR',
                                    color: const Color(0xFF059669),
                                    bgColor: const Color(0xFFECFDF5),
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
              ),
              const SizedBox(width: 16),

              // O'NG QISM: SO'NGGI AUDIT VA TEZKOR AMALLAR
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // TEZKOR AMALLAR
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
                              'Tezkor Ma’muriy Amallar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildQuickActionBtn(
                              icon: Icons.person_add_rounded,
                              label: 'Yangi foydalanuvchi qo‘shish',
                              color: AppColors.primary,
                              onTap: () => onNavigateTab(1),
                            ),
                            const SizedBox(height: 8),
                            _buildQuickActionBtn(
                              icon: Icons.file_download_outlined,
                              label: 'Viloyat hisobotlarini CSV yuklash',
                              color: const Color(0xFF059669),
                              onTap: () => onNavigateTab(7),
                            ),
                            const SizedBox(height: 8),
                            _buildQuickActionBtn(
                              icon: Icons.shield_outlined,
                              label: 'Monitoring signallarini ko‘rish',
                              color: const Color(0xFFDC2626),
                              onTap: () => onNavigateTab(8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SO'NGGI AUDIT HARAKATLARI
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'So‘nggi Audit Yozuvlari',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => onNavigateTab(10),
                                  child: const Text(
                                    'Barchasi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            if (auditLogs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Audit yozuvlari mavjud emas'),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: auditLogs.take(4).length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final log = auditLogs[i];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                log.action,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                log.userFullName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              df.format(log.timestamp),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          log.details,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 12),
          ],
        ),
      ),
    );
  }
}
