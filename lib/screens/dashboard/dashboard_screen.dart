import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/access_control_service.dart';
import '../../services/child_status_service.dart';
import '../../services/monthly_trend.dart';
import '../assessments/new_assessment_screen.dart';
import '../iep/iep_list_screen.dart';
import '../monitoring/monitoring_screen.dart';
import '../referrals/referrals_screen.dart';
import '../reports/reports_screen.dart';
import '../sessions/sessions_screen.dart';
import '../specialists/specialists_screen.dart';
import '../students/add_student_screen.dart';
import '../students/student_detail_screen.dart';
import '../students/students_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  void _openModule(BuildContext context, int tabIndex, Widget fallbackScreen) {
    if (onNavigateTab != null) {
      onNavigateTab!(tabIndex);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => fallbackScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    final alerts = app.unresolvedAlerts;
    final sessions = app.sessions;
    final assessments = app.assessments;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: ResponsivePageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KESIB OLINGAN SHISHA SALOMLASHUV PANELI
              _buildWelcomeHero(context, user)
                  .animate()
                  .fadeIn(duration: 210.ms, curve: Curves.easeOutCubic)
                  .slideY(
                    begin: 0.025,
                    end: 0,
                    duration: 210.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 10),

              // 2. DIQQAT TALAB HOLATLAR BANNERI (Erkin ikonkali)
              if (alerts.isNotEmpty) ...[
                SurfaceCard(
                  borderRadius: 22,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  backgroundColor: AppColors.warningBg,
                  borderColor: AppColors.warningBorder,
                  onTap:
                      () => _openModule(context, 5, const MonitoringScreen()),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 430;
                      final textCol = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diqqat talab holatlar (${alerts.length} ta)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            alerts.first.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    LucideIcons.triangleAlert,
                                    color: AppColors.warning,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: textCol),
                              ],
                            ),
                            const SizedBox(height: 10),
                            StatusPill(
                              label: 'Monitoringni ko‘rish',
                              color: AppColors.warning,
                              backgroundColor: AppColors.surface,
                              icon: LucideIcons.arrowUpRight,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Icon(
                            LucideIcons.triangleAlert,
                            color: AppColors.warning,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: textCol),
                          const SizedBox(width: 12),
                          StatusPill(
                            label: 'Ko‘rish',
                            color: AppColors.warning,
                            backgroundColor: Colors.white,
                            icon: LucideIcons.arrowUpRight,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // 3. 4 TA ASOSIY KPI KARTALARI (0% overflow ResponsiveGlassGrid + Free-standing icons)
              ResponsiveGlassGrid(
                    mobileColumns: 2,
                    tabletColumns: 2,
                    desktopColumns: 4,
                    spacing: 9,
                    children: [
                      _buildKpiCard(
                        title: 'Jami o‘quvchilar',
                        value: '${app.totalStudentsCount}',
                        subtitle: 'Inklyuziv ro‘yxatda',
                        icon: LucideIcons.users,
                        color: AppColors.primary,
                        onTap:
                            () => _openModule(
                              context,
                              1,
                              const StudentsListScreen(),
                            ),
                      ),
                      _buildKpiCard(
                        title: 'Faol ITR rejalari',
                        value: '${app.activeIepCount}',
                        subtitle: 'Ijro etilayotgan',
                        icon: LucideIcons.bookOpenCheck,
                        color: AppColors.info,
                        onTap:
                            () =>
                                _openModule(context, 4, const IepListScreen()),
                      ),
                      _buildKpiCard(
                        title: 'Bu oygi darslar',
                        value: '${app.thisMonthSessionsCount}',
                        subtitle: 'O‘tkazilgan va rejada',
                        icon: LucideIcons.calendarCheck2,
                        color: AppColors.purple,
                        onTap:
                            () =>
                                _openModule(context, 3, const SessionsScreen()),
                      ),
                      _buildKpiCard(
                        title: 'O‘rtacha o‘sish',
                        value:
                            '${app.averageDevelopmentGrowth >= 0 ? '+' : ''}${app.averageDevelopmentGrowth.toStringAsFixed(1)} ball',
                        subtitle: 'Oldingi baholashlarga nisbatan',
                        icon: LucideIcons.trendingUp,
                        color: AppColors.success,
                        onTap:
                            () =>
                                _openModule(context, 6, const ReportsScreen()),
                      ),
                    ],
                  )
                  .animate()
                  .fadeIn(
                    delay: 40.ms,
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .slideY(
                    begin: 0.02,
                    end: 0,
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 10),

              // 3.5. SVETOFOR VA ISHLANMAGAN BOLALAR NAZORAT PANELI
              _buildSvetoforOverviewStrip(context, app),
              const SizedBox(height: 10),

              // 4. KASBIY ISH MAYDONI
              _buildRoleSpecificWorkspace(context, user),
              const SizedBox(height: 10),

              // 5. GRAFIK: OYLIK RIVOJLANISH DINAMIKASI
              _buildAnalyticsChartCard(app),
              const SizedBox(height: 10),

              // 6. SO'NGGI BAHOLASHLAR VA KUTILAYOTGAN MASHG'ULOTLAR
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 780;

                  final leftCard = _buildRecentAssessmentsCard(
                    context,
                    assessments,
                  );
                  final rightCard = _buildUpcomingSessionsCard(
                    context,
                    sessions,
                  );

                  return isWide
                      ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: leftCard),
                          const SizedBox(width: 10),
                          Expanded(child: rightCard),
                        ],
                      )
                      : Column(
                        children: [
                          leftCard,
                          const SizedBox(height: 10),
                          rightCard,
                        ],
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initialsFor(String? fullName) {
    final cleaned = (fullName ?? '').trim();
    if (cleaned.isEmpty) return 'M';
    final parts =
        cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Widget _buildWelcomeHero(BuildContext context, UserModel? user) {
    final fullName = user?.fullName ?? 'Mutaxassis';
    final roleLabel = user?.role.label ?? 'Mutaxassis';
    final institutionName = user?.institutionName ?? '';
    final initials = _initialsFor(user?.fullName);

    return GlassSurface(
      borderRadius: 26,
      blur: 16,
      opacity: 0.96,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;

            // Bola qo'shish faqat ruxsati bor rollarga (koordinator, rahbariyat)
            final canAddStudent =
                user != null &&
                AccessControlService().canEditStudent(user, null);
            final addBtn = HeaderActionButton(
              icon: LucideIcons.plus,
              label: 'Bola qo‘shish',
              compactLabel: 'Qo‘shish',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddStudentScreen()),
                );
              },
            );

            final monogram = Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.primaryTint, width: 1.0),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
            );

            final userInfo = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    StatusPill(
                      label: roleLabel,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  institutionName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      monogram,
                      const SizedBox(width: 13),
                      Expanded(child: userInfo),
                    ],
                  ),
                  if (canAddStudent) ...[const SizedBox(height: 14), addBtn],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                monogram,
                const SizedBox(width: 15),
                Expanded(child: userInfo),
                if (canAddStudent) ...[const SizedBox(width: 16), addBtn],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSvetoforOverviewStrip(BuildContext context, AppProvider app) {
    final summary = app.monitoringSummary;
    final redCount = summary?.count(StatusColor.red) ?? 0;
    final yellowCount = summary?.count(StatusColor.yellow) ?? 0;
    final greenCount = summary?.count(StatusColor.green) ?? 0;
    final pendingReferrals =
        app.referrals
            .where(
              (r) =>
                  r.status == 'Ko‘rib chiqilmoqda' ||
                  r.status == 'Qabul qilindi',
            )
            .length;

    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.activity,
                size: 19,
                color: AppColors.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Bolalar bilan ishlash holati (Svetofor nazorati)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap:
                    () => _openModule(context, 1, const StudentsListScreen()),
                child: Text(
                  'Ro‘yxatni ochish →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              StatusPill(
                label: '🔴 Ishlanmagan / kechikkan: $redCount nafar',
                color: AppColors.error,
                backgroundColor: AppColors.errorBg,
              ),
              StatusPill(
                label: '🟡 E’tibor talab: $yellowCount nafar',
                color: AppColors.warning,
                backgroundColor: AppColors.warningBg,
              ),
              StatusPill(
                label: '🟢 Ijobiy dinamika: $greenCount nafar',
                color: AppColors.success,
                backgroundColor: AppColors.successBg,
              ),
              StatusPill(
                label: '↗ Faol yo‘naltirishlar: $pendingReferrals ta',
                color: AppColors.info,
                backgroundColor: AppColors.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChartCard(AppProvider app) {
    // Faqat haqiqiy baholashlar: ma'lumot bo'lmasa grafik o'rniga bo'sh holat.
    final points = monthlyAverages(app.assessments, now: DateTime.now());
    final months = [for (final p in points) p.shortLabel];
    final dynamicSpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].percent.roundToDouble()),
    ];

    return SurfaceCard(
      borderRadius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 460;
              final titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oylik rivojlanish dinamikasi',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Yakunlangan baholashlarning oylik o‘rtacha natijasi, %',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              );

              final pill = StatusPill(
                label: 'So‘nggi 6 oy',
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleCol, SizedBox(height: 10), pill],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleCol),
                  SizedBox(width: 12),
                  pill,
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (points.isEmpty)
            GlassWell(
              borderRadius: 12,
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 34),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.chartLine,
                      color: AppColors.textSubtle,
                      size: 26,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Hozircha ma’lumot yo‘q',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Baholashlar yakunlangach, oylik natijalar shu yerda ko‘rinadi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GlassWell(
              borderRadius: 12,
              padding: const EdgeInsets.fromLTRB(10, 20, 26, 12),
              child: SizedBox(
                height: 205,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(10),
                        getTooltipColor: (_) => AppColors.textPrimary,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            final month =
                                (idx >= 0 && idx < months.length)
                                    ? months[idx]
                                    : '';
                            return LineTooltipItem(
                              '$month\n${spot.y.toInt()} ball',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine:
                          (_) => FlLine(
                            color: AppColors.borderSlate.withValues(alpha: 0.7),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          reservedSize: 34,
                          getTitlesWidget:
                              (val, _) => Text(
                                '${val.toInt()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 32,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (val != idx.toDouble()) {
                              return const SizedBox.shrink();
                            }
                            if (idx >= 0 && idx < months.length) {
                              return SideTitleWidget(
                                meta: meta,
                                space: 10,
                                fitInside: SideTitleFitInsideData.fromTitleMeta(
                                  meta,
                                  distanceFromEdge: 0,
                                ),
                                child: Text(
                                  months[idx],
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    // Yarim birlik chekka: bitta nuqta ham, chekka yozuvlar ham sig'adi.
                    minX: -0.5,
                    maxX: months.length - 0.5,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: dynamicSpots,
                        isCurved: true,
                        curveSmoothness: 0.34,
                        color: AppColors.primary,
                        barWidth: 3.2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter:
                              (_, _, _, _) => FlDotCirclePainter(
                                radius: 5,
                                color: Colors.white,
                                strokeWidth: 2.6,
                                strokeColor: AppColors.primary,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.24),
                              AppColors.primary.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentAssessmentsCard(BuildContext context, List assessments) {
    return SurfaceCard(
      borderRadius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'So‘nggi baholashlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (onNavigateTab != null)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onNavigateTab!(2),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Barchasi',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (assessments.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Hozircha baholashlar yo‘q',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            )
          else
            ...assessments.take(3).map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: SurfaceCard(
                  elevated: false,
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  backgroundColor: AppColors.glassWellFill,
                  borderColor: AppColors.glassInnerBorder,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => StudentDetailScreen(studentId: a.studentId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${a.title} • ${a.specialistRole}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        label: '${a.totalScore.toInt()}/${a.maxScore.toInt()}',
                        color: AppColors.success,
                        backgroundColor: Colors.white,
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

  Widget _buildUpcomingSessionsCard(BuildContext context, List sessions) {
    return SurfaceCard(
      borderRadius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kutilayotgan mashg‘ulotlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (onNavigateTab != null)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onNavigateTab!(3),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Jadval',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (sessions.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Rejalashtirilgan darslar yo‘q',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            )
          else
            ...sessions.take(3).map((s) {
              final isDone = s.status == 'Bajarildi';
              final accent = isDone ? AppColors.success : AppColors.info;

              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: SurfaceCard(
                  elevated: false,
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  backgroundColor: AppColors.glassWellFill,
                  borderColor: AppColors.glassInnerBorder,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => StudentDetailScreen(studentId: s.studentId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.topic,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        label: s.status,
                        color: accent,
                        showDot: true,
                        backgroundColor: Colors.white,
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

  Widget _buildRoleSpecificWorkspace(BuildContext context, UserModel? user) {
    final role = user?.role ?? UserRole.psychologist;

    String sectionTitle;
    String sectionSubtitle;
    List<Map<String, dynamic>> actions;

    switch (role) {
      case UserRole.psychologist:
        sectionTitle = 'Amaliyotchi psixolog ish maydoni';
        sectionSubtitle =
            'Kognitiv, hissiy-irodaviy sohalarni baholash va korreksion mashg‘ulotlar';
        actions = [
          {
            'title': 'Yangi baholash (Rubrika)',
            'desc':
                'Bola rivojlanish darajasini standart mezonlar bo‘yicha baholash',
            'icon': LucideIcons.brain,
            'color': AppColors.primary,
            'screen': const NewAssessmentScreen(),
          },
          {
            'title': 'Bolalar ruhiy xaritasi',
            'desc': 'Biriktirilgan inklyuziv bolalar dinamikasi va profili',
            'icon': LucideIcons.users,
            'color': AppColors.info,
            'tabIndex': 1,
            'screen': const StudentsListScreen(),
          },
          {
            'title': 'Korreksion mashg‘ulotlar',
            'desc': 'Yakka va kichik guruhdagi psixologik seanslar jurnali',
            'icon': LucideIcons.calendarDays,
            'color': AppColors.purple,
            'tabIndex': 3,
            'screen': const SessionsScreen(),
          },
        ];
        break;

      case UserRole.speechTherapist:
        sectionTitle = 'Logoped-defektolog ish maydoni';
        sectionSubtitle =
            'Nutq nuqsonlari korreksiyasi, fonematik eshitish va artikulyatsion tahlil';
        actions = [
          {
            'title': 'Nutq diagnostikasi',
            'desc': 'Tovush talaffuzi va fonematik idrokni baholash testi',
            'icon': LucideIcons.mic,
            'color': AppColors.primary,
            'screen': const NewAssessmentScreen(),
          },
          {
            'title': 'Artikulyatsion darslar',
            'desc': 'Rejalashtirilgan logopedik mashg‘ulotlar davomati',
            'icon': LucideIcons.calendarCheck2,
            'color': AppColors.info,
            'tabIndex': 3,
            'screen': const SessionsScreen(),
          },
          {
            'title': 'Logopedik ITR rejalari',
            'desc': 'Individual ta’lim dasturidagi nutqiy maqsadlar ijrosi',
            'icon': LucideIcons.bookOpenCheck,
            'color': AppColors.purple,
            'tabIndex': 4,
            'screen': const IepListScreen(),
          },
        ];
        break;

      case UserRole.specialEducation:
        sectionTitle = 'Maxsus pedagog (Defektolog) ish maydoni';
        sectionSubtitle =
            'Sensor, motorika va aqliy rivojlanishni moslashtirilgan ta’lim bilan qo‘llab-quvvatlash';
        actions = [
          {
            'title': 'Defektologik test',
            'desc': 'Sensomotorik va kognitiv qobiliyatlarni baholash',
            'icon': LucideIcons.puzzle,
            'color': AppColors.primary,
            'screen': const NewAssessmentScreen(),
          },
          {
            'title': 'Yakka tartibdagi dars',
            'desc': 'Maxsus metodik mashg‘ulotlar jadvali va davomat',
            'icon': LucideIcons.calendarDays,
            'color': AppColors.info,
            'tabIndex': 3,
            'screen': const SessionsScreen(),
          },
          {
            'title': 'Moslashtirilgan ITR',
            'desc': 'Bolaga moslashtirilgan o‘quv rejasi va mezonlari',
            'icon': LucideIcons.bookOpenCheck,
            'color': AppColors.purple,
            'tabIndex': 4,
            'screen': const IepListScreen(),
          },
        ];
        break;

      case UserRole.specialEdTeacher:
      case UserRole.teacher:
        sectionTitle = 'Fan o‘qituvchisi / Maxsus pedagog ish maydoni';
        sectionSubtitle =
            'O‘quvchining haqiqiy DTS bilim darajasini aniqlash (masalan: 7-sinf → 3-sinf darajasi), topshiriqlar va dars davomati';
        actions = [
          {
            'title': 'DTS darajasi va fan topshiriqlari',
            'desc':
                'O‘quvchi profilida matematika, o‘qish va ona tili bo‘yicha haqiqiy darajani belgilash',
            'icon': LucideIcons.graduationCap,
            'color': AppColors.primary,
            'tabIndex': 1,
            'screen': const StudentsListScreen(),
          },
          {
            'title': 'Dars davomati va mashg‘ulotlar',
            'desc':
                'Inklyuziv o‘quvchilarning darslardagi ishtiroki va davomati',
            'icon': LucideIcons.clipboardCheck,
            'color': AppColors.info,
            'tabIndex': 3,
            'screen': const SessionsScreen(),
          },
          {
            'title': 'Mutaxassisga yo‘naltirish (Referral)',
            'desc': 'Bolani psixolog, logoped yoki defektologga yo‘naltirish',
            'icon': LucideIcons.arrowLeftRight,
            'color': AppColors.purple,
            'screen': const ReferralsScreen(),
          },
        ];
        break;

      case UserRole.institutionAdmin:
      case UserRole.reviewer:
      case UserRole.superAdmin:
      default:
        sectionTitle = 'Boshqaruv va Monitoring maydoni';
        sectionSubtitle =
            'Muassasa bo‘yicha tahliliy ko‘rsatkichlar, xavflar va mutaxassislar yuklamasi';
        actions = [
          {
            'title': 'Tahliliy hisobotlar',
            'desc':
                'Maktab inklyuziv ta’lim holati, choraklik natijalar va CSV eksport',
            'icon': LucideIcons.chartColumn,
            'color': AppColors.primary,
            'tabIndex': 6,
            'screen': const ReportsScreen(),
          },
          {
            'title': 'Monitoring signallari',
            'desc':
                'Rivojlanish regressiyasi va to‘xtab qolish xavfi ogohlantirishlari',
            'icon': LucideIcons.shieldAlert,
            'color': AppColors.warning,
            'tabIndex': 5,
            'screen': const MonitoringScreen(),
          },
          {
            'title': 'Mutaxassislar shtati',
            'desc': 'Psixolog, logoped va pedagoglar yuklamasi va bolalari',
            'icon': LucideIcons.userCheck,
            'color': AppColors.purple,
            'tabIndex': 7,
            'screen': const SpecialistsScreen(),
          },
        ];
        break;
    }

    return SurfaceCard(
      borderRadius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2.5),
              Text(
                sectionSubtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGlassGrid(
            mobileColumns: 1,
            tabletColumns: 1,
            desktopColumns: 3,
            spacing: 14,
            children:
                actions.map((act) => _buildActionTile(context, act)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, Map<String, dynamic> act) {
    final accent = act['color'] as Color;
    final tabIdx = act['tabIndex'] as int?;

    return SurfaceCard(
      elevated: false,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.glassWellFill,
      borderColor: AppColors.glassInnerBorder,
      onTap: () {
        if (tabIdx != null && onNavigateTab != null) {
          onNavigateTab!(tabIdx);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => act['screen'] as Widget),
          );
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(act['icon'] as IconData, color: accent, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  act['desc'] as String,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textSubtle,
            ),
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
      borderRadius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 21),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.7,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
