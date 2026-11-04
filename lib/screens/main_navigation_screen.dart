import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_brand.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/brand_logo.dart';
import '../core/widgets/glass_widgets.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../models/workspace_model.dart';
import '../core/constants/specialist_workspaces.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import 'assessments/assessments_list_screen.dart';
import 'auth/logout_dialog.dart';
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
import 'psychologist/tabs/psychologist_assessments_tab.dart';
import 'psychologist/tabs/psychologist_dashboard_tab.dart';
import 'psychologist/tabs/psychologist_development_map_tab.dart';
import 'psychologist/tabs/psychologist_methods_tab.dart';
import 'psychologist/tabs/psychologist_observations_tab.dart';
import 'psychologist/tabs/psychologist_reports_tab.dart';
import 'psychologist/tabs/psychologist_sessions_tab.dart';
import 'psychologist/tabs/psychologist_students_tab.dart';
import 'psychologist/tabs/psychologist_support_plans_tab.dart';

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
  final GlobalKey _profileMenuKey = GlobalKey();
  int _selectedIndex = 0;
  bool _isMovingForward = true;
  bool _isDesktopSidebarOpen = true;

  static const List<_NavItemData> _baseNavItems = [
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

  /// Faqat psixolog kabinetida ko'rinadigan qo'shimcha bo'limlar
  static const List<_NavItemData> _psychologistNavItems = [
    _NavItemData(
      index: 10,
      title: 'Kuzatuvlar jurnali',
      shortLabel: 'Kuzatuv',
      group: 'PSIXOLOGIK XIZMAT',
      icon: LucideIcons.eye,
    ),
    _NavItemData(
      index: 11,
      title: 'Rivojlanish xaritasi',
      shortLabel: 'Rivojlanish',
      group: 'PSIXOLOGIK XIZMAT',
      icon: LucideIcons.trendingUp,
    ),
    _NavItemData(
      index: 12,
      title: 'Metodikalar',
      shortLabel: 'Metodika',
      group: 'PSIXOLOGIK XIZMAT',
      icon: LucideIcons.brain,
    ),
  ];

  /// Psixolog kabineti modullarining ichki tartibi -> menyu bandi raqami
  /// (0 bosh sahifa, 1 o'quvchilar, 2 baholash, 3 kuzatuv, 4 rivojlanish xaritasi,
  /// 5 qo'llab-quvvatlash rejalari, 6 metodikalar, 7 mashg'ulotlar, 8 hisobotlar)
  static const List<int> _psychTabToNavIndex = [0, 1, 2, 10, 11, 4, 12, 3, 6];

  StudentModel? _preselectedStudent;

  bool get _isPsychologist =>
      context.read<AuthProvider>().currentUser?.role == UserRole.psychologist;

  /// Menyuda bandlarning ko'rinish tartibi (yon panel guruhlari shu tartibda)
  static const List<int> _menuOrder = [0, 1, 2, 3, 4, 5, 8, 6, 7, 9, 10, 11, 12];

  UserRole? get _role => context.read<AuthProvider>().currentUser?.role;

  /// Band shu rol kabinetiga tegishlimi. Qoida backend'dagi kabinet ta'rifidan olinadi
  /// (SpecialistWorkspaces) — menyu va ruxsatlar doim bir xil bo'ladi.
  bool _canSee(int index) {
    final role = _role;
    if (role == null) return index == 0 || index == 9;
    final ws = SpecialistWorkspaces.forRole(role);
    bool any(List<WorkspaceModule> modules) => modules.any(ws.has);
    switch (index) {
      case 0: // Boshqaruv markazi
      case 9: // Sozlamalar (profil, parol)
        return true;
      case 1: // Bolalar
        return any(const [
          WorkspaceModule.caseload,
          WorkspaceModule.schoolMonitoring,
        ]);
      case 2: // Baholashlar
        return any(const [
          WorkspaceModule.psychAssessment,
          WorkspaceModule.speechAssessment,
          WorkspaceModule.developmentAssessment,
          WorkspaceModule.subjectLevel,
          WorkspaceModule.learningResults,
          WorkspaceModule.schoolMonitoring,
        ]);
      case 3:
        return ws.has(WorkspaceModule.sessions);
      case 4:
        return ws.has(WorkspaceModule.iep);
      case 5: // Monitoring: rahbariyat — maktab, mutaxassis — o'z bolalari
        return ws.has(WorkspaceModule.schoolMonitoring) || ws.worksWithChildren;
      case 6:
        return ws.has(WorkspaceModule.reports);
      case 7: // Mutaxassislar shtati — faqat rahbariyat va koordinator
        return any(const [
          WorkspaceModule.specialistAssignment,
          WorkspaceModule.userManagement,
        ]);
      case 8:
        return ws.has(WorkspaceModule.referrals);
      case 10:
      case 11:
        return role == UserRole.psychologist;
      case 12:
        return role == UserRole.psychologist ||
            role == UserRole.specialEducation;
      default:
        return false;
    }
  }

  /// Joriy foydalanuvchi ko'radigan menyu bandlari (menyu tartibida)
  List<_NavItemData> get _navItems {
    final all = {
      for (final i in [..._baseNavItems, ..._psychologistNavItems]) i.index: i,
    };
    return [
      for (final index in _menuOrder)
        if (all.containsKey(index) && _canSee(index)) all[index]!,
    ];
  }

  /// Joriy band (rol almashganda ko'rinmay qolsa — bosh sahifa)
  _NavItemData get _currentNavItem {
    final items = _navItems;
    return items.firstWhere(
      (i) => i.index == _selectedIndex,
      orElse: () => items.first,
    );
  }

  /// Yon panel guruhi nomi: "Boshqaruv va tizim" faqat rahbariyat uchun ma'noli
  String _groupLabel(String group) {
    final leadership = _canSee(7);
    if (group == 'BOSHQARUV VA TIZIM' && !leadership) return 'HISOBOT VA SOZLAMALAR';
    return group;
  }

  /// Psixolog modullari bir-biriga o'tganda (ixtiyoriy ravishda tanlangan bola bilan)
  void _openPsychTab(int psychIndex, {StudentModel? student}) {
    if (psychIndex < 0 || psychIndex >= _psychTabToNavIndex.length) return;
    if (student != null) _preselectedStudent = student;
    _selectTab(_psychTabToNavIndex[psychIndex]);
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

  void _selectTab(int index) {
    // Faollik qayd etiladi; sessiya muddati tugagan bo'lsa — qayta kirish so'raladi
    context.read<AuthProvider>().touchSession();
    if (_selectedIndex != index && _navItems.any((i) => i.index == index)) {
      setState(() {
        _isMovingForward = index > _selectedIndex;
        _selectedIndex = index;
      });
    }
  }

  /// Psixolog uchun mos bo'limlar uning kabinetidagi ixtisoslashtirilgan ekranlarni ochadi.
  /// null — umumiy ekran ishlatiladi.
  Widget? _buildPsychologistScreen() {
    final key = ValueKey('psy_tab_$_selectedIndex');
    switch (_selectedIndex) {
      case 0:
        return PsychologistDashboardTab(key: key, onNavigateToTab: _openPsychTab);
      case 1:
        return PsychologistStudentsTab(
          key: key,
          onSelectStudentForAssessment: (s) => _openPsychTab(2, student: s),
          onSelectStudentForObservation: (s) => _openPsychTab(3, student: s),
          onSelectStudentForSession: (s) => _openPsychTab(7, student: s),
        );
      case 2:
        return PsychologistAssessmentsTab(key: key, preselectedStudent: _preselectedStudent);
      case 3:
        return PsychologistSessionsTab(key: key);
      case 4:
        return PsychologistSupportPlansTab(key: key, preselectedStudent: _preselectedStudent);
      case 6:
        return PsychologistReportsTab(key: key);
      case 10:
        return PsychologistObservationsTab(key: key, preselectedStudent: _preselectedStudent);
      case 11:
        return PsychologistDevelopmentMapTab(key: key, initialStudent: _preselectedStudent);
      case 12:
        return PsychologistMethodsTab(key: key, onNavigateToTab: _openPsychTab);
      default:
        return null;
    }
  }

  Widget _buildActiveScreen() {
    if (!_canSee(_selectedIndex)) {
      return DashboardScreen(
        key: const ValueKey('tab_default'),
        onNavigateTab: _selectTab,
      );
    }
    if (_isPsychologist) {
      final psychScreen = _buildPsychologistScreen();
      if (psychScreen != null) {
        // Psixolog kabineti sahifalari umumiy sahifa konteyneridan foydalanmaydi —
        // ular ustki va pastki suzuvchi panellar ostida qolmasin.
        final width = MediaQuery.sizeOf(context).width;
        return Padding(
          key: psychScreen.key,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + (width >= 920 ? 82 : 74),
            bottom: width < 920 ? 84 : 0,
          ),
          child: psychScreen,
        );
      }
    }
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
      barrierColor: const Color(0x420A1A3F),
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
                borderRadius: 20,
                blur: 18,
                opacity: 0.96,
                boxShadow: AppColors.elevatedShadow,
                padding: const EdgeInsets.all(20),
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
                        prefixIcon: Icon(
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'TEZKOR NATIJALAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: results.isEmpty
                          ? Padding(
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
                                    horizontal: 15,
                                    vertical: 12,
                                  ),
                                  borderRadius: 12,
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
                                      Icon(
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
                                              style: TextStyle(
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
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
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
                        'Barcha tizim bo‘limlari',
                        style: TextStyle(
                          fontSize: 17.5,
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
                  children: _navItems.map((item) {
                    final isSel = _selectedIndex == item.index;
                    final badge = _badgeForIndex(item.index, app);

                    return SurfaceCard(
                      elevated: false,
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      backgroundColor: isSel
                          ? AppColors.primaryLight
                          : Colors.white,
                      borderColor: isSel
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
                                    isSel ? FontWeight.w700 : FontWeight.w600,
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
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$badge',
                                style: TextStyle(
                                  fontSize: 11,
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

  void _showProfileRightMenu(
    BuildContext context,
    UserModel? user,
    AuthProvider auth,
  ) {
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width >= 1024;

    final renderBox =
        _profileMenuKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero);
    final size = renderBox?.size;
    final topOffset =
        (offset?.dy ?? (media.padding.top + (isDesktop ? 14.0 : 8.0) + 6.0)) +
            (size?.height ?? 38.0) +
            8.0;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profil menyusi',
      barrierColor: Colors.black.withValues(alpha: 0.08),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              top: topOffset,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: _ProfileRightDropdownMenu(
                  user: user,
                  isDesktop: isDesktop,
                  onSettings: () {
                    Navigator.of(dialogCtx).pop();
                    _selectTab(9);
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
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
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
            blur: 18,
            opacity: 0.97,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                            Icon(
                              LucideIcons.bellRing,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Bildirishnomalar',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
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
                          ? Center(
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
                                  borderRadius: 14,
                                  padding: const EdgeInsets.all(15),
                                  borderColor: notif.isRead
                                      ? AppColors.border
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
                                                          : FontWeight.w700,
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
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: AppColors.textSecondary,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              df.format(notif.createdAt),
                                              style: TextStyle(
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
    final currentNav = _currentNavItem;

    return AmbientMeshBackground(
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: !isDesktop,
        backgroundColor: Colors.transparent,
        drawer: isDesktop ? null : _buildMobileDrawer(context, auth, app, user),
        body: Row(
          children: [
            if (isDesktop && _isDesktopSidebarOpen)
              _buildDesktopGlassSidebar(context, auth, app, user),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: PageTransitionSwitcher(
                      duration: const Duration(milliseconds: 280),
                      reverse: !_isMovingForward,
                      transitionBuilder:
                          (child, primaryAnimation, secondaryAnimation) {
                        return SharedAxisTransition(
                          animation: primaryAnimation,
                          secondaryAnimation: secondaryAnimation,
                          transitionType: SharedAxisTransitionType.horizontal,
                          fillColor: Colors.transparent,
                          child: child,
                        );
                      },
                      child: _buildActiveScreen(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopGlassHeader(
                      context: context,
                      isDesktop: isDesktop,
                      currentNav: currentNav,
                      user: user,
                      auth: auth,
                      unreadNotifCount: unreadNotifCount,
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
            child: Icon(
              icon,
              size: 18.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
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
    final showMenuIsland = !isDesktop || !_isDesktopSidebarOpen;
    final mediaPadding = MediaQuery.paddingOf(context);
    const menuIslandRadius = BorderRadius.only(
      topLeft: Radius.zero,
      bottomLeft: Radius.zero,
      topRight: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );
    const mainBarRadius = BorderRadius.only(
      topLeft: Radius.circular(28),
      bottomLeft: Radius.circular(28),
      topRight: Radius.zero,
      bottomRight: Radius.zero,
    );

    return SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          showMenuIsland ? 0 : 20,
          isDesktop ? 14 : 8,
          0,
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
                    (isDesktop ? 24 : 12) + mediaPadding.right,
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
                                  currentNav.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              else
                                const BrandWordmark(fontSize: 15),
                              Text(
                                user?.institutionName ??
                                    '9-sonli inklyuziv ta’lim tayanch maktabi',
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
                        if (isDesktop)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () => _showQuickSearchModal(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.glassWellFill,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
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
                          _buildHeaderIconAction(
                            icon: LucideIcons.search,
                            tooltip: 'Qidirish',
                            onTap: () => _showQuickSearchModal(context),
                          ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildHeaderIconAction(
                              icon: LucideIcons.bell,
                              tooltip: 'Bildirishnomalar',
                              onTap: () => _showNotificationsSheet(context),
                            ),
                            if (unreadNotifCount > 0)
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
                                      '$unreadNotifCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
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
                          onTap: () => _showProfileRightMenu(context, user, auth),
                          pressedScale: 0.95,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 11 : 5,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.glassWellFill,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 13.5,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    (user?.fullName ?? 'U').substring(0, 1),
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
                                      maxWidth: 145,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user?.fullName ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          user?.role.label ?? '',
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

  Widget _buildDesktopGlassSidebar(
    BuildContext context,
    AuthProvider auth,
    AppProvider app,
    UserModel? user,
  ) {
    final groups = <String, List<_NavItemData>>{};
    for (final item in _navItems) {
      groups.putIfAbsent(_groupLabel(item.group), () => []).add(item);
    }

    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
        child: SizedBox(
          width: 260,
          child: GlassSurface(
            borderRadius: 20,
            blur: 16,
            opacity: 0.95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header (free-standing icon + collapse toggle)
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
                            BrandWordmark(fontSize: 18),
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
                      _buildHeaderIconAction(
                        icon: LucideIcons.panelLeftClose,
                        tooltip: 'Menyuni yig‘ish',
                        onTap: () =>
                            setState(() => _isDesktopSidebarOpen = false),
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
                                style: TextStyle(
                                  fontSize: 11,
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
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _selectTab(item.index),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 13,
                                        vertical: 10.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primaryLight
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryTint
                                              : Colors.transparent,
                                          width: 1.0,
                                        ),
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
                                                    ? FontWeight.w700
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
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isAlertBadge
                                                      ? AppColors.errorBorder
                                                      : AppColors.border,
                                                  width: 0.85,
                                                ),
                                              ),
                                              child: Text(
                                                '$badge',
                                                style: TextStyle(
                                                  fontSize: 11,
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
                    vertical: 11,
                  ),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      Icon(
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Himoyalangan tizim',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFrostedBottomBar(BuildContext context, AppProvider app) {
    final quickTabs = _navItems.take(4).toList();
    final isMoreActive = _selectedIndex >= 4;
    final mediaPadding = MediaQuery.paddingOf(context);

    const leftIslandRadius = BorderRadius.only(
      topLeft: Radius.zero,
      bottomLeft: Radius.zero,
      topRight: Radius.circular(28),
      bottomRight: Radius.circular(28),
    );
    const rightIslandRadius = BorderRadius.only(
      topLeft: Radius.circular(28),
      bottomLeft: Radius.circular(28),
      topRight: Radius.zero,
      bottomRight: Radius.zero,
    );

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          height: 54,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Chap tarafga yopishgan asosiy kengayuvchi Island
              Expanded(
                flex: isMoreActive ? 14 : 23,
                child: GlassSurface(
                  customBorderRadius: leftIslandRadius,
                  borderColor: AppColors.navGlassBorder,
                  useBlur: true,
                  blur: 24,
                  opacity: AppColors.navGlassOpacity,
                  boxShadow: AppColors.navShadow,
                  padding: EdgeInsets.fromLTRB(
                    mediaPadding.left + 5,
                    5,
                    5,
                    5,
                  ),
                  child: ClipRRect(
                    borderRadius: leftIslandRadius,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: quickTabs.map((item) {
                        final isSelected =
                            !isMoreActive && _selectedIndex == item.index;
                        const pillRadius = BorderRadius.all(Radius.circular(20));

                        return Expanded(
                          flex: isSelected ? 22 : 10,
                          child: TactileBounce(
                            onTap: () => _selectTab(item.index),
                            pressedScale: 0.92,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected ? 12 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: pillRadius,
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.22),
                                        width: 1.0,
                                      )
                                    : null,
                              ),
                              child: isSelected
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 19,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            item.shortLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Center(
                                      child: Icon(
                                        item.icon,
                                        size: 19.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                            ),
                          ),
                        );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              // 2. O'ng tarafga yopishgan "Barchasi" Island
              Expanded(
                flex: isMoreActive ? 16 : 7,
                child: GlassSurface(
                  customBorderRadius: rightIslandRadius,
                  borderColor: isMoreActive
                      ? AppColors.primary.withValues(alpha: 0.28)
                      : AppColors.navGlassBorder,
                  useBlur: true,
                  blur: 24,
                  opacity: AppColors.navGlassOpacity,
                  boxShadow: AppColors.navShadow,
                  padding: EdgeInsets.fromLTRB(
                    5,
                    5,
                    mediaPadding.right + 5,
                    5,
                  ),
                  child: ClipRRect(
                    borderRadius: rightIslandRadius,
                    child: TactileBounce(
                      onTap: () => _showMobileModulesSheet(context, app),
                      pressedScale: 0.94,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMoreActive ? 12 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: isMoreActive
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                          border: isMoreActive
                              ? Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.22),
                                  width: 1.0,
                                )
                              : null,
                        ),
                          child: isMoreActive
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _currentNavItem.icon,
                                      size: 19,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 7),
                                    Flexible(
                                      child: Text(
                                        _currentNavItem.shortLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                      if (app.alerts.any((a) => !a.isResolved))
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
                      BrandMark(height: 32),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BrandWordmark(fontSize: 18),
                            Text(
                              AppBrand.tagline,
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
                    borderRadius: 14,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            (user?.fullName ?? 'U').substring(0, 1),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isSel
                          ? AppColors.primaryLight
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
                              isSel ? FontWeight.w700 : FontWeight.w600,
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
                  Expanded(
                    child: Text(
                      '${AppBrand.name} • v1.0.0',
                      style: TextStyle(
                        fontSize: 11.5,
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

/// O'ng tarafga to'liq yopishgan va shishasimon (glassy) profil menyusi
class _ProfileRightDropdownMenu extends StatelessWidget {
  final UserModel? user;
  final bool isDesktop;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _ProfileRightDropdownMenu({
    required this.user,
    required this.isDesktop,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(22),
      bottomLeft: Radius.circular(22),
      topRight: Radius.zero,
      bottomRight: Radius.zero,
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
                    user?.fullName ?? 'Mutaxassis',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3.5),
                  Text(
                    user?.role.label ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 0.85,
              color: Color(0x180A1A3F),
              indent: 14,
              endIndent: 0,
            ),
            const SizedBox(height: 4),
            _buildMenuItem(
              icon: LucideIcons.settings,
              iconColor: AppColors.textSecondary,
              label: 'Sozlamalar',
              textColor: AppColors.textPrimary,
              onTap: onSettings,
            ),
            _buildMenuItem(
              icon: LucideIcons.logOut,
              iconColor: AppColors.error,
              label: 'Tizimdan chiqish',
              textColor: AppColors.error,
              isDestructive: true,
              onTap: onLogout,
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return TactileBounce(
      onTap: onTap,
      pressedScale: 0.965,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16.5, color: iconColor),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isDestructive ? FontWeight.w700 : FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.1,
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
