import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import '../auth/logout_dialog.dart';
import '../referrals/referrals_screen.dart';
import '../settings/profile_edit_dialog.dart';

import 'admin_theme.dart';

import 'server/server_institutions_tab.dart';
import 'server/server_history_tab.dart';
import 'server/server_users_tab.dart';
import 'tabs/admin_home_blocks.dart' show adminCardShadow;
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
    _AdminNavCategory('Asosiy', [
      _AdminNavItemData(
        index: 0,
        title: 'Boshqaruv paneli',
        icon: LucideIcons.layoutDashboard,
        activeIcon: LucideIcons.layoutDashboard,
      ),
    ]),
    _AdminNavCategory('Monitoring va tahlil', [
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
    _AdminNavCategory('Reyestrlar va kadrlar', [
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
    _AdminNavCategory('Xavfsizlik va ma’muriyat', [
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
    final unread = app.myUnreadNotificationCount;

    // Kirgan zahoti AppProvider'ga foydalanuvchi keyingi kadrda o'rnatiladi
    // (didChangeDependencies). Shungacha sahifalar "tizimga kirilmagan"
    // xatosini bermasligi uchun yuklanish belgisi ko'rsatiladi.
    if (user != null && app.currentUser?.id != user.id) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
      // Server rejimida: har bir o'zgarish tarixi va xavfsizlik jurnali serverdan.
      AppConfig.serverMode ? const ServerHistoryTab() : const AdminAuditTab(),
      const ReferralsScreen(),
    ];

    // Rolga mos sarlavha ostidagi yozuv
    final String portalSubtitle;
    if (user?.role == UserRole.institutionAdmin) {
      portalSubtitle = user?.institutionName ?? 'Muassasa ma’muriyati';
    } else if (user?.role == UserRole.reviewer) {
      portalSubtitle = 'Ta’lim sifatini monitoring qilish markazi';
    } else {
      portalSubtitle = 'Maktabgacha va maktab ta’limi vazirligi';
    }

    return Theme(
      data: adminTheme(Theme.of(context)),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        appBar: AppBar(
          toolbarHeight: 72,
          titleSpacing: isDesktop ? 20 : 4,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leading:
              isDesktop
                  ? null
                  : IconButton(
                    tooltip: 'Menyu',
                    icon: Icon(
                      LucideIcons.menu,
                      color: AppColors.textPrimary,
                      size: 26,
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
          title:
              isDesktop
                  ? const SizedBox.shrink()
                  : Row(
                    children: [
                      const BrandMark(height: 42),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: BrandWordmark(fontSize: 21),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              portalSubtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.2,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          actions: [
            // XABARLAR (qo'ng'iroqcha)
            IconButton(
              tooltip: 'Xabarlar',
              onPressed: () => _showNotifications(context),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.bell,
                    color: AppColors.textPrimary,
                    size: 25,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // PROFIL
            _ProfileButton(user: user),
            SizedBox(width: isDesktop ? 20 : 12),
          ],
        ),
        drawer:
            isDesktop
                ? null
                : Drawer(
                  width: math.min(MediaQuery.sizeOf(context).width * 0.86, 360),
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    child: _buildSidebarContent(
                      context,
                      unresolvedAlertsCount,
                      userRole: user?.role,
                      isDrawer: true,
                    ),
                  ),
                ),
        bottomNavigationBar:
            isDesktop
                ? null
                : _AdminBottomBar(
                  selected: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop)
              Container(
                width: 290,
                margin: const EdgeInsets.fromLTRB(16, 0, 0, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: adminCardShadow(),
                ),
                child: _buildSidebarContent(
                  context,
                  unresolvedAlertsCount,
                  userRole: user?.role,
                ),
              ),
            Expanded(
              child: screens[_selectedIndex.clamp(0, screens.length - 1)],
            ),
          ],
        ),
      ),
    );
  }

  /// Qo'ng'iroqcha: shu administratorga kelgan xabarlar (masalan yangi
  /// ro'yxatdan o'tish). Bosilgani o'qilgan deb belgilanadi; ro'yxatdan
  /// o'tish xabari "Foydalanuvchilar" bo'limini ochadi.
  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<AppProvider>(
          builder: (ctx, app, _) {
            final items = [...app.myNotifications]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Xabarlar',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Yopish',
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.bellOff,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Hozircha xabar yo‘q. Kimdir ro‘yxatdan o‘tsa, shu yerda ko‘rinadi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        itemCount: items.length,
                        separatorBuilder:
                            (_, __) => Divider(
                              height: 1,
                              indent: 64,
                              color: AppColors.borderLight,
                            ),
                        itemBuilder: (ctx, i) {
                          final n = items[i];
                          final signup = n.type == 'SIGNUP';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color:
                                    n.isRead
                                        ? AppColors.surfaceMuted
                                        : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                signup
                                    ? LucideIcons.userPlus
                                    : LucideIcons.bell,
                                size: 20,
                                color:
                                    n.isRead
                                        ? AppColors.textMuted
                                        : AppColors.primary,
                              ),
                            ),
                            title: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight:
                                    n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${n.body}\n${DateFormat('dd.MM.yyyy HH:mm').format(n.createdAt.toLocal())}',
                            ),
                            isThreeLine: true,
                            trailing:
                                n.isRead
                                    ? null
                                    : Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                            onTap: () async {
                              final sheet = Navigator.of(ctx);
                              if (!n.isRead) {
                                try {
                                  await app.markNotificationAsRead(n.id);
                                } catch (_) {
                                  // Xabar o'qilmagan bo'lib qoladi — keyinroq qayta urinadi.
                                }
                              }
                              if (signup) {
                                sheet.pop();
                                if (mounted) setState(() => _selectedIndex = 1);
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    int alertCount, {
    UserRole? userRole,
    bool isDrawer = false,
  }) {
    final dashboard = _categories.first.items.first;
    final rest = _categories.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, isDrawer ? 20 : 22, 14, 6),
          child: Row(
            children: [
              const BrandMark(height: 46),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandWordmark(fontSize: 24),
                    const SizedBox(height: 2),
                    Text(
                      'Administrator menyusi',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDrawer)
                Material(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  child: IconButton(
                    tooltip: 'Yopish',
                    icon: Icon(LucideIcons.x, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              _DashboardEntry(
                title: dashboard.title,
                selected: _selectedIndex == dashboard.index,
                onTap: () => _select(dashboard.index, isDrawer),
              ),
              for (final cat in rest) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 22, 8, 6),
                  child: Text(
                    cat.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.5,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                for (var i = 0; i < cat.items.length; i++)
                  _MenuEntry(
                    icon: cat.items[i].icon,
                    title:
                        cat.items[i].index == 4 &&
                                userRole == UserRole.institutionAdmin
                            ? 'Mening muassasam'
                            : cat.items[i].title,
                    selected: _selectedIndex == cat.items[i].index,
                    badge:
                        cat.items[i].hasAlertBadge && alertCount > 0
                            ? alertCount
                            : null,
                    showDivider: i != cat.items.length - 1,
                    onTap: () => _select(cat.items[i].index, isDrawer),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _select(int index, bool isDrawer) {
    setState(() => _selectedIndex = index);
    if (isDrawer) Navigator.pop(context);
  }
}

/// Menyudagi "Boshqaruv paneli": yashil fonli ajratilgan qator.
class _DashboardEntry extends StatelessWidget {
  const _DashboardEntry({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.success : AppColors.textPrimary;
    return Material(
      color: selected ? AppColors.successBg : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(LucideIcons.house, color: fg, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, color: fg, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menyu qatori: chiziqli ikona, nom, o'q va ostida ingichka chiziq.
/// Tanlangani yashil.
class _MenuEntry extends StatelessWidget {
  const _MenuEntry({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.showDivider,
    this.badge,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.success : AppColors.textPrimary;
    return Material(
      color: selected ? AppColors.successBg : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected ? fg : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 19,
                    color: selected ? fg : AppColors.textMuted,
                  ),
                ],
              ),
            ),
            if (showDivider && !selected)
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
          ],
        ),
      ),
    );
  }
}

/// Profil belgisi: bosilganda ism, rol, email va amallar menyusi —
/// profilni tahrirlash, mutaxassis interfeysi va tizimdan chiqish.
class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Administrator';
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    return PopupMenuButton<String>(
      tooltip: 'Profil',
      offset: const Offset(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: AppColors.surface,
      onSelected: (v) async {
        switch (v) {
          case 'profile':
            if (user != null) await showProfileEditDialog(context, user!);
          case 'specialist':
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            );
          case 'logout':
            await confirmLogout(context);
        }
      },
      itemBuilder:
          (ctx) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.role.label ?? 'Tizim administratori',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if ((user?.email ?? '').isNotEmpty)
                      Text(
                        user!.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            _menuItem('profile', LucideIcons.userPen, 'Profilni tahrirlash'),
            _menuItem(
              'specialist',
              LucideIcons.arrowLeftRight,
              'Mutaxassis interfeysi',
            ),
            const PopupMenuDivider(),
            _menuItem(
              'logout',
              LucideIcons.logOut,
              'Tizimdan chiqish',
              color: AppColors.error,
            ),
          ],
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandBlueBright, AppColors.brandBlueDeep],
          ),
        ),
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 19,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final c = color ?? AppColors.textPrimary;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 19, color: c),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Telefonda pastki navigatsiya: Bosh sahifa, Monitoring, Foydalanuvchilar,
/// Sozlamalar. Qolgan bo'limlar yon menyuda.
class _AdminBottomBar extends StatelessWidget {
  const _AdminBottomBar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const _items = [
    (0, LucideIcons.house, 'Bosh sahifa'),
    (8, LucideIcons.chartColumn, 'Monitoring'),
    (1, LucideIcons.users, 'Foydalanuvchilar'),
    (9, LucideIcons.settings, 'Sozlamalar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: adminCardShadow(),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              for (final (index, icon, label) in _items)
                Expanded(
                  child: _BottomItem(
                    icon: icon,
                    label: label,
                    selected: selected == index,
                    onTap: () => onSelect(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : AppColors.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: fg),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
