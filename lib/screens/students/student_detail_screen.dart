import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/assessment_model.dart';
import '../../models/audit_log_model.dart';
import '../../models/iep_model.dart';
import '../../models/referral_model.dart';
import '../../models/session_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/access_control_service.dart';
import '../assessments/new_assessment_screen.dart';
import '../iep/iep_print_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AccessControlService _access = AccessControlService();

  final List<String> _tabs = [
    'Umumiy ma’lumot',
    'Baholashlar',
    'Mashg‘ulotlar tarixi',
    'Individual ta’lim rejasi',
    'Rivojlanish dinamikasi',
    'Yo‘naltirishlar',
    'Hujjatlar',
    'Faoliyat tarixi',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showArchiveDialog(
    BuildContext context,
    StudentModel student,
    UserModel currentUser,
  ) {
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O‘quvchi anketasini arxivlash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${student.fullName} anketasini faol ro‘yxatdan arxivga o‘tkazmoqchimisiz? Barcha tarixiy yozuvlar (baholashlar, ITR, mashg‘ulotlar) to‘liq saqlanadi.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Arxivlash sababi *',
                hintText:
                    'Masalan: Boshqa maktabga ko‘chib o‘tdi yoki bosqichni yakunladi',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Iltimos, arxivlash sababini yozing'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await context.read<AppProvider>().deactivateStudent(
                student.id,
                reason,
                byUser: currentUser,
              );
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('O‘quvchi muvaffaqiyatli arxivlandi'),
                ),
              );
            },
            child: const Text('Arxivlash'),
          ),
        ],
      ),
    );
  }

  void _showUnarchiveDialog(
    BuildContext context,
    StudentModel student,
    UserModel currentUser,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O‘quvchini qayta faollashtirish'),
        content: Text(
          '${student.fullName} anketasini arxivdan qayta faol holatga o‘tkazishni tasdiqlaysizmi?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final updated = student.copyWith(
                status: 'Faol',
                deactivationReason: null,
                deactivatedAt: null,
              );
              await context.read<AppProvider>().updateStudent(
                updated,
                byUser: currentUser,
              );
              messenger.showSnackBar(
                const SnackBar(content: Text('O‘quvchi qayta faollashtirildi')),
              );
            },
            child: const Text('Faollashtirish'),
          ),
        ],
      ),
    );
  }

  void _showAssignSpecialistDialog(
    BuildContext context,
    StudentModel student,
    UserModel currentUser,
  ) {
    final app = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final availableSpecialists = app.specialists
        .where((u) => !student.assignedSpecialistIds.contains(u.id))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mutaxassis biriktirish'),
        content: SizedBox(
          width: 420,
          child: availableSpecialists.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Barcha mutaxassislar allaqachon biriktirilgan yoki mutaxassislar ro‘yxati bo‘sh.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableSpecialists.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.hairlineBorder, height: 1),
                  itemBuilder: (c, i) {
                    final sp = availableSpecialists[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: sp.role.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          LucideIcons.userRound,
                          color: sp.role.color,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        sp.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        '${sp.role.label} • ${sp.institutionName ?? ''}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          LucideIcons.userPlus,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await app.assignSpecialistToStudent(
                            student.id,
                            sp.id,
                            byUser: currentUser,
                          );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '${sp.fullName} ushbu o‘quvchiga biriktirildi',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;

    final student = app.students.firstWhere(
      (s) => s.id == widget.studentId,
      orElse: () => app.allStudentsIncludingArchived.firstWhere(
        (s) => s.id == widget.studentId,
        orElse: () => app.students.isNotEmpty
            ? app.students.first
            : app.allStudentsIncludingArchived.first,
      ),
    );

    final assessments = app.assessments
        .where((a) => a.studentId == student.id)
        .toList();
    final sessions = app.sessions
        .where((s) => s.studentId == student.id)
        .toList();
    final iepPlans = app.iepPlans
        .where((p) => p.studentId == student.id)
        .toList();
    final referrals = app.referrals
        .where((r) => r.studentId == student.id)
        .toList();
    final auditLogs = app.auditLogs
        .where(
          (a) =>
              a.details.contains(student.firstName) ||
              a.details.contains(student.id),
        )
        .toList();

    final isArchived = student.status == 'Arxivlangan';
    final canArchive =
        currentUser != null && _access.canArchiveStudent(currentUser, student);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          student.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          if (canArchive && !isArchived)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(
                  LucideIcons.archive,
                  color: AppColors.warning,
                  size: 19,
                ),
                tooltip: 'O‘quvchini arxivlash',
                onPressed: () =>
                    _showArchiveDialog(context, student, currentUser),
              ),
            ),
          if (canArchive && isArchived)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(
                  LucideIcons.archiveRestore,
                  color: AppColors.success,
                  size: 19,
                ),
                tooltip: 'Arxivdan qaytarish',
                onPressed: () =>
                    _showUnarchiveDialog(context, student, currentUser),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: AppColors.hairlineBorder,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: _tabs.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: AmbientMeshBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(student, currentUser, app),
            _buildAssessmentsTab(assessments, student),
            _buildSessionsTab(sessions),
            _buildIepTab(context, iepPlans, student),
            _buildDynamicsTab(assessments),
            _buildReferralsTab(referrals),
            _buildDocumentsTab(),
            _buildAuditTab(auditLogs),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTabState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: ResponsivePageContainer(
        maxWidth: 480,
        child: SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 26, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 16), action],
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: UMUMIY MA'LUMOT ---
  Widget _buildGeneralTab(
    StudentModel s,
    UserModel? currentUser,
    AppProvider app,
  ) {
    final df = DateFormat('dd.MM.yyyy');
    final isArchived = s.status == 'Arxivlangan';
    final canViewMedical =
        currentUser != null && _access.canViewSensitiveMedical(currentUser);
    final canManageAssignments =
        currentUser != null &&
        (_access.canManageUsers(currentUser) ||
            currentUser.role == UserRole.coordinator);

    final assignedStaff = app.allUsers
        .where((u) => s.assignedSpecialistIds.contains(u.id))
        .toList();

    return SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 1040,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isArchived)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.archive,
                      color: AppColors.warning,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ushbu o‘quvchi anketasi arxivlangan',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sababi: ${s.deactivationReason ?? 'Ko‘rsatilmagan'} • Sana: ${s.deactivatedAt != null ? df.format(s.deactivatedAt!) : 'Noma’lum'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Frosted Profil Hero Karta
            GlassSurface(
              padding: const EdgeInsets.all(22),
              borderRadius: 18,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 430;
                  final avatar = Container(
                    width: isCompact ? 56 : 68,
                    height: isCompact ? 56 : 68,
                    decoration: BoxDecoration(
                      gradient: isArchived
                          ? null
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryLight,
                                Color(0xFFDCE7FF),
                              ],
                            ),
                      color: isArchived ? AppColors.borderLight : null,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isArchived
                            ? AppColors.border
                            : AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.firstName.isNotEmpty
                          ? s.firstName.substring(0, 1)
                          : '?',
                      style: TextStyle(
                        fontSize: isCompact ? 22 : 26,
                        fontWeight: FontWeight.w800,
                        color: isArchived
                            ? AppColors.textMuted
                            : AppColors.primaryDark,
                      ),
                    ),
                  );

                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.fullName,
                        style: TextStyle(
                          fontSize: isCompact ? 17 : 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.institutionName} • ${s.grade}-sinf',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tug‘ilgan kuni: ${df.format(s.dateOfBirth)} (${s.age} yosh)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusPill(
                            label: 'Holati: ${s.status}',
                            color: isArchived
                                ? AppColors.warning
                                : AppColors.success,
                            showDot: true,
                          ),
                          if (s.coordinatorName != null)
                            StatusPill(
                              label: 'Koordinator: ${s.coordinatorName}',
                              color: AppColors.info,
                              icon: LucideIcons.shieldCheck,
                            ),
                        ],
                      ),
                    ],
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      SizedBox(width: isCompact ? 14 : 20),
                      Expanded(child: details),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Ta'limiy Ehtiyoj va Daraja
            SurfaceCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ta’limiy Ehtiyoj va Qo‘llab-quvvatlash Darajasi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailItem(
                    icon: LucideIcons.brain,
                    iconColor: AppColors.primary,
                    label: 'Asosiy ta’limiy ehtiyoj',
                    value: s.primaryNeed,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppColors.hairlineBorder, height: 1),
                  ),
                  _buildDetailItem(
                    icon: LucideIcons.badgeCheck,
                    iconColor: AppColors.info,
                    label: 'Qo‘llab-quvvatlash darajasi',
                    value: s.supportLevel,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppColors.hairlineBorder, height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.stethoscope,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tibbiy xulosa va tavsiyalar',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (canViewMedical)
                              Text(
                                s.medicalNotes ??
                                    'Tibbiy ma’lumot kiritilmagan',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: AppColors.hairlineBorder,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      LucideIcons.lock,
                                      size: 15,
                                      color: AppColors.textMuted,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Maxfiy tibbiy ma’lumot — faqat vakolatli tibbiy va defektologik mutaxassislar uchun ochiq',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textMuted,
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Biriktirilgan Mutaxassislar
            SurfaceCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Mas’ul Mutaxassislar Jamoasi',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (canManageAssignments)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(LucideIcons.userPlus, size: 15),
                          label: const Text(
                            'Biriktirish',
                            style: TextStyle(fontSize: 12.5),
                          ),
                          onPressed: () => _showAssignSpecialistDialog(
                            context,
                            s,
                            currentUser,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (assignedStaff.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Ushbu o‘quvchiga hali maxsus mutaxassis biriktirilmagan',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  else
                    ...assignedStaff.map((staff) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: staff.role.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                LucideIcons.userRound,
                                color: staff.role.color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${staff.role.label} • Tel: ${staff.phone ?? 'Mavjud emas'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vasiylar
            SurfaceCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ota-ona yoki Qonuniy Vasiylar',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (s.guardians.isEmpty)
                    const Text(
                      'Vasiy ma’lumotlari kiritilmagan',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...s.guardians.map((g) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                LucideIcons.usersRound,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${g.relationship} • Tel: ${g.phone}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Manzil: ${g.address ?? 'Ko‘rsatilmagan'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 2: BAHOLASHLAR ---
  Widget _buildAssessmentsTab(
    List<AssessmentModel> assessments,
    StudentModel student,
  ) {
    final auth = context.watch<AuthProvider>();
    final currentRole = auth.currentUser?.role ?? UserRole.psychologist;
    final df = DateFormat('dd.MM.yyyy');

    if (assessments.isEmpty) {
      return _buildEmptyTabState(
        icon: LucideIcons.clipboardCheck,
        title: 'Ushbu o‘quvchiga hali baholash o‘tkazilmagan',
        subtitle:
            'Kasbiy diagnostika natijalarini kiritib, dinamikani kuzatishni boshlang.',
        action: currentRole.canCreateAssessments
            ? FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: currentRole.color,
                ),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('${currentRole.label} baholashi kiritish'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NewAssessmentScreen(initialStudentId: student.id),
                    ),
                  );
                },
              )
            : null,
      );
    }

    return SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 1040,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              icon: LucideIcons.clipboardCheck,
              title: 'Kasbiy Baholashlar Tarixi',
              subtitle:
                  'O‘tkazilgan jami diagnostikalar: ${assessments.length} ta',
              action: currentRole.canCreateAssessments
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: currentRole.color,
                      ),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: Text('Yangi ${currentRole.label} baholashi'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewAssessmentScreen(
                              initialStudentId: student.id,
                            ),
                          ),
                        );
                      },
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            ...assessments.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Yo‘nalish: ${a.category}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          StatusPill(
                            label:
                                '${a.totalScore.toInt()} / ${a.maxScore.toInt()} ball',
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.userCheck,
                                size: 13.5,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                a.specialistName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          StatusPill(
                            label: a.specialistRole,
                            color: AppColors.textSecondary,
                            backgroundColor: AppColors.background,
                            borderColor: AppColors.hairlineBorder,
                          ),
                          Text(
                            df.format(a.assessmentDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xulosa: ${a.notes}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tavsiya: ${a.recommendations}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: MASHG'ULOTLAR ---
  Widget _buildSessionsTab(List<SessionModel> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyTabState(
        icon: LucideIcons.calendarClock,
        title: 'Hozircha mashg‘ulotlar tarixi mavjud emas',
        subtitle:
            'Korreksion va yakka tartibdagi mashg‘ulotlar shu yerda aks etadi.',
      );
    }
    final df = DateFormat('dd.MM.yyyy HH:mm');
    return SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 1040,
        child: Column(
          children: sessions.map((s) {
            final isDone = s.status == 'Bajarildi';
            final statusColor = isDone ? AppColors.success : AppColors.info;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        isDone ? LucideIcons.circleCheck : LucideIcons.clock,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                s.topic,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              StatusPill(
                                label: s.status,
                                color: statusColor,
                                showDot: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.specialistName} • ${df.format(s.scheduledAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (s.activities != null &&
                              s.activities!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              s.activities!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- TAB 4: INDIVIDUAL TA'LIM REJASI (ITR) ---
  Widget _buildIepTab(
    BuildContext context,
    List<IndividualEducationPlanModel> iepPlans,
    StudentModel student,
  ) {
    if (iepPlans.isEmpty) {
      return _buildEmptyTabState(
        icon: LucideIcons.bookOpenCheck,
        title: 'Ushbu o‘quvchiga ITR rejasi ochilmagan',
        subtitle:
            'Asosiy menyudagi ITR bo‘limi orqali o‘quvchi uchun individual ta’lim rejasi yarating.',
      );
    }
    final plan = iepPlans.first;
    final app = context.watch<AppProvider>();

    return SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 1040,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              icon: LucideIcons.bookOpenCheck,
              title: plan.title,
              subtitle:
                  'O‘quv yili: ${plan.academicYear} • Mas’ul: ${plan.responsibleTeacherName}',
              action: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primaryDark,
                ),
                icon: const Icon(LucideIcons.printer, size: 16),
                label: const Text('Rasmiy Blank'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          IepPrintScreen(plan: plan, student: student),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Rejalashtirilgan o‘lchanadigan maqsadlar va ularning bajarilishi:',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...plan.objectives.map((obj) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              obj.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          StatusPill(
                            label: '${obj.progressPercent}%',
                            color: obj.progressPercent >= 80
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soha: ${obj.domain} • Mezon: ${obj.successCriteria ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7.5,
                          ),
                        ),
                        child: Slider(
                          value: obj.progressPercent.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.primary.withValues(
                            alpha: 0.16,
                          ),
                          label: '${obj.progressPercent}%',
                          onChanged: (val) {
                            app.updateObjectiveProgress(
                              plan.id,
                              obj.id,
                              val.toInt(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- TAB 5: RIVOJLANISH DINAMIKASI ---
  Widget _buildDynamicsTab(List<AssessmentModel> assessments) {
    final sorted = [...assessments]
      ..sort((a, b) => a.assessmentDate.compareTo(b.assessmentDate));

    return SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 1040,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassSurface(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.trendingUp,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rivojlanish tendensiyasi xulosasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Diagnostika natijalariga ko‘ra, o‘quvchida barqaror ijobiy dinamika kuzatilmoqda. Ayniqsa, nutqiy muloqot va kognitiv moslashuv mezonlarida o‘sish qayd etilgan.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (sorted.length >= 2) ...[
              SurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Baholash ko‘rsatkichlari grafigi (%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 190,
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 100,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 25,
                            getDrawingHorizontalLine: (_) => const FlLine(
                              color: AppColors.borderLight,
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 34,
                                interval: 25,
                                getTitlesWidget: (val, _) => Text(
                                  '${val.toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (val, _) {
                                  final idx = val.toInt();
                                  if (idx < 0 || idx >= sorted.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      DateFormat(
                                        'dd.MM',
                                      ).format(sorted[idx].assessmentDate),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              curveSmoothness: 0.32,
                              color: AppColors.primary,
                              barWidth: 3,
                              spots: List.generate(sorted.length, (i) {
                                final pct = sorted[i].maxScore > 0
                                    ? (sorted[i].totalScore /
                                              sorted[i].maxScore) *
                                          100
                                    : 0.0;
                                return FlSpot(i.toDouble(), pct.clamp(0, 100));
                              }),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (_, _, _, _) =>
                                    FlDotCirclePainter(
                                      radius: 4.5,
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                      strokeColor: AppColors.primary,
                                    ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.2),
                                    AppColors.primary.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SurfaceCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monitoring baholarining vaqt bo‘yicha o‘zgarishi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (assessments.isEmpty)
                    const Text(
                      'Hozircha monitoring ballari kiritilmagan.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    ...assessments.map((a) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.activity,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${a.category}: ${a.title}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusPill(
                              label: '${a.totalScore.toInt()} ball (${a.trend})',
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 6: YO'NALTIRISHLAR ---
  Widget _buildReferralsTab(List<ReferralModel> referrals) {
    if (referrals.isEmpty) {
      return _buildEmptyTabState(
        icon: LucideIcons.gitBranchPlus,
        title: 'Tashqi yoki ichki yo‘naltirishlar mavjud emas',
        subtitle:
            'Boshqa tor doiradagi mutaxassislarga yo‘llanmalar shu yerda saqlanadi.',
      );
    }
    return SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 1040,
        child: Column(
          children: referrals.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        LucideIcons.arrowUpRight,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${r.toSpecialistType}ga yo‘naltirish',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              StatusPill(
                                label: r.status,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Yuborgan: ${r.fromSpecialistName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sababi: ${r.reason}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- TAB 7: HUJJATLAR ---
  Widget _buildDocumentsTab() {
    final docs = [
      (
        title: 'PMPK Xulosasi va Yo‘llanmasi (PDF)',
        subtitle: 'Shahar pedagogik-tibbiy komissiyasi • 14.08.2026',
      ),
      (
        title: 'Tibbiy Ko‘rik Karta Ma’lumotnomasi (PDF)',
        subtitle: '12-sonli bolalar poliklinikasi • 20.08.2026',
      ),
    ];

    return SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 1040,
        child: Column(
          children: docs.map((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        LucideIcons.fileText,
                        color: AppColors.error,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doc.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.download,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Yuklab olish',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hujjat yuklab olindi.')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- TAB 8: AUDIT TARIXI ---
  Widget _buildAuditTab(List<AuditLogModel> logs) {
    if (logs.isEmpty) {
      return _buildEmptyTabState(
        icon: LucideIcons.history,
        title: 'Ushbu o‘quvchi bo‘yicha audit yozuvlari yo‘q',
        subtitle:
            'Anketadagi barcha o‘zgarishlar va amallar shu yerda qayd etiladi.',
      );
    }
    return SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 1040,
        child: Column(
          children: logs.map((log) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.hairlineBorder),
                      ),
                      child: const Icon(
                        LucideIcons.history,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.details,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${log.userFullName} (${log.userRole})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd.MM HH:mm').format(log.timestamp),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
