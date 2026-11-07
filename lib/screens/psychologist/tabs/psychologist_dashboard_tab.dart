import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/session_model.dart';
import '../../../models/psychologist_observation_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/glass_widgets.dart';

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

    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width < 600 ? 12.0 : 18.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        MediaQuery.paddingOf(context).top + (width >= 920 ? 82 : 74),
        horizontalPad,
        width < 920 ? (84 + MediaQuery.paddingOf(context).bottom) : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. KESIB OLINGAN SHISHA SALOMLASHUV KARTASI (Minimalist & Glassy)
          SurfaceCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;

                // Tepadagi metadata qatori (Rol va Sana)
                final metaRow = Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: StatusPill(
                        label: 'Maktab psixologi',
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryLight,
                        icon: LucideIcons.brain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 13.5,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          df.format(now),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                // Asosiy ma'lumotlar
                final titleText =
                    user != null
                        ? 'Xush kelibsiz, ${user.fullName}!'
                        : 'Psixolog ish stoli';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    metaRow,
                    const SizedBox(height: 12),
                    Text(
                      titleText,
                      style: TextStyle(
                        fontSize: isCompact ? 18.5 : 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${user?.institutionName ?? "1-sonli umumiy o‘rta ta’lim maktabi"} • Alohida ta’limiy ehtiyojli bolalar bilan psixokorreksiya va monitoring',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 2. ASOSIY 4 TA KPI KARTALARI (Bir xil balandlik va kenglikda)
          ResponsiveGlassGrid(
            mobileColumns: 2,
            tabletColumns: 2,
            desktopColumns: 4,
            spacing: 10,
            children: [
              _buildKpiCard(
                title: 'Biriktirilgan o‘quvchilar',
                value: '${myStudents.length} nafar',
                subtitle: 'Psixologik hisobda',
                icon: LucideIcons.users,
                color: AppColors.primary,
                onTap: () => onNavigateToTab?.call(1),
              ),
              _buildKpiCard(
                title: 'Bugungi mashg‘ulotlar',
                value: '${todaySessions.length} ta',
                subtitle: 'Kun tartibida',
                icon: LucideIcons.calendar,
                color: AppColors.info,
                onTap: () => onNavigateToTab?.call(7),
              ),
              _buildKpiCard(
                title: 'Psixologik baholashlar',
                value: '${myAssessments.length} ta',
                subtitle: 'Diagnostika xulosalari',
                icon: LucideIcons.clipboardCheck,
                color: AppColors.success,
                onTap: () => onNavigateToTab?.call(2),
              ),
              _buildKpiCard(
                title: 'Kuzatuv daftari',
                value: '${myObservations.length} ta qayd',
                subtitle: 'Dinamik o‘zgarishlar',
                icon: LucideIcons.bookOpen,
                color: AppColors.warning,
                onTap: () => onNavigateToTab?.call(3),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. TEZKOR AMALLAR — ilova uslubidagi plitkalar
          Text(
            'Tezkor amallar',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ResponsiveGlassGrid(
            mobileColumns: 2,
            tabletColumns: 2,
            desktopColumns: 4,
            spacing: 10,
            children: [
              _QuickActionTile(
                icon: LucideIcons.notebookPen,
                label: 'Yangi kuzatuv',
                onTap: onNewObservation ?? () => onNavigateToTab?.call(3),
              ),
              _QuickActionTile(
                icon: LucideIcons.brain,
                label: 'Diagnostika',
                onTap: onNewAssessment ?? () => onNavigateToTab?.call(2),
              ),
              _QuickActionTile(
                icon: LucideIcons.calendarCheck,
                label: 'Mashg‘ulot',
                onTap: onNewSession ?? () => onNavigateToTab?.call(7),
              ),
              _QuickActionTile(
                icon: LucideIcons.barChart,
                label: 'Hisobotlar',
                onTap: () => onNavigateToTab?.call(8),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. IKKI USTUNLI BLOK: BUGUNGI MASHG'ULOTLAR VA MUHIM KUZATUVLAR
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 860;

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
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: sessionsBlock),
                      const SizedBox(width: 12),
                      Expanded(child: observationsBlock),
                    ],
                  ),
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    sessionsBlock,
                    const SizedBox(height: 12),
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
    required VoidCallback onTap,
  }) {
    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      onTap: onTap,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                subtitle,
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
        ],
      ),
    );
  }

  Widget _buildTodaySessionsCard(
    BuildContext context,
    List<SessionModel> sessions,
    DateFormat timeFormat,
  ) {
    return SurfaceCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.clock,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bugungi uchrashuv va darslar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
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
                    size: 36,
                    color: AppColors.textSubtle,
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
            Column(
              children: [
                for (int i = 0; i < sessions.length; i++) ...[
                  if (i > 0) const Divider(height: 16),
                  Builder(
                    builder: (ctx) {
                      final s = sessions[i];
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              timeFormat.format(s.scheduledAt),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${s.sessionType} • ${s.topic}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(
                            label: s.status,
                            color:
                                s.isCompleted
                                    ? AppColors.success
                                    : AppColors.info,
                            backgroundColor:
                                s.isCompleted
                                    ? AppColors.successBg
                                    : AppColors.primaryLight,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecentObservationsCard(
    BuildContext context,
    List<PsychologicalObservationModel> observations,
    DateFormat df,
  ) {
    return SurfaceCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.eye, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Muhim psixologik kuzatuvlar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
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
                    size: 36,
                    color: AppColors.textSubtle,
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
            Column(
              children: [
                for (
                  int i = 0;
                  i < (observations.length > 3 ? 3 : observations.length);
                  i++
                ) ...[
                  if (i > 0) const Divider(height: 16),
                  Builder(
                    builder: (ctx) {
                      final obs = observations[i];
                      final isPositive = obs.emotionalState.contains(
                        'Barqaror',
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${obs.studentName} (${obs.studentGrade})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                label: obs.emotionalState,
                                color:
                                    isPositive
                                        ? AppColors.success
                                        : AppColors.warning,
                                backgroundColor:
                                    isPositive
                                        ? AppColors.successBg
                                        : AppColors.warningBg,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            obs.observationText,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
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
                              Expanded(
                                child: Text(
                                  '• ${obs.category}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
        ],
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
    return SurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
