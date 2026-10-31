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
      barrierColor: const Color(0x420F172A),
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
              horizontal: 18,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 500),
              child: GlassSurface(
                borderRadius: 30,
                blur: 26,
                opacity: 0.84,
                boxShadow: AppColors.elevatedShadow,
                padding: const EdgeInsets.all(22),
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
                          icon: const Icon(LucideIcons.x, size: 17),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'TEZKOR NATIJALAR',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: results.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 34),
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
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final s = results[i];
                                return SurfaceCard(
                                  elevated: false,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 13,
                                  ),
                                  borderRadius: 20,
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
                                      const Icon(
                                        LucideIcons.userRound,
                                        size: 19,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 13),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.fullName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${s.grade}-sinf • ${s.primaryNeed}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
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
        borderRadius: 32,
        blur: 26,
        opacity: 0.88,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: AppColors.borderSlate,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.layoutGrid,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Barcha tizim bo‘limlari',
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(LucideIcons.x, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ResponsiveGlassGrid(
                  mobileColumns: 2,
                  tabletColumns: 2,
                  desktopColumns: 2,
                  spacing: 12,
                  children: _navItems.map((item) {
                    final isSel = _selectedIndex == item.index;
                    final badge = _badgeForIndex(item.index, app);

                    return SurfaceCard(
                      elevated: !isSel,
                      borderRadius: 22,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 14,
                      ),
                      backgroundColor: isSel
                          ? Colors.white.withValues(alpha: 0.94)
                          : null,
                      borderColor: isSel
                          ? AppColors.primary.withValues(alpha: 0.45)
                          : Colors.white,
                      onTap: () {
                        Navigator.pop(ctx);
                        _selectTab(item.index);
                      },
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 19,
                            color: isSel
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.shortLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.index == 5
                                    ? AppColors.errorBg
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(999),
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
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
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
            borderRadius: 32,
            blur: 26,
            opacity: 0.88,
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: AppColors.borderSlate,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.bellRing,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Bildirishnomalar',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: -0.3,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              StatusPill(
                                label: '$unreadCount yangi',
                                color: AppColors.error,
                                backgroundColor: AppColors.errorBg,
                              ),
                            ],
                          ],
                        ),
                        if (auth.currentUser != null && unreadCount > 0)
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
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 10),
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
                                  const SizedBox(height: 10),
                              itemBuilder: (c, i) {
                                final notif = notifications[i];
                                final isAlert = notif.type == 'ALERT';
                                final accent = isAlert
                                    ? AppColors.error
                                    : AppColors.primary;

                                return SurfaceCard(
                                  elevated: false,
                                  borderRadius: 22,
                                  padding: const EdgeInsets.all(16),
                                  borderColor: notif.isRead
                                      ? Colors.white
                                      : accent.withValues(alpha: 0.35),
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
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(
                                          isAlert
                                              ? LucideIcons.triangleAlert
                                              : notif.type == 'REFERRAL'
                                                  ? LucideIcons.arrowLeftRight
                                                  : LucideIcons.clipboardList,
                                          color: notif.isRead
                                              ? AppColors.textMuted
                                              : accent,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 13),
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
                                                          : FontWeight.w800,
                                                      fontSize: 13.5,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                if (!notif.isRead)
                                                  Container(
                                                    width: 7.5,
                                                    height: 7.5,
                                                    decoration: BoxDecoration(
                                                      color: accent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notif.body,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppColors.textSecondary,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
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
    final isDesktop = width >= 920;
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
                      duration: const Duration(milliseconds: 220),
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
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 14,
          isDesktop ? 16 : 10,
          isDesktop ? 28 : 14,
          4,
        ),
        child: GlassSurface(
          borderRadius: 24,
          blur: 22,
          opacity: 0.74,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 12,
            vertical: 10,
          ),
          child: Row(
            children: [
              if (!isDesktop) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Menyu',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(
                    LucideIcons.panelLeft,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.landmark,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 9),
              ],
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
                        fontSize: isDesktop ? 16.5 : 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
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

              if (isDesktop)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => _showQuickSearchModal(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.3),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.search,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'O‘quvchi qidirish...',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
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
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(999),
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

              const SizedBox(width: 6),

              PopupMenuButton<String>(
                tooltip: 'Profil menyusi',
                offset: const Offset(0, 48),
                color: const Color(0xF2FFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Colors.white, width: 1.4),
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
                            fontWeight: FontWeight.w800,
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 12 : 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 13.5,
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
                        const SizedBox(width: 9),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 145),
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
                        const SizedBox(width: 5),
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

    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
        child: SizedBox(
          width: 262,
          child: GlassSurface(
            borderRadius: 30,
            blur: 24,
            opacity: 0.74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header (free-standing icon!)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 20, 16),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.landmark,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TA’LIM NAZORAT',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Inklyuziv monitoring',
                              style: TextStyle(
                                fontSize: 11.5,
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

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    children: groups.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: AppColors.textSubtle,
                                ),
                              ),
                            ),
                            ...entry.value.map((item) {
                              final isSelected = _selectedIndex == item.index;
                              final badge = _badgeForIndex(item.index, app);
                              final isAlertBadge = item.index == 5;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => _selectTab(item.index),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 170,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withValues(
                                                alpha: 0.92,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 1.2,
                                        ),
                                        boxShadow: isSelected
                                            ? const [
                                                BoxShadow(
                                                  color: Color(0x100F172A),
                                                  blurRadius: 12,
                                                  offset: Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            item.icon,
                                            size: 18.5,
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
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
                                                horizontal: 7.5,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isAlertBadge
                                                    ? AppColors.errorBg
                                                    : AppColors.primaryLight,
                                                borderRadius:
                                                    BorderRadius.circular(999),
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
                                                      : AppColors.primary,
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

                // Sidebar Footer Glass Well (free-standing icon!)
                GlassWell(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.shieldCheck,
                        size: 19,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.district ?? 'Chortoq tumani',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
        child: GlassSurface(
          borderRadius: 28,
          blur: 24,
          opacity: 0.80,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                      duration: const Duration(milliseconds: 170),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.94)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0x120F172A),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ]
                            : null,
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
                                  ? FontWeight.w800
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
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showMobileModulesSheet(context, app),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isMoreActive
                          ? Colors.white.withValues(alpha: 0.94)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: isMoreActive
                          ? const [
                              BoxShadow(
                                color: Color(0x120F172A),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
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
                                ? FontWeight.w800
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
    );
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    AuthProvider auth,
    AppProvider app,
    UserModel? user,
  ) {
    return Drawer(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.landmark,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TA’LIM NAZORAT',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Yagona monitoring tizimi',
                              style: TextStyle(
                                fontSize: 11.5,
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
                    padding: const EdgeInsets.all(14),
                    borderRadius: 22,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            (user?.fullName ?? 'U').substring(0, 1),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Mutaxassis',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.role.label ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: _navItems.length,
                itemBuilder: (ctx, idx) {
                  final item = _navItems[idx];
                  final isSel = _selectedIndex == item.index;
                  final badge = _badgeForIndex(item.index, app);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: isSel
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.transparent,
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
                              isSel ? FontWeight.w800 : FontWeight.w600,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TA’LIM NAZORAT • v2.6',
                      style: TextStyle(
                        fontSize: 11.5,
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
                        fontSize: 12.5,
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
