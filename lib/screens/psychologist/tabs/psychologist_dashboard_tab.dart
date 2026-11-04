import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/session_model.dart';
import '../../../models/psychologist_observation_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';

class PsychologistDashboardTab extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;
  final VoidCallback? onNewObservation;
  final VoidCallback? onNewAssessment;
  final VoidCallback? onNewSession;

  const PsychologistDashboardTab({
    super.key,
    this.onNavigateToTab,
    this.onNewObservation,
    this.onNewAssessment,
    this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser;
    final df = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm');

    final myStudents = app.students;
    final mySessions = app.sessions;
    final myAssessments = app.assessments;
    final myObservations = app.observations;

    // Bugungi mashg'ulotlar
    final now = DateTime.now();
    final todaySessions =
        mySessions.where((s) {
          return s.scheduledAt.year == now.year &&
              s.scheduledAt.month == now.month &&
              s.scheduledAt.day == now.day;
        }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. DAVLAT STANDARTI DAVLAT GERBI BILAN PSIXOLOG BANNERI
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.25),
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
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.brain,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                ),
                              ),
                              child: Text(
                                'MAKTAB PSIXOLOGIK XIZMATI',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            df.format(now),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user != null
                            ? 'Xush kelibsiz, ${user.fullName}!'
                            : 'Psixolog ish stoli',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.institutionName ?? "5-sonli umumiy o‘rta ta’lim maktabi"} • Alohida ta’limiy ehtiyojli bolalar bilan psixokorreksiya va monitoring',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 2. ASOSIY 4 TA KPI KARTALARI
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final cardWidth =
                  isWide
                      ? (constraints.maxWidth - 36) / 4
                      : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildKpiCard(
                    title: 'Biriktirilgan o‘quvchilar',
                    value: '${myStudents.length} nafar',
                    subtitle: 'Psixologik hisobda',
                    icon: LucideIcons.users,
                    color: AppColors.primary,
                    bgColor: AppColors.primaryLight,
                    width: cardWidth,
                    onTap: () => onNavigateToTab?.call(1),
                  ),
                  _buildKpiCard(
                    title: 'Bugungi mashg‘ulotlar',
                    value: '${todaySessions.length} ta',
                    subtitle: 'Kun tartibida',
                    icon: LucideIcons.calendar,
                    color: AppColors.info,
                    bgColor: AppColors.infoBg,
                    width: cardWidth,
                    onTap: () => onNavigateToTab?.call(7),
                  ),
                  _buildKpiCard(
                    title: 'Psixologik baholashlar',
                    value: '${myAssessments.length} ta',
                    subtitle: 'Diagnostika xulosalari',
                    icon: LucideIcons.clipboardCheck,
                    color: AppColors.success,
                    bgColor: AppColors.successBg,
                    width: cardWidth,
                    onTap: () => onNavigateToTab?.call(2),
                  ),
                  _buildKpiCard(
                    title: 'Kuzatuv daftari',
                    value: '${myObservations.length} ta qayd',
                    subtitle: 'Dinamik o‘zgarishlar',
                    icon: LucideIcons.bookOpen,
                    color: AppColors.warning,
                    bgColor: AppColors.warningBg,
                    width: cardWidth,
                    onTap: () => onNavigateToTab?.call(3),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. TEZKOR AMALLAR — ilova uslubidagi plitkalar
          Text(
            'Tezkor amallar',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              const gap = 12.0;
              final tileWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              final actions = [
                (
                  LucideIcons.notebookPen,
                  'Yangi kuzatuv',
                  onNewObservation ?? () => onNavigateToTab?.call(3),
                ),
                (
                  LucideIcons.brain,
                  'Diagnostika',
                  onNewAssessment ?? () => onNavigateToTab?.call(2),
                ),
                (
                  LucideIcons.calendarCheck,
                  'Mashg‘ulot',
                  onNewSession ?? () => onNavigateToTab?.call(7),
                ),
                (
                  LucideIcons.barChart,
                  'Hisobotlar',
                  () => onNavigateToTab?.call(8),
                ),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (icon, label, onTap) in actions)
                    SizedBox(
                      width: tileWidth,
                      child: _QuickActionTile(
                        icon: icon,
                        label: label,
                        onTap: onTap,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 4. IKKI USTUNLI BLOK: BUGUNGI MASHG'ULOTLAR VA MUHIM KUZATUVLAR
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              final sessionsBlock = _buildTodaySessionsCard(
                context,
                todaySessions,
                timeFormat,
              );
              final observationsBlock = _buildRecentObservationsCard(
                context,
                myObservations,
                df,
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: sessionsBlock),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: observationsBlock),
                  ],
                );
              } else {
                return Column(
                  children: [
                    sessionsBlock,
                    const SizedBox(height: 16),
                    observationsBlock,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double width,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
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
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
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

  Widget _buildTodaySessionsCard(
    BuildContext context,
    List<SessionModel> sessions,
    DateFormat timeFormat,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Bugungi uchrashuv va darslar',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateToTab?.call(7),
                  child: const Text(
                    'Barchasi →',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.calendarCheck,
                      size: 38,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bugunga rejalashtirilgan mashg‘ulotlar yo‘q',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (ctx, i) {
                  final s = sessions[i];
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeFormat.format(s.scheduledAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.studentName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${s.sessionType} • ${s.topic}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              s.isCompleted
                                  ? AppColors.successBg
                                  : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                s.isCompleted
                                    ? AppColors.success
                                    : AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentObservationsCard(
    BuildContext context,
    List<PsychologicalObservationModel> observations,
    DateFormat df,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(LucideIcons.eye, color: AppColors.warning, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Muhim psixologik kuzatuvlar',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateToTab?.call(3),
                  child: const Text('Jurnal →', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (observations.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.notebookText,
                      size: 38,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hozircha kuzatuvlar kiritilmagan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: observations.length > 3 ? 3 : observations.length,
                separatorBuilder: (_, _) => const Divider(height: 14),
                itemBuilder: (ctx, i) {
                  final obs = observations[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${obs.studentName} (${obs.studentGrade})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              obs.emotionalState,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        obs.observationText,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            df.format(obs.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${obs.category}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Tezkor amal plitkasi: chapda matn, o'ngda chiziqli ikona (davlat xizmatlari
/// ilovalaridagi "sohalar" plitkalari uslubida).
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 26, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
