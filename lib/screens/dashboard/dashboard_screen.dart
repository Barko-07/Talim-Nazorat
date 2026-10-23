import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../students/add_student_screen.dart';
import '../students/students_list_screen.dart';
import '../monitoring/monitoring_screen.dart';
import '../assessments/new_assessment_screen.dart';
import '../sessions/sessions_screen.dart';
import '../iep/iep_list_screen.dart';
import '../reports/reports_screen.dart';
import '../specialists/specialists_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    final alerts = app.unresolvedAlerts;
    final sessions = app.sessions;
    final assessments = app.assessments;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shaxsiy Mutaxassis Paneli (Welcome Header - Responsive)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 550;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border, width: 1),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      (user?.fullName ?? 'U').substring(0, 1),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
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
                                          'Assalomu alaykum, ${user?.fullName ?? ''}!',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user?.role.label ?? '',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.account_balance_outlined,
                                          size: 14,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            user?.institutionName ?? '5-sonli maktab',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(
                                      Icons.person_add_rounded,
                                      size: 15,
                                    ),
                                    label: const Text(
                                      'Bola qo‘shish',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AddStudentScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  (user?.fullName ?? 'U').substring(0, 1),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assalomu alaykum, ${user?.fullName ?? ''}!',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user?.role.label ?? '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${user?.institutionName ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(
                                  Icons.person_add_rounded,
                                  size: 16,
                                ),
                                label: const Text('Bola qo‘shish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddStudentScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // 1. DIQQAT TALAB HOLATLAR (Agar signal bo'lsa)
            if (alerts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warningBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diqqat talab holatlar (${alerts.length} ta)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alerts.first.message,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MonitoringScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Ko‘rish',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 2. 4 TA ASOSIY KPI KARTALARI
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isWide ? 1.5 : 1.25,
                  children: [
                    _buildKpiCard(
                      title: 'Jami o‘quvchilar',
                      value: '${app.totalStudentsCount}',
                      subtitle: 'Inklyuziv ro‘yxatda',
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primary,
                      bgColor: AppColors.primaryLight,
                    ),
                    _buildKpiCard(
                      title: 'Faol ITR rejalari',
                      value: '${app.activeIepCount}',
                      subtitle: 'Ijro etilayotgan',
                      icon: Icons.assignment_turned_in_rounded,
                      color: AppColors.info,
                      bgColor: AppColors.infoBg,
                    ),
                    _buildKpiCard(
                      title: 'Bu oygi darslar',
                      value: '${app.thisMonthSessionsCount}',
                      subtitle: 'O‘tkazilgan va rejada',
                      icon: Icons.event_available_rounded,
                      color: AppColors.purple,
                      bgColor: AppColors.purpleBg,
                    ),
                    _buildKpiCard(
                      title: 'O‘rtacha o‘sish',
                      value:
                          '+${app.averageDevelopmentGrowth.toStringAsFixed(1)}%',
                      subtitle: 'Oxirgi chorakda',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.success,
                      bgColor: AppColors.successBg,
                    ),
                  ],
                );
              },
            ),
            // 2.5 KASBIY TEZKOR VAZIFALAR VA ISH MAYDONI
            _buildRoleSpecificWorkspace(context, user),
            const SizedBox(height: 24),

            // 3. GRAFIK: OYLIK RIVOJLANISH DINAMIKASI
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                              'Oylik Rivojlanish Dinamikasi (Kuzatuv mezonlari)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Nutq, kognitiv va ijtimoiy sohalar kesimida o‘rtacha ballar',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '2026 o‘quv yili',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 25,
                            getDrawingHorizontalLine: (value) => const FlLine(
                              color: AppColors.borderLight,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 25,
                                reservedSize: 32,
                                getTitlesWidget: (val, meta) => Text(
                                  '${val.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final months = [
                                    'Sentyabr',
                                    'Oktyabr',
                                    'Noyabr',
                                    'Dekabr',
                                  ];
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < months.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        months[idx],
                                        style: const TextStyle(
                                          fontSize: 11,
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
                          minX: 0,
                          maxX: 3,
                          minY: 0,
                          maxY: 100,
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 55),
                                FlSpot(1, 62),
                                FlSpot(2, 70),
                                FlSpot(3, 78),
                              ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. SO'NGGI HARAKATLAR VA O'QUVCHILAR
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;

                final leftCard = Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'So‘nggi baholashlar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (assessments.isEmpty)
                          const Text(
                            'Hozircha baholashlar yo‘q',
                            style: TextStyle(fontSize: 12),
                          )
                        else
                          ...assessments.take(3).map((a) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.assignment,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${a.title} • ${a.specialistRole}',
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
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${a.totalScore.toInt()}/${a.maxScore.toInt()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );

                final rightCard = Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kutilayotgan mashg‘ulotlar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (sessions.isEmpty)
                          const Text(
                            'Rejalashtirilgan darslar yo‘q',
                            style: TextStyle(fontSize: 12),
                          )
                        else
                          ...sessions.take(3).map((s) {
                            final isDone = s.status == 'Bajarildi';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? AppColors.successBg
                                          : AppColors.infoBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isDone
                                          ? Icons.check_circle
                                          : Icons.schedule,
                                      color: isDone
                                          ? AppColors.success
                                          : AppColors.info,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          s.topic,
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
                                  Text(
                                    s.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDone
                                          ? AppColors.success
                                          : AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );

                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: leftCard),
                          const SizedBox(width: 16),
                          Expanded(child: rightCard),
                        ],
                      )
                    : Column(
                        children: [
                          leftCard,
                          const SizedBox(height: 16),
                          rightCard,
                        ],
                      );
              },
            ),
          ],
        ),
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
        sectionSubtitle = 'Kognitiv, hissiy-irodaviy sohalarni baholash va korreksion mashg‘ulotlar';
        actions = [
          {
            'title': 'Yangi baholash (Rubrika)',
            'desc': 'Bola rivojlanish darajasini standart mezonlar bo‘yicha baholash',
            'icon': Icons.psychology_rounded,
            'color': AppColors.primary,
            'screen': const NewAssessmentScreen(),
          },
          {
            'title': 'Bolalar ruhiy xaritasi',
            'desc': 'Biriktirilgan inklyuziv bolalar dinamikasi va profili',
            'icon': Icons.child_care_rounded,
            'color': AppColors.info,
            'screen': const StudentsListScreen(),
          },
          {
            'title': 'Korreksion mashg‘ulotlar',
            'desc': 'Yakka va kichik guruhdagi psixologik seanslar jurnali',
            'icon': Icons.calendar_month_rounded,
            'color': AppColors.purple,
            'screen': const SessionsScreen(),
          },
        ];
        break;

      case UserRole.speechTherapist:
        sectionTitle = 'Logoped-defektolog ish maydoni';
        sectionSubtitle = 'Nutq nuqsonlari korreksiyasi, fonematik eshitish va artikulyatsion tahlil';
        actions = [
          {
            'title': 'Nutq diagnostikasi',
            'desc': 'Tovush talaffuzi va fonematik idrokni baholash testi',
            'icon': Icons.record_voice_over_rounded,
            'color': AppColors.primary,
            'screen': const NewAssessmentScreen(),
          },
          {
            'title': 'Artikulyatsion darslar',
            'desc': 'Rejalashtirilgan logopedik mashg‘ulotlar davomati',
            'icon': Icons.mic_external_on_rounded,
            'color': AppColors.info,
            'screen': const SessionsScreen(),
          },
          {
            'title': 'Logopedik ITR rejalari',
            'desc': 'Individual ta’lim dasturidagi nutqiy maqsadlar ijrosi',
            'icon': Icons.menu_book_rounded,
            'color': AppColors.purple,
            'screen': const IepListScreen(),
          },
        ];
        break;

      case UserRole.specialEducation:
        sectionTitle = 'Maxsus pedagog (Defektolog) ish maydoni';
        sectionSubtitle = 'Sensor, motorika va aqliy rivojlanishni moslashtirilgan ta’lim bilan qo‘llab-quvvatlash';
        actions = [
          {
            'title': 'Defektologik test',
            'desc': 'Sensomotorik va kognitiv qobiliyatlarni baholash',
            'icon': Icons.accessibility_new_rounded,
            'color': AppColors.primary,
            'screen': const NewAssessmentScreen(),
          },
          {
            'title': 'Yakka tartibdagi dars',
            'desc': 'Maxsus metodik mashg‘ulotlar jadvali va davomat',
            'icon': Icons.event_note_rounded,
            'color': AppColors.info,
            'screen': const SessionsScreen(),
          },
          {
            'title': 'Moslashtirilgan ITR',
            'desc': 'Bolaga moslashtirilgan o‘quv rejasi va mezonlari',
            'icon': Icons.auto_stories_rounded,
            'color': AppColors.purple,
            'screen': const IepListScreen(),
          },
        ];
        break;

      case UserRole.teacher:
        sectionTitle = 'Fan o‘qituvchisi / Tyutor ish maydoni';
        sectionSubtitle = 'Sinfdagi inklyuziv muhit, o‘quv dasturini moslashtirish va davomat';
        actions = [
          {
            'title': 'Dars davomati va faollik',
            'desc': 'Inklyuziv o‘quvchilarning umumiy sinfdagi ishtiroki',
            'icon': Icons.fact_check_rounded,
            'color': AppColors.primary,
            'screen': const SessionsScreen(),
          },
          {
            'title': 'O‘quvchilar ro‘yxati',
            'desc': 'Sinfdagi alohida ehtiyojli o‘quvchilar profillari',
            'icon': Icons.groups_rounded,
            'color': AppColors.info,
            'screen': const StudentsListScreen(),
          },
          {
            'title': 'ITR tavsiyalari',
            'desc': 'Mutaxassislar tomonidan tavsiya etilgan dars usullari',
            'icon': Icons.assignment_outlined,
            'color': AppColors.purple,
            'screen': const IepListScreen(),
          },
        ];
        break;

      case UserRole.institutionAdmin:
      case UserRole.reviewer:
      case UserRole.superAdmin:
      default:
        sectionTitle = 'Boshqaruv va Monitoring maydoni';
        sectionSubtitle = 'Muassasa bo‘yicha tahliliy ko‘rsatkichlar, xavflar va mutaxassislar yuklamasi';
        actions = [
          {
            'title': 'Tahliliy hisobotlar',
            'desc': 'Maktab inklyuziv ta’lim holati, choraklik natijalar va CSV eksport',
            'icon': Icons.analytics_rounded,
            'color': AppColors.primary,
            'screen': const ReportsScreen(),
          },
          {
            'title': 'Monitoring signallari',
            'desc': 'Rivojlanish regressiyasi va to‘xtab qolish xavfi ogohlantirishlari',
            'icon': Icons.shield_rounded,
            'color': AppColors.warning,
            'screen': const MonitoringScreen(),
          },
          {
            'title': 'Mutaxassislar shtati',
            'desc': 'Psixolog, logoped va pedagoglar yuklamasi va bolalari',
            'icon': Icons.badge_rounded,
            'color': AppColors.purple,
            'screen': const SpecialistsScreen(),
          },
        ];
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sectionTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        sectionSubtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return isWide
                    ? Row(
                        children: actions.map((act) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _buildActionTile(context, act),
                            ),
                          );
                        }).toList(),
                      )
                    : Column(
                        children: actions.map((act) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildActionTile(context, act),
                          );
                        }).toList(),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, Map<String, dynamic> act) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => act['screen'] as Widget),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (act['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  act['icon'] as IconData,
                  color: act['color'] as Color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      act['desc'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
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
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
