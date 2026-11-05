import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import '../auth/logout_dialog.dart';
import '../referrals/referrals_screen.dart';

import 'server/server_institutions_tab.dart';
import 'server/server_users_tab.dart';
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
        icon: LucideIcons.layoutDashboard,
        activeIcon: LucideIcons.layoutDashboard,
      ),
    ]),
    _AdminNavCategory('MONITORING VA TAHLIL', [
      _AdminNavItemData(
        index: 8,
        title: 'Monitoring markazi',
        icon: LucideIcons.shield,
        activeIcon: LucideIcons.shield,
        hasAlertBadge: true,
      ),
      _AdminNavItemData(
        index: 7,
        title: 'Tahliliy hisobotlar',
        icon: LucideIcons.barChart,
        activeIcon: LucideIcons.barChart,
      ),
    ]),
    _AdminNavCategory('REYESTRLAR VA KADRLAR', [
      _AdminNavItemData(
        index: 3,
        title: 'O‘quvchilar reyestri',
        icon: LucideIcons.users,
        activeIcon: LucideIcons.users,
      ),
      _AdminNavItemData(
        index: 2,
        title: 'Pedagog-mutaxassislar',
        icon: LucideIcons.brain,
        activeIcon: LucideIcons.brain,
      ),
      _AdminNavItemData(
        index: 4,
        title: 'Ta’lim muassasalari',
        icon: LucideIcons.building2,
        activeIcon: LucideIcons.building2,
      ),
      _AdminNavItemData(
        index: 5,
        title: 'Sinflar va guruhlar',
        icon: LucideIcons.school,
        activeIcon: LucideIcons.school,
      ),
      _AdminNavItemData(
        index: 11,
        title: 'Yo‘naltirishlar jurnali',
        icon: LucideIcons.route,
        activeIcon: LucideIcons.route,
      ),
    ]),
    _AdminNavCategory('XAVFSIZLIK VA MA’MURIYAT', [
      _AdminNavItemData(
        index: 1,
        title: 'Foydalanuvchilar',
        icon: LucideIcons.userCog,
        activeIcon: LucideIcons.userCog,
      ),
      _AdminNavItemData(
        index: 6,
        title: 'Rollar va ruxsatlar',
        icon: LucideIcons.shield,
        activeIcon: LucideIcons.shield,
      ),
      _AdminNavItemData(
        index: 10,
        title: 'Audit jurnali',
        icon: LucideIcons.scrollText,
        activeIcon: LucideIcons.scrollText,
      ),
      _AdminNavItemData(
        index: 9,
        title: 'Tizim sozlamalari',
        icon: LucideIcons.settings2,
        activeIcon: LucideIcons.settings2,
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
      // Server rejimida hisoblar va muassasalar serverdan boshqariladi.
      AppConfig.serverMode ? const ServerUsersTab() : const AdminUsersTab(),
      const AdminSpecialistsTab(),
      const AdminStudentsTab(),
      AppConfig.serverMode
          ? const ServerInstitutionsTab()
          : const AdminInstitutionsTab(),
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
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
        title: Row(
          children: [
            const BrandMark(height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: BrandWordmark(fontSize: 17),
                        ),
                      ),
                      // Telefonda rol nomi sarlavhaga sig'maydi — u profil qatorida ko'rinadi
                      if (MediaQuery.sizeOf(context).width >= 700) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: StatusBadge(roleTag, tone: StatusTone.primary),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    portalSubtitle,
                    style: TextStyle(
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
          // MUTAXASSIS KO'RINISHIGA O'TISH (telefonda faqat ikona — sarlavha sig'sin)
          if (MediaQuery.sizeOf(context).width < 700)
            IconButton(
              tooltip: 'Mutaxassis interfeysi',
              icon: Icon(LucideIcons.arrowLeftRight, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainNavigationScreen(),
                  ),
                );
              },
            )
          else
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
              icon: const Icon(LucideIcons.arrowLeftRight, size: 18),
              label: const Text(
                'Mutaxassis interfeysi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 10),

          // FOYDALANUVCHI PROFILI
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryDark,
                    child: Text(
                      (user?.fullName ?? 'A').substring(0, 1),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width >= 700) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user?.fullName ?? 'Administrator',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          user?.role.label ?? 'Tizim administratori',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.0,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // CHIQISH (LOGOUT)
          IconButton(
            icon: Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
            tooltip: 'Tizimdan chiqish',
            onPressed: () => confirmLogout(context),
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
                color: AppColors.surface,
                shape: Border(right: BorderSide(color: AppColors.border)),
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
            color: AppColors.primaryDark,
            child: const Row(
              children: [
                Icon(LucideIcons.shieldCheck, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'ADMINISTRATOR MENYUSI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
                              fontSize: 13,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
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
}
