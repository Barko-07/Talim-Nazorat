import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../main_navigation_screen.dart';
import '../auth/logout_dialog.dart';
import '../referrals/referrals_screen.dart';

import 'server/server_institutions_tab.dart';
import 'server/server_history_tab.dart';
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

// Administrator paneli — mutaxassislar ilovasining ramkasi asosida (suzuvchi
// shishasimon yon menyu, yuqori panel, telefonda pastki "orolcha" menyu).
// Sahifalarning o'zi va ularning funksiyalari o'zgarmagan.

class _AdminNavCategory {
  final String title;
  final List<_AdminNavItemData> items;
  const _AdminNavCategory(this.title, this.items);
}

class _AdminNavItemData {
  final int index;
  final String title;
  final String shortLabel;
  final IconData icon;
  final bool hasAlertBadge;
  const _AdminNavItemData({
    required this.index,
    required this.title,
    required this.shortLabel,
    required this.icon,
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
  final GlobalKey _profileMenuKey = GlobalKey();
  late int _selectedIndex;
  bool _isDesktopSidebarOpen = true;

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
        shortLabel: 'Boshqaruv',
        icon: LucideIcons.layoutDashboard,
      ),
    ]),
    _AdminNavCategory('Monitoring va tahlil', [
      _AdminNavItemData(
        index: 8,
        title: 'Monitoring markazi',
        shortLabel: 'Monitoring',
        icon: LucideIcons.shieldAlert,
        hasAlertBadge: true,
      ),
      _AdminNavItemData(
        index: 7,
        title: 'Tahliliy hisobotlar',
        shortLabel: 'Hisobotlar',
        icon: LucideIcons.chartColumn,
      ),
    ]),
    _AdminNavCategory('Reyestrlar va kadrlar', [
      _AdminNavItemData(
        index: 3,
        title: 'O‘quvchilar reyestri',
        shortLabel: 'O‘quvchilar',
        icon: LucideIcons.users,
      ),
      _AdminNavItemData(
        index: 2,
        title: 'Pedagog-mutaxassislar',
        shortLabel: 'Mutaxassislar',
        icon: LucideIcons.userCheck,
      ),
      _AdminNavItemData(
        index: 4,
        title: 'Ta’lim muassasalari',
        shortLabel: 'Muassasalar',
        icon: LucideIcons.building2,
      ),
      _AdminNavItemData(
        index: 5,
        title: 'Sinflar va guruhlar',
        shortLabel: 'Sinflar',
        icon: LucideIcons.school,
      ),
      _AdminNavItemData(
        index: 11,
        title: 'Yo‘naltirishlar jurnali',
        shortLabel: 'Yo‘naltirish',
        icon: LucideIcons.arrowLeftRight,
      ),
    ]),
    _AdminNavCategory('Xavfsizlik va ma’muriyat', [
      _AdminNavItemData(
        index: 1,
        title: 'Foydalanuvchilar',
        shortLabel: 'Foydalanuvchi',
        icon: LucideIcons.userCog,
      ),
      _AdminNavItemData(
        index: 6,
        title: 'Rollar va ruxsatlar',
        shortLabel: 'Rollar',
        icon: LucideIcons.shieldCheck,
      ),
      _AdminNavItemData(
        index: 10,
        title: 'Audit jurnali',
        shortLabel: 'Audit',
        icon: LucideIcons.scrollText,
      ),
      _AdminNavItemData(
        index: 9,
        title: 'Tizim sozlamalari',
        shortLabel: 'Sozlamalar',
        icon: LucideIcons.settings2,
      ),
    ]),
  ];

  /// Telefonda pastki menyudagi tezkor bo'limlar; qolganlari "Barchasi"da.
  static const _quickIndexes = [0, 1, 3, 8];

  List<_AdminNavItemData> get _allItems => [
    for (final c in _categories) ...c.items,
  ];

  _AdminNavItemData get _currentItem => _allItems.firstWhere(
    (i) => i.index == _selectedIndex,
    orElse: () => _allItems.first,
  );

  String _itemTitle(_AdminNavItemData item, UserModel? user) =>
      item.index == 4 && user?.role == UserRole.institutionAdmin
          ? 'Mening muassasam'
          : item.title;

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  String _portalSubtitle(UserModel? user) {
    if (user?.role == UserRole.institutionAdmin) {
      return user?.institutionName ?? 'Muassasa ma’muriyati';
    }
    if (user?.role == UserRole.reviewer) {
      return 'Namangan viloyat ta’lim sifatini monitoring qilish markazi';
    }
    return 'Maktabgacha va maktab ta’limi vazirligi • Namangan viloyati';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 920;
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser;
    final alertCount = app.unresolvedAlerts.length;

    // Kirgan zahoti AppProvider'ga foydalanuvchi keyingi kadrda o'rnatiladi;
    // shungacha sahifalar "tizimga kirilmagan" xatosini bermasin.
    if (user != null && app.currentUser?.id != user.id) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> screens = [
      AdminOverviewTab(onNavigateTab: _selectTab),
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

    return AmbientMeshBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer:
            isDesktop ? null : _buildMobileDrawer(context, user, alertCount),
        body: Row(
          children: [
            if (isDesktop && _isDesktopSidebarOpen)
              _buildDesktopSidebar(context, user, alertCount),
            Expanded(
              child: Column(
                children: [
                  _buildTopHeader(
                    context: context,
                    isDesktop: isDesktop,
                    user: user,
                    unread: app.myUnreadNotificationCount,
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey('admin_tab_$_selectedIndex'),
                      child:
                          screens[_selectedIndex.clamp(0, screens.length - 1)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar:
            isDesktop ? null : _buildMobileBottomBar(context, alertCount),
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _buildHeaderIconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: TactileBounce(
        onTap: onTap,
        pressedScale: 0.88,
        child: SizedBox(
          width: 35,
          height: 35,
          child: Center(
            child: Icon(icon, size: 18.5, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader({
    required BuildContext context,
    required bool isDesktop,
    required UserModel? user,
    required int unread,
  }) {
    final showMenuIsland = !isDesktop || !_isDesktopSidebarOpen;
    final mediaPadding = MediaQuery.paddingOf(context);
    const menuIslandRadius = BorderRadius.only(
      topRight: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );
    final mainBarRadius =
        isDesktop
            ? BorderRadius.circular(20)
            : const BorderRadius.only(
              topLeft: Radius.circular(28),
              bottomLeft: Radius.circular(28),
            );

    return SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          showMenuIsland ? 0 : 16,
          isDesktop ? 16 : 8,
          isDesktop ? 16 : 0,
          6,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showMenuIsland) ...[
                GlassSurface(
                  customBorderRadius: menuIslandRadius,
                  borderColor: AppColors.navGlassBorder,
                  useBlur: true,
                  blur: 24,
                  opacity: AppColors.navGlassOpacity,
                  boxShadow: AppColors.navShadow,
                  padding: EdgeInsets.zero,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: menuIslandRadius,
                      onTap: () {
                        if (isDesktop) {
                          setState(() => _isDesktopSidebarOpen = true);
                        } else {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 54),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            15 + mediaPadding.left,
                            0,
                            18,
                            0,
                          ),
                          child: Center(
                            child: Tooltip(
                              message: 'Menyu',
                              child: Icon(
                                LucideIcons.panelLeft,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 10),
              ],
              Expanded(
                child: GlassSurface(
                  customBorderRadius: mainBarRadius,
                  borderColor: AppColors.navGlassBorder,
                  useBlur: true,
                  blur: 24,
                  opacity: AppColors.navGlassOpacity,
                  boxShadow: AppColors.navShadow,
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 22 : 16,
                    8,
                    (isDesktop ? 14 : 12) + mediaPadding.right,
                    8,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 38),
                    child: Row(
                      children: [
                        if (showMenuIsland) ...[
                          const BrandMark(height: 26),
                          const SizedBox(width: 9),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isDesktop)
                                Text(
                                  _itemTitle(_currentItem, user),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              else
                                const BrandWordmark(fontSize: 15.5),
                              Text(
                                _portalSubtitle(user),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Mutaxassis ko'rinishiga o'tish (avvalgidek)
                        if (isDesktop)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () => _openSpecialistView(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.glassWellFill,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.arrowLeftRight,
                                      size: 15,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mutaxassis interfeysi',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          _buildHeaderIconAction(
                            icon: LucideIcons.arrowLeftRight,
                            tooltip: 'Mutaxassis interfeysi',
                            onTap: () => _openSpecialistView(context),
                          ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildHeaderIconAction(
                              icon: LucideIcons.bell,
                              tooltip: 'Bildirishnomalar',
                              onTap: () => _showNotificationsSheet(context),
                            ),
                            if (unread > 0)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: IgnorePointer(
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
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                    ),
                                    child: Text(
                                      '$unread',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 5),
                        TactileBounce(
                          key: _profileMenuKey,
                          onTap: () => _showProfileMenu(context, user),
                          pressedScale: 0.95,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 11 : 5,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.glassWellFill,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 13.5,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    _initial(user),
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (isDesktop) ...[
                                  const SizedBox(width: 9),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 160,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user?.fullName ?? 'Administrator',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          user?.role.label ??
                                              'Tizim administratori',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Icon(
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
            ],
          ),
        ),
      ),
    );
  }

  static String _initial(UserModel? user) {
    final name = (user?.fullName ?? 'A').trim();
    return name.isEmpty ? 'A' : name.substring(0, 1).toUpperCase();
  }

  void _openSpecialistView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  // ---------------------------------------------------------------- sidebar

  Widget _buildNavRow(
    _AdminNavItemData item,
    UserModel? user,
    int alertCount, {
    VoidCallback? afterTap,
  }) {
    final isSelected = _selectedIndex == item.index;
    final badge = item.hasAlertBadge && alertCount > 0 ? alertCount : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _selectTab(item.index);
            afterTap?.call();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10.5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryTint : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18.5,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _itemTitle(item, user),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7.5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.errorBorder,
                        width: 0.85,
                      ),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavGroups(
    UserModel? user,
    int alertCount, {
    VoidCallback? afterTap,
  }) {
    return [
      for (final cat in _categories)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  cat.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: AppColors.textSubtle,
                  ),
                ),
              ),
              for (final item in cat.items)
                _buildNavRow(item, user, alertCount, afterTap: afterTap),
            ],
          ),
        ),
    ];
  }

  Widget _buildSecureFooter(UserModel? user) {
    return GlassWell(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      borderRadius: 12,
      child: Row(
        children: [
          Icon(LucideIcons.shieldCheck, size: 19, color: AppColors.success),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.role.label ?? 'Tizim administratori',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Himoyalangan boshqaruv',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    UserModel? user,
    int alertCount,
  ) {
    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
        child: SizedBox(
          width: 264,
          child: GlassSurface(
            borderRadius: 20,
            blur: 16,
            opacity: 0.95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 14, 16),
                  child: Row(
                    children: [
                      const BrandMark(height: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const BrandWordmark(fontSize: 17),
                            Text(
                              'Administrator paneli',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildHeaderIconAction(
                        icon: LucideIcons.panelLeftClose,
                        tooltip: 'Menyuni yig‘ish',
                        onTap:
                            () => setState(() => _isDesktopSidebarOpen = false),
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
                    children: _buildNavGroups(user, alertCount),
                  ),
                ),
                _buildSecureFooter(user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    UserModel? user,
    int alertCount,
  ) {
    return Drawer(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const BrandMark(height: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const BrandWordmark(fontSize: 17),
                            Text(
                              'Administrator paneli',
                              style: TextStyle(
                                fontSize: 12,
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
                    borderRadius: 14,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            _initial(user),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Administrator',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.role.label ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
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
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                children: _buildNavGroups(
                  user,
                  alertCount,
                  afterTap: () => Navigator.pop(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Individ • Administrator',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => confirmLogout(context),
                    icon: Icon(
                      LucideIcons.logOut,
                      size: 15,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Chiqish',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
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

  // ---------------------------------------------------------------- phone bar

  Widget _buildMobileBottomBar(BuildContext context, int alertCount) {
    final quick = [
      for (final i in _quickIndexes) _allItems.firstWhere((n) => n.index == i),
    ];
    final isMoreActive = !_quickIndexes.contains(_selectedIndex);
    final mediaPadding = MediaQuery.paddingOf(context);
    const leftIslandRadius = BorderRadius.only(
      topRight: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );
    const rightIslandRadius = BorderRadius.only(
      topLeft: Radius.circular(28),
      bottomLeft: Radius.circular(28),
    );
    const pillRadius = BorderRadius.all(Radius.circular(20));

    Widget pill({
      required bool selected,
      required IconData icon,
      required String label,
    }) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: selected ? 12 : 4),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
          borderRadius: pillRadius,
          border:
              selected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.22))
                  : null,
        ),
        child:
            selected
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 19, color: AppColors.primary),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                )
                : Center(
                  child: Icon(icon, size: 19.5, color: AppColors.textMuted),
                ),
      );
    }

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: isMoreActive ? 14 : 23,
                child: GlassSurface(
                  customBorderRadius: leftIslandRadius,
                  borderColor: AppColors.navGlassBorder,
                  useBlur: true,
                  blur: 24,
                  opacity: AppColors.navGlassOpacity,
                  boxShadow: AppColors.navShadow,
                  padding: EdgeInsets.fromLTRB(mediaPadding.left + 5, 5, 5, 5),
                  child: ClipRRect(
                    borderRadius: leftIslandRadius,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in quick)
                          Expanded(
                            flex:
                                !isMoreActive && _selectedIndex == item.index
                                    ? 22
                                    : 10,
                            child: Tooltip(
                              message: item.title,
                              child: TactileBounce(
                                onTap: () => _selectTab(item.index),
                                pressedScale: 0.92,
                                child: pill(
                                  selected:
                                      !isMoreActive &&
                                      _selectedIndex == item.index,
                                  icon: item.icon,
                                  label: item.shortLabel,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: isMoreActive ? 16 : 7,
                child: GlassSurface(
                  customBorderRadius: rightIslandRadius,
                  borderColor:
                      isMoreActive
                          ? AppColors.primary.withValues(alpha: 0.28)
                          : AppColors.navGlassBorder,
                  useBlur: true,
                  blur: 24,
                  opacity: AppColors.navGlassOpacity,
                  boxShadow: AppColors.navShadow,
                  padding: EdgeInsets.fromLTRB(5, 5, mediaPadding.right + 5, 5),
                  child: ClipRRect(
                    borderRadius: rightIslandRadius,
                    child: Tooltip(
                      message: 'Barcha bo‘limlar',
                      child: TactileBounce(
                        onTap: () => _showModulesSheet(context, alertCount),
                        pressedScale: 0.94,
                        child:
                            isMoreActive
                                ? pill(
                                  selected: true,
                                  icon: _currentItem.icon,
                                  label: _currentItem.shortLabel,
                                )
                                : Center(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        LucideIcons.layoutGrid,
                                        size: 20,
                                        color: AppColors.textPrimary,
                                      ),
                                      if (alertCount > 0)
                                        Positioned(
                                          top: -2,
                                          right: -3,
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Barchasi": hamma admin bo'limlari ikki ustunli to'rda.
  void _showModulesSheet(BuildContext context, int alertCount) {
    final user = context.read<AuthProvider>().currentUser;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => GlassSurface(
            borderRadius: 26,
            blur: 18,
            opacity: 0.97,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
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
                        Icon(
                          LucideIcons.layoutGrid,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Barcha boshqaruv bo‘limlari',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
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
                      children: [
                        for (final item in _allItems)
                          SurfaceCard(
                            elevated: false,
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            backgroundColor:
                                _selectedIndex == item.index
                                    ? AppColors.primaryLight
                                    : AppColors.surface,
                            borderColor:
                                _selectedIndex == item.index
                                    ? AppColors.primary.withValues(alpha: 0.35)
                                    : AppColors.border,
                            onTap: () {
                              Navigator.pop(ctx);
                              _selectTab(item.index);
                            },
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 19,
                                  color:
                                      _selectedIndex == item.index
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _itemTitle(item, user),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _selectedIndex == item.index
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (item.hasAlertBadge && alertCount > 0)
                                  StatusPill(
                                    label: '$alertCount',
                                    color: AppColors.error,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // ---------------------------------------------------------------- menus

  void _showProfileMenu(BuildContext context, UserModel? user) {
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width >= 920;
    final box =
        _profileMenuKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = box?.localToGlobal(Offset.zero);
    final top =
        (offset?.dy ?? (media.padding.top + 20)) + (box?.size.height ?? 38) + 8;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profil menyusi',
      barrierColor: Colors.black.withValues(alpha: 0.08),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogCtx, _, _) {
        return Stack(
          children: [
            Positioned(
              top: top,
              right: isDesktop ? 16 : 0,
              child: Material(
                color: Colors.transparent,
                child: _AdminProfileMenu(
                  user: user,
                  isDesktop: isDesktop,
                  onSettings: () {
                    Navigator.of(dialogCtx).pop();
                    _selectTab(9);
                  },
                  onSpecialistView: () {
                    Navigator.of(dialogCtx).pop();
                    _openSpecialistView(context);
                  },
                  onLogout: () {
                    Navigator.of(dialogCtx).pop();
                    confirmLogout(context);
                  },
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (dialogCtx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  /// Bildirishnomalar: shu administratorga kelganlari (masalan yangi
  /// ro'yxatdan o'tish). Bosilgani o'qilgan bo'ladi; ro'yxatdan o'tish xabari
  /// "Foydalanuvchilar" bo'limini ochadi.
  void _showNotificationsSheet(BuildContext context) {
    final df = DateFormat('dd.MM HH:mm');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Consumer<AppProvider>(
            builder: (ctx, app, _) {
              final items = [...app.myNotifications]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return GlassSurface(
                borderRadius: 26,
                blur: 18,
                opacity: 0.97,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        Row(
                          children: [
                            Icon(
                              LucideIcons.bell,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bildirishnomalar',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
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
                        const SizedBox(height: 10),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            child: Text(
                              'Hozircha bildirishnoma yo‘q. Kimdir ro‘yxatdan o‘tsa, shu yerda ko‘rinadi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        else
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder:
                                  (_, _) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final n = items[i];
                                final signup = n.type == 'SIGNUP';
                                return SurfaceCard(
                                  elevated: false,
                                  borderRadius: 14,
                                  padding: const EdgeInsets.all(14),
                                  backgroundColor:
                                      n.isRead
                                          ? AppColors.surface
                                          : AppColors.primaryLight,
                                  borderColor:
                                      n.isRead
                                          ? AppColors.border
                                          : AppColors.primaryTint,
                                  onTap: () async {
                                    final sheet = Navigator.of(ctx);
                                    if (!n.isRead) {
                                      try {
                                        await app.markNotificationAsRead(n.id);
                                      } catch (_) {
                                        // keyinroq qayta urinadi
                                      }
                                    }
                                    if (signup) {
                                      sheet.pop();
                                      if (mounted) _selectTab(1);
                                    }
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        signup
                                            ? LucideIcons.userPlus
                                            : LucideIcons.bell,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    n.isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              n.body,
                                              style: TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              df.format(n.createdAt.toLocal()),
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
}

/// Profil menyusi (mutaxassislar ilovasidagi bilan bir xil ko'rinishda).
class _AdminProfileMenu extends StatelessWidget {
  final UserModel? user;
  final bool isDesktop;
  final VoidCallback onSettings;
  final VoidCallback onSpecialistView;
  final VoidCallback onLogout;

  const _AdminProfileMenu({
    required this.user,
    required this.isDesktop,
    required this.onSettings,
    required this.onSpecialistView,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final radius =
        isDesktop
            ? BorderRadius.circular(18)
            : const BorderRadius.only(
              topLeft: Radius.circular(22),
              bottomLeft: Radius.circular(22),
            );
    return GlassSurface(
      customBorderRadius: radius,
      borderColor: AppColors.navGlassBorder,
      useBlur: true,
      blur: 24,
      opacity: AppColors.navGlassOpacity,
      boxShadow: AppColors.navShadow,
      padding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: isDesktop ? 260 : 235,
          maxWidth: isDesktop ? 285 : 260,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.fullName ?? 'Administrator',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3.5),
                  Text(
                    user?.role.label ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 14),
            const SizedBox(height: 4),
            _item(
              LucideIcons.arrowLeftRight,
              AppColors.textSecondary,
              'Mutaxassis interfeysi',
              AppColors.textPrimary,
              onSpecialistView,
            ),
            _item(
              LucideIcons.settings,
              AppColors.textSecondary,
              'Tizim sozlamalari',
              AppColors.textPrimary,
              onSettings,
            ),
            _item(
              LucideIcons.logOut,
              AppColors.error,
              'Tizimdan chiqish',
              AppColors.error,
              onLogout,
              bold: true,
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _item(
    IconData icon,
    Color iconColor,
    String label,
    Color textColor,
    VoidCallback onTap, {
    bool bold = false,
  }) {
    return TactileBounce(
      onTap: onTap,
      pressedScale: 0.965,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16.5, color: iconColor),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: textColor,
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
