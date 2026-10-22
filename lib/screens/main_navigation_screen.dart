import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'students/students_list_screen.dart';
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
    {'title': 'Boshqaruv', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded},
    {'title': 'Bolalar bazasi', 'icon': Icons.people_outline_rounded, 'activeIcon': Icons.people_rounded},
    {'title': 'Baholashlar', 'icon': Icons.assignment_outlined, 'activeIcon': Icons.assignment_rounded},
    {'title': 'Mashg‘ulotlar', 'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today_rounded},
    {'title': 'ITR rejalari', 'icon': Icons.menu_book_outlined, 'activeIcon': Icons.menu_book_rounded},
    {'title': 'Monitoring', 'icon': Icons.shield_outlined, 'activeIcon': Icons.shield_rounded},
    {'title': 'Hisobotlar', 'icon': Icons.bar_chart_outlined, 'activeIcon': Icons.bar_chart_rounded},
    {'title': 'Mutaxassislar', 'icon': Icons.badge_outlined, 'activeIcon': Icons.badge_rounded},
    {'title': 'Yo‘naltirishlar', 'icon': Icons.alt_route_rounded, 'activeIcon': Icons.alt_route_rounded},
    {'title': 'Sozlamalar', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 860;
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser;
    final alertCount = app.unresolvedAlerts.length;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TA’LIM NAZORAT',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  user?.institutionName ?? '14-Inklyuziv maktab',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Monitoring alert belgisi
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  setState(() => _selectedIndex = 5); // Monitoringga o'tish
                },
              ),
              if (alertCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$alertCount',
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (user?.fullName ?? 'U').substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
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
                    const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
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
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
          const SizedBox(width: 8),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: AppColors.primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.school, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'TA’LIM NAZORAT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user?.fullName ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(_navItems.length, (idx) {
                    final item = _navItems[idx];
                    final isSel = _selectedIndex == idx;
                    return ListTile(
                      leading: Icon(
                        isSel ? item['activeIcon'] : item['icon'],
                        color: isSel ? AppColors.primary : AppColors.textSecondary,
                      ),
                      title: Text(
                        item['title'],
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSel,
                      onTap: () {
                        setState(() => _selectedIndex = idx);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ),
      body: Row(
        children: [
          // Desktop Navigation Rail
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
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
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),

          // Asosiy kontent
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
              onTap: (idx) {
                if (idx == 4) {
                  // "Barchasi" drawer menyusini ochish
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  setState(() => _selectedIndex = idx);
                }
              },
              type: BottomNavigationBarType.fixed,
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
    );
  }
}
