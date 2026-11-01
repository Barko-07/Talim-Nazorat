import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import 'auth/login_screen.dart';
import 'admin/admin_portal_screen.dart';
import 'students/student_detail_screen.dart';

// Psixolog portali 9 ta ixtisoslashgan bo'limlari
import 'psychologist/tabs/psychologist_dashboard_tab.dart';
import 'psychologist/tabs/psychologist_students_tab.dart';
import 'psychologist/tabs/psychologist_assessments_tab.dart';
import 'psychologist/tabs/psychologist_observations_tab.dart';
import 'psychologist/tabs/psychologist_development_map_tab.dart';
import 'psychologist/tabs/psychologist_support_plans_tab.dart';
import 'psychologist/tabs/psychologist_methods_tab.dart';
import 'psychologist/tabs/psychologist_sessions_tab.dart';
import 'psychologist/tabs/psychologist_reports_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  StudentModel? _preselectedStudent;

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

  void _navigateToTab(int index, {StudentModel? student}) {
    if (index >= 0 && index < 9) {
      setState(() {
        _selectedIndex = index;
        if (student != null) _preselectedStudent = student;
      });
    }
  }

  void _showNotificationsSheet(BuildContext context) {
    final app = context.read<AppProvider>();
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            final auth = context.read<AuthProvider>();
                            if (auth.currentUser != null) {
                              await app.markAllNotificationsAsRead(auth.currentUser!.id);
                              setSheetState(() {});
                            }
                          },
                          child: const Text('Barchasini o‘qilgan qilish'),
                        ),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: notifications.isEmpty
                        ? const Center(
                            child: Text(
                              'Yangi bildirishnomalar mavjud emas',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
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

  // Psixolog portali uchun 9 ta ixtisoslashtirilgan menyu bo'limlari
  final List<Map<String, dynamic>> _navItems = const [
    {
      'title': 'Bosh sahifa',
      'subtitle': 'Vazifalar va uchrashuvlar',
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard_rounded,
    },
    {
      'title': 'O‘quvchilar',
      'subtitle': 'Biriktirilgan bolalar',
      'icon': Icons.people_outline_rounded,
      'activeIcon': Icons.people_rounded,
    },
    {
      'title': 'Baholash',
      'subtitle': 'Metodika bo‘yicha qayd',
      'icon': Icons.quiz_outlined,
      'activeIcon': Icons.quiz_rounded,
    },
    {
      'title': 'Kuzatuv jurnali',
      'subtitle': 'Xulq-atvor va emotsiyalar',
      'icon': Icons.menu_book_outlined,
      'activeIcon': Icons.menu_book_rounded,
    },
    {
      'title': 'Rivojlanish xaritasi',
      'subtitle': 'Vaqt davomidagi dinamika',
      'icon': Icons.insights_rounded,
      'activeIcon': Icons.insights_rounded,
    },
    {
      'title': 'Yordam rejalari',
      'subtitle': 'Psixologik ITR maqsadlari',
      'icon': Icons.task_alt_outlined,
      'activeIcon': Icons.task_alt_rounded,
    },
    {
      'title': 'Metodikalar',
      'subtitle': 'Testlar va qo‘llanmalar',
      'icon': Icons.psychology_outlined,
      'activeIcon': Icons.psychology_rounded,
    },
    {
      'title': 'Mashg‘ulotlar',
      'subtitle': 'Korreksiya va suhbatlar',
      'icon': Icons.calendar_month_outlined,
      'activeIcon': Icons.calendar_month_rounded,
    },
    {
      'title': 'Hisobotlar',
      'subtitle': 'Faoliyat tahlili va CSV',
      'icon': Icons.bar_chart_outlined,
      'activeIcon': Icons.bar_chart_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    final auth = context.watch<AuthProvider>();
    final app = context.watch<AppProvider>();
    final user = auth.currentUser;
    final unreadNotifCount = app.myUnreadNotificationCount;

    // 9 ta ixtisoslashtirilgan ekranlar ro'yxati
    final screens = [
      PsychologistDashboardTab(
        onNavigateToTab: _navigateToTab,
      ),
      PsychologistStudentsTab(
        onSelectStudentForAssessment: (s) => _navigateToTab(2, student: s),
        onSelectStudentForObservation: (s) => _navigateToTab(3, student: s),
        onSelectStudentForSession: (s) => _navigateToTab(7, student: s),
      ),
      PsychologistAssessmentsTab(preselectedStudent: _preselectedStudent),
      const PsychologistObservationsTab(),
      PsychologistDevelopmentMapTab(initialStudent: _preselectedStudent),
      const PsychologistSupportPlansTab(),
      PsychologistMethodsTab(
        onNavigateToTab: _navigateToTab,
      ),
      const PsychologistSessionsTab(),
      const PsychologistReportsTab(),
    ];

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
                Icons.psychology_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          'PSIXOLOG PORTALI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    user?.institutionName ?? 'Chortoq tumani 1-sonli ixtisoslashtirilgan maktab-internati',
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
          // Agar SuperAdmin kirgan bo'lsa, Administrator portaliga o'tish imkoniyati
          if (user?.role == UserRole.superAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF073A82),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const AdminPortalScreen(),
                    ),
                    (r) => false,
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                label: const Text(
                  'Admin Portali',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(width: 6),

          // Bildirishnomalar
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

          // Foydalanuvchi menyusi
          PopupMenuButton<String>(
            tooltip: 'Foydalanuvchi profili',
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
                          user?.fullName ?? 'Dilnoza Usmonova',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user?.specialization ?? 'Maktab amaliyotchi psixologi',
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
              if (val == 'admin_portal') {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const AdminPortalScreen(),
                  ),
                  (r) => false,
                );
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
                  '${user?.fullName}\n${user?.specialization ?? user?.role.label}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              if (user?.role == UserRole.superAdmin)
                const PopupMenuItem(
                  value: 'admin_portal',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, size: 18, color: Color(0xFF073A82)),
                      SizedBox(width: 8),
                      Text('Admin Portali', style: TextStyle(fontWeight: FontWeight.bold)),
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

      // Mobil drawer
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: Colors.white,
              child: Column(
                children: [
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
                                  Icons.psychology_rounded,
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
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Psixologik xizmat portali',
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
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    (user?.fullName ?? 'U').substring(0, 1),
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.fullName ?? 'Dilnoza Usmonova',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        maxLines: 1,
                                      ),
                                      Text(
                                        user?.specialization ?? 'Maktab psixologi',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

                  // 9 ta menyu punkti
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

                  // Drawer Bottom
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Psixologik xizmat moduli\nO‘zR O‘RQ-547 maxfiylik kafolati',
                            style: TextStyle(fontSize: 9, color: AppColors.textMuted),
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

      // Desktop layout
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  // Sidebar header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Psixolog xizmati',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '9 ta asosiy bo‘lim',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Navigatsiya menyulari
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      itemCount: _navItems.length,
                      itemBuilder: (context, idx) {
                        final item = _navItems[idx];
                        final isSel = _selectedIndex == idx;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFEFF6FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isSel ? Border.all(color: const Color(0xFFBFDBFE)) : null,
                          ),
                          child: InkWell(
                            onTap: () => setState(() => _selectedIndex = idx),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(
                                    isSel ? item['activeIcon'] : item['icon'],
                                    size: 19,
                                    color: isSel ? AppColors.primary : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${idx + 1}. ${item['title']}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                            color: isSel ? AppColors.primary : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        Text(
                                          item['subtitle'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isSel ? AppColors.primary.withOpacity(0.8) : const Color(0xFF94A3B8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSel)
                                    Container(
                                      width: 4,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Pastki axborot paneli
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.borderLight)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF0D9488)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Maxfiylik ta’minlangan\nO‘RQ-547 standarti',
                            style: TextStyle(fontSize: 10, color: Color(0xFF0F766E), height: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Asosiy tanlangan ekran kontenti
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),

      // Mobil qurilmalar uchun pastki menyu
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex > 4 ? 4 : _selectedIndex,
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
                selectedFontSize: 10,
                unselectedFontSize: 9,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard_rounded),
                    label: 'Bosh sahifa',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline_rounded),
                    activeIcon: Icon(Icons.people_rounded),
                    label: 'O‘quvchilar',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.quiz_outlined),
                    activeIcon: Icon(Icons.quiz_rounded),
                    label: 'Baholash',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book_outlined),
                    activeIcon: Icon(Icons.menu_book_rounded),
                    label: 'Kuzatuv',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.more_horiz_rounded),
                    label: 'Bo‘limlar (9)',
                  ),
                ],
              ),
            ),
    );
  }
}
