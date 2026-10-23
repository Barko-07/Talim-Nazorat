import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'students/students_list_screen.dart';
import 'students/student_detail_screen.dart';
import 'assessments/assessments_list_screen.dart';
import 'sessions/sessions_screen.dart';
import 'iep/iep_list_screen.dart';
import 'monitoring/monitoring_screen.dart';
import 'reports/reports_screen.dart';
import 'specialists/specialists_screen.dart';
import 'referrals/referrals_screen.dart';
import 'settings/settings_screen.dart';
import 'auth/login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

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

  void _showNotificationsSheet(BuildContext context) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final notifications = app.myNotifications;
    final df = DateFormat('dd.MM HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final unreadCount = app.myUnreadNotificationCount;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              height: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Bildirishnomalar va Vazifalar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount ta yangi',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                            'Barchasini o‘qilgan qilish',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: notifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  size: 40,
                                  color: AppColors.textMuted,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Hozircha yangi bildirishnomalar yo‘q',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (c, i) {
                              final notif = notifications[i];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: notif.isRead
                                      ? AppColors.borderLight
                                      : AppColors.primaryLight,
                                  child: Icon(
                                    notif.type == 'ALERT'
                                        ? Icons.warning_amber_rounded
                                        : notif.type == 'REFERRAL'
                                        ? Icons.alt_route
                                        : Icons.assignment,
                                    color: notif.isRead
                                        ? AppColors.textMuted
                                        : (notif.type == 'ALERT'
                                              ? AppColors.error
                                              : AppColors.primary),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: notif.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.body,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      df.format(notif.createdAt),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: !notif.isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                                onTap: () async {
                                  final navigator = Navigator.of(context);
                                  final sheetNav = Navigator.of(ctx);
                                  final studentId = notif.relatedStudentId;
                                  if (!notif.isRead) {
                                    await app.markNotificationAsRead(notif.id);
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
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    StudentsListScreen(),
    AssessmentsListScreen(),
    SessionsScreen(),
    IepListScreen(),
    MonitoringScreen(),
    ReportsScreen(),
    SpecialistsScreen(),
    ReferralsScreen(),
    SettingsScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {
      'title': 'Boshqaruv',
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard_rounded,
    },
    {
      'title': 'Bolalar bazasi',
      'icon': Icons.people_outline_rounded,
      'activeIcon': Icons.people_rounded,
    },
    {
      'title': 'Baholashlar',
      'icon': Icons.assignment_outlined,
      'activeIcon': Icons.assignment_rounded,
    },
    {
      'title': 'Mashg‘ulotlar',
      'icon': Icons.calendar_today_outlined,
      'activeIcon': Icons.calendar_today_rounded,
    },
    {
      'title': 'ITR rejalari',
      'icon': Icons.menu_book_outlined,
      'activeIcon': Icons.menu_book_rounded,
    },
    {
      'title': 'Monitoring',
      'icon': Icons.shield_outlined,
      'activeIcon': Icons.shield_rounded,
    },
    {
      'title': 'Hisobotlar',
      'icon': Icons.bar_chart_outlined,
      'activeIcon': Icons.bar_chart_rounded,
    },
    {
      'title': 'Mutaxassislar',
      'icon': Icons.badge_outlined,
      'activeIcon': Icons.badge_rounded,
    },
    {
      'title': 'Yo‘naltirishlar',
      'icon': Icons.alt_route_rounded,
      'activeIcon': Icons.alt_route_rounded,
    },
    {
      'title': 'Sozlamalar',
      'icon': Icons.settings_outlined,
      'activeIcon': Icons.settings_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 860;
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser;
    final unreadNotifCount = app.myUnreadNotificationCount;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        titleSpacing: 16,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TA’LIM NAZORAT',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    user?.institutionName ?? '5-sonli umumiy o‘rta ta’lim maktabi',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Bildirishnomalar belgisi
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
                tooltip: 'Bildirishnomalar',
                onPressed: () => _showNotificationsSheet(context),
              ),
              if (unreadNotifCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadNotifCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Foydalanuvchi va rol
          PopupMenuButton<String>(
            tooltip: 'Foydalanuvchi menyusi',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (user?.fullName ?? 'U').substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user?.role.label ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
            onSelected: (val) async {
              if (val == 'settings') {
                setState(() => _selectedIndex = 9);
              } else if (val == 'logout') {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  '${user?.fullName}\n${user?.role.label}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Sozlamalar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Chiqish', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: Colors.white,
              child: Column(
                children: [
                  // Modern Governmental Drawer Header
                  SafeArea(
                    bottom: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: Colors.white,
                                  size: 18,
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
                                        letterSpacing: 0.2,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Yagona monitoring tizimi',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Foydalanuvchi kartochkasi
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    (user?.fullName ?? 'U').substring(0, 1),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          user?.role.label ?? '',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
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

                  // Menyular ro'yxati
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      itemCount: _navItems.length,
                      itemBuilder: (context, idx) {
                        final item = _navItems[idx];
                        final isSel = _selectedIndex == idx;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primaryLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            leading: Icon(
                              isSel ? item['activeIcon'] : item['icon'],
                              color: isSel ? AppColors.primary : AppColors.textSecondary,
                              size: 20,
                            ),
                            title: Text(
                              item['title'],
                              style: TextStyle(
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? AppColors.primary : AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSel,
                            onTap: () {
                              setState(() => _selectedIndex = idx);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Drawer Bottom Footer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'MyGov Standart v2.4.0',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Axborot xavfsizligi kafolatlangan',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Chiqish',
                          icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                          onPressed: () async {
                            await auth.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      body: Row(
        children: [
          // Desktop Navigation Rail
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _selectedIndex = idx),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.textSecondary,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              destinations: _navItems.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item['icon'], size: 22),
                  selectedIcon: Icon(item['activeIcon'], size: 22),
                  label: Text(item['title']),
                );
              }).toList(),
            ),
          if (isDesktop)
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: AppColors.border,
            ),

          // Asosiy kontent
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
                onTap: (idx) {
                  if (idx == 4) {
                    _scaffoldKey.currentState?.openDrawer();
                  } else {
                    setState(() => _selectedIndex = idx);
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textMuted,
                selectedFontSize: 11,
                unselectedFontSize: 10,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard_rounded),
                    label: 'Boshqaruv',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline_rounded),
                    activeIcon: Icon(Icons.people_rounded),
                    label: 'Bolalar',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.assignment_outlined),
                    activeIcon: Icon(Icons.assignment_rounded),
                    label: 'Baholash',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today_rounded),
                    label: 'Mashg‘ulot',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_rounded),
                    label: 'Barchasi',
                  ),
                ],
              ),
            ),
    );
  }
}
