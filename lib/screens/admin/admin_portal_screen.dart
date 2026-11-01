import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import '../auth/login_screen.dart';

import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_specialists_tab.dart';
import 'tabs/admin_students_tab.dart';
import 'tabs/admin_institutions_tab.dart';
import 'tabs/admin_classes_tab.dart';
import 'tabs/admin_roles_tab.dart';
import 'tabs/admin_reports_tab.dart';
import 'tabs/admin_monitoring_tab.dart';
import 'tabs/admin_settings_tab.dart';
import 'tabs/admin_audit_tab.dart';

class AdminPortalScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminPortalScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

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

  final List<Map<String, dynamic>> _navItems = const [
    {
      'title': 'Bosh sahifa',
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard_rounded,
    },
    {
      'title': 'Foydalanuvchilar',
      'icon': Icons.manage_accounts_outlined,
      'activeIcon': Icons.manage_accounts_rounded,
    },
    {
      'title': 'Mutaxassislar',
      'icon': Icons.psychology_outlined,
      'activeIcon': Icons.psychology_rounded,
    },
    {
      'title': 'O‘quvchilar',
      'icon': Icons.groups_outlined,
      'activeIcon': Icons.groups_rounded,
    },
    {
      'title': 'Muassasalar',
      'icon': Icons.apartment_outlined,
      'activeIcon': Icons.apartment_rounded,
    },
    {
      'title': 'Sinflar',
      'icon': Icons.school_outlined,
      'activeIcon': Icons.school_rounded,
    },
    {
      'title': 'Rollar va ruxsatlar',
      'icon': Icons.security_outlined,
      'activeIcon': Icons.security_rounded,
    },
    {
      'title': 'Hisobotlar',
      'icon': Icons.bar_chart_outlined,
      'activeIcon': Icons.bar_chart_rounded,
    },
    {
      'title': 'Monitoring',
      'icon': Icons.shield_outlined,
      'activeIcon': Icons.shield_rounded,
    },
    {
      'title': 'Sozlamalar',
      'icon': Icons.settings_suggest_outlined,
      'activeIcon': Icons.settings_suggest_rounded,
    },
    {
      'title': 'Audit jurnali',
      'icon': Icons.history_edu_outlined,
      'activeIcon': Icons.history_edu_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser;
    final unresolvedAlertsCount = app.unresolvedAlerts.length;

    final List<Widget> screens = [
      AdminOverviewTab(
        onNavigateTab: (idx) => setState(() => _selectedIndex = idx),
      ),
      const AdminUsersTab(),
      const AdminSpecialistsTab(),
      const AdminStudentsTab(),
      const AdminInstitutionsTab(),
      const AdminClassesTab(),
      const AdminRolesTab(),
      const AdminReportsTab(),
      const AdminMonitoringTab(),
      const AdminSettingsTab(),
      const AdminAuditTab(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF073A82),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF073A82),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN PORTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'O‘zbekiston Respublikasi Maktabgacha va maktab ta’limi vazirligi • Namangan viloyati',
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
          // MUTAXASSIS KO'RINISHIGA O'TISH
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MainNavigationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text(
              'Mutaxassis interfeysi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),

          // FOYDALANUVCHI PROFILI
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF073A82),
                    child: Text(
                      (user?.fullName ?? 'A').substring(0, 1),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?.fullName ?? 'Administrator',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        user?.role.label ?? 'Tizim administratori',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // CHIQISH (LOGOUT)
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 20,
            ),
            tooltip: 'Tizimdan chiqish',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: _buildSidebarContent(
                context,
                unresolvedAlertsCount,
                isDrawer: true,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: AppColors.border),
                ),
              ),
              child: _buildSidebarContent(context, unresolvedAlertsCount),
            ),
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    int alertCount, {
    bool isDrawer = false,
  }) {
    return Column(
      children: [
        if (isDrawer)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: const Color(0xFF073A82),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'ADMINISTRATOR MENYUSI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              final item = _navItems[index];
              final isSelected = _selectedIndex == index;
              final isMonitoring = index == 8;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: Icon(
                    isSelected ? item['activeIcon'] : item['icon'],
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    item['title'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: (isMonitoring && alertCount > 0)
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$alertCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (isDrawer) Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tizimdan chiqish'),
        content: const Text(
          'Haqiqatan ham Administrator portalidan chiqmoqchimisiz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }
}
