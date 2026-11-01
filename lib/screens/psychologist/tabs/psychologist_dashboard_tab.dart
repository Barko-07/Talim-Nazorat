import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/session_model.dart';
import '../../../models/psychologist_observation_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../students/student_detail_screen.dart';

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
    final todaySessions = mySessions.where((s) {
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
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF312E81).withValues(alpha: 0.25),
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
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF818CF8).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF818CF8).withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'MAKTAB PSIXOLOGIK XIZMATI • KASBIY ISH JOYI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Color(0xFFE0E7FF),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            df.format(now),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC7D2FE),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user != null ? 'Xush kelibsiz, ${user.fullName}!' : 'Psixolog ish stoli',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.institutionName ?? "5-sonli umumiy o‘rta ta’lim maktabi"} • Alohida ta’limiy ehtiyojli bolalar bilan psixokorreksiya va monitoring',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE0E7FF),
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
              final cardWidth = isWide
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
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF4F46E5),
                    bgColor: const Color(0xFFEEF2FF),
                    width: cardWidth,
                    onTap: () => onNavigateToTab?.call(1),
                  ),
                  _buildKpiCard(
                    title: 'Bugungi mashg‘ulotlar',
                    value: '${todaySessions.length} ta',
                    subtitle: 'Kun tartibida',
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFF0284C7),
                    bgColor: const Color(0xFFF0F9FF),
                    width: cardWidth,
                    onTap: () => onNavigateToTab?.call(7),
                  ),
                  _buildKpiCard(
                    title: 'Psixologik baholashlar',
                    value: '${myAssessments.length} ta',
                    subtitle: 'Diagnostika xulosalari',
                    icon: Icons.assignment_turned_in_rounded,
                    color: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                    width: cardWidth,
                    onTap: () => onNavigateToTab?.call(2),
                  ),
                  _buildKpiCard(
                    title: 'Kuzatuv daftari',
                    value: '${myObservations.length} ta qayd',
                    subtitle: 'Dinamik o‘zgarishlar',
                    icon: Icons.auto_stories_rounded,
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                    width: cardWidth,
                    onTap: () => onNavigateToTab?.call(3),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. TEZKOR HARAKATLAR PANELI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.flash_on_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tezkor amallar:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: onNewObservation,
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: const Text(
                            '+ Yangi kuzatuv qayd etish',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: onNewAssessment,
                          icon: const Icon(Icons.psychology_outlined, size: 16),
                          label: const Text(
                            'Diagnostika o‘tkazish',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: onNewSession,
                          icon: const Icon(Icons.alarm_add_rounded, size: 16),
                          label: const Text(
                            'Mashg‘ulot rejalashtirish',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () => onNavigateToTab?.call(8),
                          icon: const Icon(Icons.bar_chart_rounded, size: 16),
                          label: const Text(
                            'Hisobotlar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. IKKI USTUNLI BLOK: BUGUNGI MASHG'ULOTLAR VA MUHIM KUZATUVLAR
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              final sessionsBlock = _buildTodaySessionsCard(context, todaySessions, timeFormat);
              final observationsBlock = _buildRecentObservationsCard(context, myObservations, df);

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
          color: Colors.white,
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
                    style: const TextStyle(
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
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
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Bugungi uchrashuv va darslar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => onNavigateToTab?.call(7),
                  child: const Text('Barchasi →', style: TextStyle(fontSize: 12)),
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
                        Icons.event_available_rounded,
                        size: 38,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bugunga rejalashtirilgan mashg‘ulotlar yo‘q',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeFormat.format(s.scheduledAt),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${s.sessionType} • ${s.topic}',
                              style: const TextStyle(
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
                          color: s.isCompleted
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: s.isCompleted
                                ? const Color(0xFF059669)
                                : const Color(0xFF0284C7),
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
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Muhim psixologik kuzatuvlar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
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
                        Icons.notes_rounded,
                        size: 38,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hozircha kuzatuvlar kiritilmagan',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              obs.emotionalState,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        obs.observationText,
                        style: const TextStyle(
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
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${obs.category}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF4F46E5),
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
