import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/access_control_service.dart';
import '../../services/child_status_service.dart';
import '../../services/monthly_trend.dart';
import '../iep/iep_list_screen.dart';
import '../monitoring/monitoring_screen.dart';
import '../reports/reports_screen.dart';
import '../sessions/sessions_screen.dart';
import '../settings/settings_screen.dart';
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
                              fontSize: 13,
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
                            backgroundColor: AppColors.surface,
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
                        title: 'Bolalar',
                        value: '${app.totalStudentsCount}',
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
                        icon: LucideIcons.bookOpenCheck,
                        color: AppColors.info,
                        onTap:
                            () =>
                                _openModule(context, 4, const IepListScreen()),
                      ),
                      _buildKpiCard(
                        title: 'Bu oygi darslar',
                        value: '${app.thisMonthSessionsCount}',
                        icon: LucideIcons.calendarCheck2,
                        color: AppColors.purple,
                        onTap:
                            () =>
                                _openModule(context, 3, const SessionsScreen()),
                      ),
                      _buildKpiCard(
                        title: 'O‘rtacha o‘sish',
                        // Baholash bo'lmasa "+0.0 ball" emas, "—".
                        value:
                            app.assessments.isEmpty
                                ? '—'
                                : '${app.averageDevelopmentGrowth >= 0 ? '+' : ''}${app.averageDevelopmentGrowth.toStringAsFixed(1)} ball',
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

    // Yashil to'lqin — boshqa sahifalar sarlavhasi bilan bir xil uslub.
    return SurfaceCard(
      borderRadius: 26,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned(right: 0, bottom: 0, child: PageHeaderHill()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 560;

                  // Bola qo'shish faqat ruxsati bor rollarga (koordinator, rahbariyat)
                  final canAddStudent =
                      user != null &&
                      AccessControlService().canEditStudent(user, null);
                  final monogram = Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.primaryTint,
                        width: 1.0,
                      ),
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

                  final subStyle = TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  );
                  final userInfo = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xush kelibsiz',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Telefonda rol va maktab alohida qatorda: kesilib qolmaydi.
                      if (isCompact) ...[
                        Text(
                          roleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subStyle,
                        ),
                        if (institutionName.isNotEmpty)
                          Text(
                            institutionName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: subStyle,
                          ),
                      ] else
                        Text(
                          [
                            roleLabel,
                            if (institutionName.isNotEmpty) institutionName,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subStyle,
                        ),
                    ],
                  );

                  // Bola qo'shish — tez-tez kerak bo'ladigan amal, lekin asosiy emas:
                  // ism yonida ixcham ikkinchi darajali tugma.
                  final addCompact = Tooltip(
                    message: 'Bola qo‘shish',
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddStudentScreen(),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.userPlus, size: 18),
                      label: Text(isCompact ? 'Bola' : 'Bola qo‘shish'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Ism va rasm — Sozlamalarga (shaxsiy ma'lumotlar) o'tadi.
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Sozlamalar',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap:
                                () => _openModule(
                                  context,
                                  9,
                                  const SettingsScreen(),
                                ),
                            child: Row(
                              children: [
                                monogram,
                                const SizedBox(width: 14),
                                Expanded(child: userInfo),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (canAddStudent) ...[
                        const SizedBox(width: 12),
                        addCompact,
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSvetoforOverviewStrip(BuildContext context, AppProvider app) {
    final summary = app.monitoringSummary;
    Widget row(StatusColor c) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ChildStatusLabel(c),
          const Spacer(),
          Text(
            '${summary?.count(c) ?? 0}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      onTap: () => _openModule(context, 1, const StudentsListScreen()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bolalar holati',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Hammasi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          row(StatusColor.red),
          row(StatusColor.yellow),
          row(StatusColor.green),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChartCard(AppProvider app) {
    // Faqat haqiqiy baholashlar: ma'lumot bo'lmasa grafik o'rniga bo'sh holat.
    final points = weeklyAverages(app.assessments, now: DateTime.now());
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
                    'Rivojlanish dinamikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              );

              final pill = StatusPill(
                label: 'So‘nggi 1 oy',
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
                      'So‘nggi oyda baholash yo‘q',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
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
                                    fontSize: 12,
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
                    fontSize: 15.5,
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
                        fontSize: 13,
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
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                                fontSize: 14,
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
                        backgroundColor: AppColors.surface,
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
                    fontSize: 15.5,
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
                        fontSize: 13,
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
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                                fontSize: 14,
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
                        backgroundColor: AppColors.surface,
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

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    fontSize: 13,
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
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.7,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
