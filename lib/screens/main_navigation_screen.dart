import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/widgets/glass_widgets.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import 'assessments/assessments_list_screen.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'iep/iep_list_screen.dart';
import 'monitoring/monitoring_screen.dart';
import 'referrals/referrals_screen.dart';
import 'reports/reports_screen.dart';
import 'sessions/sessions_screen.dart';
import 'settings/settings_screen.dart';
import 'specialists/specialists_screen.dart';
import 'students/student_detail_screen.dart';
import 'students/students_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _NavItemData {
  final int index;
  final String title;
  final String shortLabel;
  final String group;
  final IconData icon;

  const _NavItemData({
    required this.index,
    required this.title,
    required this.shortLabel,
    required this.group,
    required this.icon,
  });
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  static const List<_NavItemData> _navItems = [
    _NavItemData(
      index: 0,
      title: 'Boshqaruv markazi',
      shortLabel: 'Boshqaruv',
      group: 'ASOSIY ISH MAYDONI',
      icon: LucideIcons.layoutDashboard,
    ),
    _NavItemData(
      index: 1,
      title: 'Bolalar bazasi',
      shortLabel: 'Bolalar',
      group: 'ASOSIY ISH MAYDONI',
      icon: LucideIcons.users,
    ),
    _NavItemData(
      index: 2,
      title: 'Baholashlar',
      shortLabel: 'Baholash',
      group: 'ASOSIY ISH MAYDONI',
      icon: LucideIcons.clipboardCheck,
    ),
    _NavItemData(
      index: 3,
      title: 'Mashg‘ulotlar',
      shortLabel: 'Mashg‘ulot',
      group: 'ASOSIY ISH MAYDONI',
      icon: LucideIcons.calendarDays,
    ),
    _NavItemData(
      index: 4,
      title: 'ITR rejalari',
      shortLabel: 'ITR',
      group: 'REJA VA NAZORAT',
      icon: LucideIcons.bookOpenCheck,
    ),
    _NavItemData(
      index: 5,
      title: 'Monitoring',
      shortLabel: 'Monitoring',
      group: 'REJA VA NAZORAT',
      icon: LucideIcons.shieldAlert,
    ),
    _NavItemData(
      index: 6,
      title: 'Hisobotlar',
      shortLabel: 'Hisobotlar',
      group: 'BOSHQARUV VA TIZIM',
      icon: LucideIcons.chartColumn,
    ),
    _NavItemData(
      index: 7,
      title: 'Mutaxassislar',
      shortLabel: 'Kadrlar',
      group: 'BOSHQARUV VA TIZIM',
      icon: LucideIcons.userCheck,
    ),
    _NavItemData(
      index: 8,
      title: 'Yo‘naltirishlar',
      shortLabel: 'Yo‘naltirish',
      group: 'REJA VA NAZORAT',
      icon: LucideIcons.arrowLeftRight,
    ),
    _NavItemData(
      index: 9,
      title: 'Sozlamalar',
      shortLabel: 'Sozlamalar',
      group: 'BOSHQARUV VA TIZIM',
      icon: LucideIcons.settings,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    if (app.currentUser?.id != auth.currentUser?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        app.setCurrentUser(auth.currentUser);
      });
    }
  }

  void _selectTab(int index) {
    if (index >= 0 && index < 10 && _selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildActiveScreen() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          key: const ValueKey('tab_0'),
          onNavigateTab: _selectTab,
        );
      case 1:
        return const StudentsListScreen(key: ValueKey('tab_1'));
      case 2:
        return const AssessmentsListScreen(key: ValueKey('tab_2'));
      case 3:
        return const SessionsScreen(key: ValueKey('tab_3'));
      case 4:
        return const IepListScreen(key: ValueKey('tab_4'));
      case 5:
        return const MonitoringScreen(key: ValueKey('tab_5'));
      case 6:
        return const ReportsScreen(key: ValueKey('tab_6'));
      case 7:
        return const SpecialistsScreen(key: ValueKey('tab_7'));
      case 8:
        return const ReferralsScreen(key: ValueKey('tab_8'));
      case 9:
        return const SettingsScreen(key: ValueKey('tab_9'));
      default:
        return DashboardScreen(
          key: const ValueKey('tab_default'),
          onNavigateTab: _selectTab,
        );
    }
  }

  int? _badgeForIndex(int index, AppProvider app) {
    if (index == 1 && app.students.isNotEmpty) {
      return app.students.length;
    }
    if (index == 5) {
      final openAlerts = app.alerts.where((a) => !a.isResolved).length;
      return openAlerts > 0 ? openAlerts : null;
    }
    return null;
  }

  void _showQuickSearchModal(BuildContext context) {
    final app = context.read<AppProvider>();
    String query = '';

    showDialog(
      context: context,
      barrierColor: const Color(0x4D0F172A),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final results = app.students.where((s) {
            if (query.trim().isEmpty) return true;
            final q = query.toLowerCase();
            return s.fullName.toLowerCase().contains(q) ||
                s.grade.toLowerCase().contains(q) ||
                s.primaryNeed.toLowerCase().contains(q);
          }).take(8).toList();

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540, maxHeight: 480),
              child: GlassSurface(
                borderRadius: 22,
                blur: 24,
                opacity: 0.92,
                boxShadow: AppColors.elevatedShadow,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (v) => setModalState(() => query = v),
                      decoration: InputDecoration(
                        hintText:
                            'O‘quvchi F.I.Sh., sinfi yoki yo‘nalishini qidiring...',
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'TEZKOR NATIJALAR',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: results.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'So‘rov bo‘yicha o‘quvchi topilmadi',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: results.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, i) {
                                final s = results[i];
                                return SurfaceCard(
                                  elevated: false,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  borderRadius: 12,
                                  backgroundColor: Colors.white,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      this.context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            StudentDetailScreen(studentId: s.id),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          s.firstName.isNotEmpty
                                              ? s.firstName[0]
                                              : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                            fontSize: 14,
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
                                              s.fullName,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              '${s.grade}-sinf • ${s.primaryNeed}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        LucideIcons.chevronRight,
                                        size: 16,
                                        color: AppColors.textSubtle,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMobileModulesSheet(BuildContext context, AppProvider app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassSurface(
        borderRadius: 26,
        blur: 24,
        opacity: 0.93,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Barcha tizim bo‘limlari',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(LucideIcons.x, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _navItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 60,
                ),
                itemBuilder: (_, idx) {
                  final item = _navItems[idx];
                  final isSel = _selectedIndex == item.index;
                  final badge = _badgeForIndex(item.index, app);

                  return SurfaceCard(
                    elevated: false,
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    backgroundColor:
                        isSel ? AppColors.primaryLight : Colors.white,
                    borderColor: isSel
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : AppColors.hairlineBorder,
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectTab(item.index);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            size: 17,
                            color:
                                isSel ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.shortLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w600,
                              color: isSel
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.index == 5
                                  ? AppColors.errorBg
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$badge',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: item.index == 5
                                    ? AppColors.error
                                    : AppColors.primary,
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
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final df = DateFormat('dd.MM HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final notifications = app.myNotifications;
          final unreadCount = app.myUnreadNotificationCount;
          return GlassSurface(
            borderRadius: 26,
            blur: 24,
            opacity: 0.94,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 480,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.bellRing,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Bildirishnomalar',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          StatusPill(
                            label: '$unreadCount yangi',
                            color: AppColors.error,
                            backgroundColor: AppColors.errorBg,
                          ),
                        if (auth.currentUser != null && unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: () async {
                              await app.markAllNotificationsAsRead(
                                auth.currentUser!.id,
                              );
                              setSheetState(() {});
                            },
                            child: const Text(
                              'O‘qilgan qilish',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: notifications.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.bellOff,
                                    size: 36,
                                    color: AppColors.textSubtle,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Hozircha yangi bildirishnomalar yo‘q',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: notifications.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (c, i) {
                                final notif = notifications[i];
                                final isAlert = notif.type == 'ALERT';
                                final accent = isAlert
                                    ? AppColors.error
                                    : AppColors.primary;

                                return SurfaceCard(
                                  elevated: false,
                                  borderRadius: 14,
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: notif.isRead
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.white,
                                  borderColor: notif.isRead
                                      ? AppColors.hairlineBorder
                                      : accent.withValues(alpha: 0.25),
                                  onTap: () async {
                                    final navigator =
                                        Navigator.of(this.context);
                                    final sheetNav = Navigator.of(ctx);
                                    final studentId = notif.relatedStudentId;
                                    if (!notif.isRead) {
                                      await app.markNotificationAsRead(
                                        notif.id,
                                      );
                                      setSheetState(() {});
                                    }
                                    if (studentId != null) {
                                      sheetNav.pop();
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (_) => StudentDetailScreen(
                                            studentId: studentId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: notif.isRead
                                              ? AppColors.borderLight
                                              : accent.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isAlert
                                              ? LucideIcons.triangleAlert
                                              : notif.type == 'REFERRAL'
                                                  ? LucideIcons.arrowLeftRight
                                                  : LucideIcons.clipboardList,
                                          color: notif.isRead
                                              ? AppColors.textMuted
                                              : accent,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif.title,
                                                    style: TextStyle(
                                                      fontWeight: notif.isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.w700,
                                                      fontSize: 13,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (!notif.isRead)
                                                  Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration: BoxDecoration(
                                                      color: accent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              notif.body,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              df.format(notif.createdAt),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                                fontFeatures: [
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser;
    final unreadNotifCount = app.myUnreadNotificationCount;
    final currentNav = _navItems[_selectedIndex];

    return AmbientMeshBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: isDesktop ? null : _buildMobileDrawer(context, auth, app, user),
        body: Row(
          children: [
            if (isDesktop) _buildDesktopGlassSidebar(context, auth, app, user),
            Expanded(
              child: Column(
                children: [
                  _buildTopGlassHeader(
                    context: context,
                    isDesktop: isDesktop,
                    currentNav: currentNav,
                    user: user,
                    auth: auth,
                    unreadNotifCount: unreadNotifCount,
                  ),
                  Expanded(
                    child: PageTransitionSwitcher(
                      duration: const Duration(milliseconds: 210),
                      transitionBuilder:
                          (child, primaryAnimation, secondaryAnimation) {
                        return FadeThroughTransition(
                          fillColor: Colors.transparent,
                          animation: primaryAnimation,
                          secondaryAnimation: secondaryAnimation,
                          child: child,
                        );
                      },
                      child: _buildActiveScreen(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar:
            isDesktop ? null : _buildMobileFrostedBottomBar(context, app),
      ),
    );
  }

  Widget _buildTopGlassHeader({
    required BuildContext context,
    required bool isDesktop,
    required _NavItemData currentNav,
    required UserModel? user,
    required AuthProvider auth,
    required int unreadNotifCount,
  }) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: const Border(
              bottom: BorderSide(color: AppColors.hairlineBorder, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 60,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 14),
                child: Row(
                  children: [
                    if (!isDesktop) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Menyu',
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        icon: const Icon(
                          LucideIcons.panelLeft,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (!isDesktop)
                      Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppColors.primaryGlow,
                        ),
                        child: const Icon(
                          LucideIcons.landmark,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDesktop ? currentNav.title : 'TA’LIM NAZORAT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isDesktop ? 16 : 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.25,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            user?.institutionName ??
                                '9-sonli inklyuziv ta’lim tayanch maktabi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tezkor qidiruv tugmasi
                    if (isDesktop)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () => _showQuickSearchModal(context),
                          borderRadius: BorderRadius.circular(11),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.search,
                                  size: 15,
                                  color: AppColors.textMuted,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'O‘quvchi qidirish...',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Qidirish',
                        onPressed: () => _showQuickSearchModal(context),
                        icon: const Icon(
                          LucideIcons.search,
                          size: 19,
                          color: AppColors.textSecondary,
                        ),
                      ),

                    // Bildirishnomalar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Bildirishnomalar',
                          onPressed: () => _showNotificationsSheet(context),
                          icon: const Icon(
                            LucideIcons.bell,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (unreadNotifCount > 0)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(minWidth: 16),
                              child: Text(
                                '$unreadNotifCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 4),

                    // Foydalanuvchi menyusi
                    PopupMenuButton<String>(
                      tooltip: 'Profil menyusi',
                      offset: const Offset(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.hairlineBorder),
                      ),
                      onSelected: (val) async {
                        if (val == 'settings') {
                          _selectTab(9);
                        } else if (val == 'logout') {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Mutaxassis',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.role.label ?? '',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(LucideIcons.settings, size: 16),
                              SizedBox(width: 10),
                              Text(
                                'Sozlamalar',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.logOut,
                                size: 16,
                                color: AppColors.error,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Tizimdan chiqish',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 10 : 4,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                (user?.fullName ?? 'U').substring(0, 1),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 140),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      user?.role.label ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                LucideIcons.chevronDown,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopGlassSidebar(
    BuildContext context,
    AuthProvider auth,
    AppProvider app,
    UserModel? user,
  ) {
    final groups = <String, List<_NavItemData>>{
      'ASOSIY ISH MAYDONI': [
        _navItems[0],
        _navItems[1],
        _navItems[2],
        _navItems[3],
      ],
      'REJA VA NAZORAT': [
        _navItems[4],
        _navItems[5],
        _navItems[8],
      ],
      'BOSHQARUV VA TIZIM': [
        _navItems[6],
        _navItems[7],
        _navItems[9],
      ],
    };

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 256,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            border: const Border(
              right: BorderSide(color: AppColors.hairlineBorder, width: 1),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: AppColors.primaryGlow,
                        ),
                        child: const Icon(
                          LucideIcons.landmark,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TA’LIM NAZORAT',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Inklyuziv monitoring',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Scrollable Grouped Nav List (zero vertical overflow on any laptop)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    children: groups.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.textSubtle,
                                ),
                              ),
                            ),
                            ...entry.value.map((item) {
                              final isSelected = _selectedIndex == item.index;
                              final badge = _badgeForIndex(item.index, app);
                              final isAlertBadge = item.index == 5;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(11),
                                    onTap: () => _selectTab(item.index),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 9.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryLight
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                                  .withValues(alpha: 0.18)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            item.icon,
                                            size: 18,
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textSecondary,
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                          ),
                                          if (badge != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isAlertBadge
                                                    ? AppColors.errorBg
                                                    : (isSelected
                                                        ? Colors.white
                                                        : AppColors
                                                            .borderLight),
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                              child: Text(
                                                '$badge',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  fontFeatures: const [
                                                    FontFeature
                                                        .tabularFigures(),
                                                  ],
                                                  color: isAlertBadge
                                                      ? AppColors.error
                                                      : (isSelected
                                                          ? AppColors.primary
                                                          : AppColors
                                                              .textMuted),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Sidebar Footer Card
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.hairlineBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          size: 16,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.district ?? 'Chortoq tumani',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Himoyalangan tizim',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFrostedBottomBar(BuildContext context, AppProvider app) {
    final quickTabs = [_navItems[0], _navItems[1], _navItems[2], _navItems[3]];
    final isMoreActive = _selectedIndex >= 4;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: const Border(
              top: BorderSide(color: AppColors.hairlineBorder, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ...quickTabs.map((item) {
                    final isSelected = _selectedIndex == item.index;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _selectTab(item.index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.shortLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // 5-chi "Bo'limlar" tugmasi (4..9 indekslar faol bo'lganda aynan shu yonadi!)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showMobileModulesSheet(context, app),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isMoreActive
                              ? AppColors.primaryLight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMoreActive
                                  ? _navItems[_selectedIndex].icon
                                  : LucideIcons.layoutGrid,
                              size: 20,
                              color: isMoreActive
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isMoreActive
                                  ? _navItems[_selectedIndex].shortLabel
                                  : 'Barchasi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isMoreActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isMoreActive
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    AuthProvider auth,
    AppProvider app,
    UserModel? user,
  ) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(color: AppColors.hairlineBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.landmark,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TA’LIM NAZORAT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Yagona monitoring tizimi',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SurfaceCard(
                    elevated: false,
                    padding: const EdgeInsets.all(11),
                    borderRadius: 12,
                    backgroundColor: Colors.white,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            (user?.fullName ?? 'U').substring(0, 1),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Mutaxassis',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.role.label ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _navItems.length,
                itemBuilder: (ctx, idx) {
                  final item = _navItems[idx];
                  final isSel = _selectedIndex == item.index;
                  final badge = _badgeForIndex(item.index, app);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tileColor:
                          isSel ? AppColors.primaryLight : Colors.transparent,
                      leading: Icon(
                        item.icon,
                        color: isSel
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 19,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      trailing: badge != null
                          ? StatusPill(
                              label: '$badge',
                              color: item.index == 5
                                  ? AppColors.error
                                  : AppColors.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _selectTab(item.index);
                      },
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.hairlineBorder),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TA’LIM NAZORAT • v2.5',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      LucideIcons.logOut,
                      size: 15,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Chiqish',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
}
