import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import '../auth/login_screen.dart';
import '../referrals/referrals_screen.dart';

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

class _AdminNavCategory {
  final String title;
  final List<_AdminNavItemData> items;
  const _AdminNavCategory(this.title, this.items);
}

class _AdminNavItemData {
  final int index;
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final bool hasAlertBadge;
  const _AdminNavItemData({
    required this.index,
    required this.title,
    required this.icon,
    required this.activeIcon,
    this.hasAlertBadge = false,
  });
}

class AdminPortalScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminPortalScreen({super.key, this.initialTabIndex = 0});

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

  static const List<_AdminNavCategory> _categories = [
    _AdminNavCategory('ASOSIY BOSHQARUV', [
      _AdminNavItemData(
        index: 0,
        title: 'Boshqaruv paneli',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
      ),
    ]),
    _AdminNavCategory('MONITORING VA TAHLIL', [
      _AdminNavItemData(
        index: 8,
        title: 'Monitoring markazi',
        icon: Icons.shield_outlined,
        activeIcon: Icons.shield_rounded,
        hasAlertBadge: true,
      ),
      _AdminNavItemData(
        index: 7,
        title: 'Tahliliy hisobotlar',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
      ),
    ]),
    _AdminNavCategory('REYESTRLAR VA KADRLAR', [
      _AdminNavItemData(
        index: 3,
        title: 'O‘quvchilar reyestri',
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups_rounded,
      ),
      _AdminNavItemData(
        index: 2,
        title: 'Pedagog-mutaxassislar',
        icon: Icons.psychology_outlined,
        activeIcon: Icons.psychology_rounded,
      ),
      _AdminNavItemData(
        index: 4,
        title: 'Ta’lim muassasalari',
        icon: Icons.apartment_outlined,
        activeIcon: Icons.apartment_rounded,
      ),
      _AdminNavItemData(
        index: 5,
        title: 'Sinflar va guruhlar',
        icon: Icons.school_outlined,
        activeIcon: Icons.school_rounded,
      ),
      _AdminNavItemData(
        index: 11,
        title: 'Yo‘naltirishlar jurnali',
        icon: Icons.alt_route_outlined,
        activeIcon: Icons.alt_route_rounded,
      ),
    ]),
    _AdminNavCategory('XAVFSIZLIK VA MA’MURIYAT', [
      _AdminNavItemData(
        index: 1,
        title: 'Foydalanuvchilar',
        icon: Icons.manage_accounts_outlined,
        activeIcon: Icons.manage_accounts_rounded,
      ),
      _AdminNavItemData(
        index: 6,
        title: 'Rollar va ruxsatlar',
        icon: Icons.security_outlined,
        activeIcon: Icons.security_rounded,
      ),
      _AdminNavItemData(
        index: 10,
        title: 'Audit jurnali',
        icon: Icons.history_edu_outlined,
        activeIcon: Icons.history_edu_rounded,
      ),
      _AdminNavItemData(
        index: 9,
        title: 'Tizim sozlamalari',
        icon: Icons.settings_suggest_outlined,
        activeIcon: Icons.settings_suggest_rounded,
      ),
    ]),
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
      const ReferralsScreen(),
    ];

    // Rolga mos sarlavha va status
    final String roleTag;
    final String portalSubtitle;
    if (user?.role == UserRole.institutionAdmin) {
      roleTag = 'MUASSASA ADMINI';
      portalSubtitle = user?.institutionName ?? 'Muassasa ma’muriyati';
    } else if (user?.role == UserRole.reviewer) {
      roleTag = 'METODIK NAZORAT';
      portalSubtitle =
          'Namangan viloyat ta’lim sifatini monitoring qilish markazi';
    } else {
      roleTag = 'TIZIM ADMINISTRATORI';
      portalSubtitle =
          'O‘zbekiston Respublikasi Maktabgacha va maktab ta’limi vazirligi • Namangan viloyati';
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
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
                        child: Text(
                          roleTag,
                          style: const TextStyle(
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
                    portalSubtitle,
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
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
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
                          height: 1.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        user?.role.label ?? 'Tizim administratori',
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.0,
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
      drawer:
          isDesktop
              ? null
              : Drawer(
                child: _buildSidebarContent(
                  context,
                  unresolvedAlertsCount,
                  userRole: user?.role,
                  isDrawer: true,
                ),
              ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            SizedBox(
              width: 260,
              child: Material(
                color: Colors.white,
                shape: const Border(right: BorderSide(color: AppColors.border)),
                child: _buildSidebarContent(
                  context,
                  unresolvedAlertsCount,
                  userRole: user?.role,
                ),
              ),
            ),
          Expanded(child: screens[_selectedIndex.clamp(0, screens.length - 1)]),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    int alertCount, {
    UserRole? userRole,
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
            itemCount: _categories.length,
            itemBuilder: (context, catIdx) {
              final cat = _categories[catIdx];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 14,
                      bottom: 6,
                    ),
                    child: Text(
                      cat.title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...cat.items.map((item) {
                    final isSelected = _selectedIndex == item.index;
                    final isMonitoring = item.hasAlertBadge;

                    // Rolga mos matn o'zgarishi
                    String itemTitle = item.title;
                    if (item.index == 4 &&
                        userRole == UserRole.institutionAdmin) {
                      itemTitle = 'Mening muassasam';
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: AppColors.primaryLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          leading: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                            size: 19,
                          ),
                          title: Text(
                            itemTitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                          trailing:
                              (isMonitoring && alertCount > 0)
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
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                  : null,
                          onTap: () {
                            setState(() => _selectedIndex = item.index);
                            if (isDrawer) Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  }),
                ],
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
      builder:
          (ctx) => AlertDialog(
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
