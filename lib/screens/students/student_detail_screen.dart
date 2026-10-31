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
          width: 430,
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
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (c, i) {
                    final sp = availableSpecialists[i];
                    return GlassWell(
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            premiumRoleIcon(sp.role),
                            color: sp.role.color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sp.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${sp.role.label} • ${sp.institutionName ?? ''}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
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
                        ],
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
            letterSpacing: -0.25,
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
          indicatorWeight: 2.6,
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
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 38),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 18), action],
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
        maxWidth: 1060,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isArchived)
              SurfaceCard(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                backgroundColor: AppColors.warningBg,
                borderColor: AppColors.warningBorder,
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

            // Minimalist Soft-Glass Profil Hero Karta
            GlassSurface(
              padding: const EdgeInsets.all(20),
              borderRadius: 18,
              opacity: 0.96,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 430;
                  final firstInitial = s.lastName.isNotEmpty
                      ? s.lastName.substring(0, 1).toUpperCase()
                      : '';
                  final secondInitial = s.firstName.isNotEmpty
                      ? s.firstName.substring(0, 1).toUpperCase()
                      : '?';
                  final initials = '$firstInitial$secondInitial';

                  final avatar = Container(
                    width: isCompact ? 46 : 52,
                    height: isCompact ? 46 : 52,
                    decoration: BoxDecoration(
                      color: isArchived
                          ? AppColors.glassWellFill
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(isCompact ? 13 : 14),
                      border: Border.all(
                        color: isArchived
                            ? AppColors.border
                            : AppColors.primaryTint,
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: isArchived
                            ? AppColors.textMuted
                            : AppColors.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  );

                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.fullName,
                        style: TextStyle(
                          fontSize: isCompact ? 17.5 : 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.1,
                          wordSpacing: 0.4,
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
                      const SizedBox(height: 3),
                      Text(
                        'Tug‘ilgan kuni: ${df.format(s.dateOfBirth)} (${s.age} yosh)',
                        style: const TextStyle(
                          fontSize: 12.3,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusPill(
                            label: 'Holati: ${s.status}',
                            color: isArchived
                                ? AppColors.warning
                                : AppColors.success,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.86),
                            showDot: true,
                          ),
                          if (s.coordinatorName != null)
                            StatusPill(
                              label: 'Koordinator: ${s.coordinatorName}',
                              color: AppColors.info,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.86),
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
            const SizedBox(height: 18),

            // Ta'limiy Ehtiyoj va Daraja (Erkin ikonkalar!)
            SurfaceCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ta’limiy Ehtiyoj va Qo‘llab-quvvatlash Darajasi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildDetailItem(
                    icon: LucideIcons.brain,
                    iconColor: AppColors.primary,
                    label: 'Asosiy ta’limiy ehtiyoj',
                    value: s.primaryNeed,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1),
                  ),
                  _buildDetailItem(
                    icon: LucideIcons.badgeCheck,
                    iconColor: AppColors.info,
                    label: 'Qo‘llab-quvvatlash darajasi',
                    value: s.supportLevel,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          LucideIcons.stethoscope,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tibbiy xulosa va tavsiyalar',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (canViewMedical)
                              Text(
                                s.medicalNotes ??
                                    'Tibbiy ma’lumot kiritilmagan',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.45,
                                ),
                              )
                            else
                              const GlassWell(
                                borderRadius: 12,
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.lock,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Maxfiy tibbiy ma’lumot — faqat vakolatli tibbiy va defektologik mutaxassislar uchun ochiq',
                                        style: TextStyle(
                                          fontSize: 12,
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
            const SizedBox(height: 18),

            // Biriktirilgan Mutaxassislar
            SurfaceCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(24),
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
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.25,
                        ),
                      ),
                      if (canManageAssignments)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
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
                  const SizedBox(height: 14),
                  if (assignedStaff.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Ushbu o‘quvchiga hali maxsus mutaxassis biriktirilmagan',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  else
                    ...assignedStaff.map((staff) {
                      return GlassWell(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        borderRadius: 12,
                        child: Row(
                          children: [
                            Icon(
                              premiumRoleIcon(staff.role),
                              color: staff.role.color,
                              size: 20,
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
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
            const SizedBox(height: 18),

            // Vasiylar
            SurfaceCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ota-ona yoki Qonuniy Vasiylar',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (s.guardians.isEmpty)
                    const Text(
                      'Vasiy ma’lumotlari kiritilmagan',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...s.guardians.map((g) {
                      return GlassWell(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        borderRadius: 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                LucideIcons.usersRound,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${g.relationship} • Tel: ${g.phone}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
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
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.35,
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
        maxWidth: 1060,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              title: 'Baholashlar tarixi',
              subtitle:
                  'O‘tkazilgan jami diagnostikalar • ${assessments.length} ta',
              action: currentRole.canCreateAssessments
                  ? HeaderActionButton(
                      icon: LucideIcons.plus,
                      label: 'Yangi baholash',
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
            const SizedBox(height: 18),
            ...assessments.map((a) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SurfaceCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Yo‘nalish: ${a.category}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          StatusPill(
                            label:
                                '${a.totalScore.toInt()} / ${a.maxScore.toInt()} ball',
                            color: AppColors.success,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.85),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  a.specialistName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          StatusPill(
                            label: a.specialistRole,
                            color: AppColors.textSecondary,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.8),
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
                      const SizedBox(height: 14),
                      GlassWell(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xulosa: ${a.notes}',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tavsiya: ${a.recommendations}',
                              style: const TextStyle(
                                fontSize: 12.5,
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
        maxWidth: 1060,
        child: Column(
          children: sessions.map((s) {
            final isDone = s.status == 'Bajarildi';
            final statusColor = isDone ? AppColors.success : AppColors.info;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SurfaceCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        isDone ? LucideIcons.circleCheck : LucideIcons.clock,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  s.topic,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              StatusPill(
                                label: s.status,
                                color: statusColor,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.85),
                                showDot: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${s.specialistName} • ${df.format(s.scheduledAt)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (s.activities != null &&
                              s.activities!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              s.activities!,
                              style: const TextStyle(
                                fontSize: 13,
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
        maxWidth: 1060,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              title: plan.title,
              subtitle:
                  'O‘quv yili: ${plan.academicYear} • Mas’ul: ${plan.responsibleTeacherName}',
              action: HeaderActionButton(
                variant: HeaderActionVariant.secondary,
                icon: LucideIcons.printer,
                label: 'Rasmiy blank',
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
            const SizedBox(height: 20),
            const Text(
              'Rejalashtirilgan o‘lchanadigan maqsadlar va ularning bajarilishi:',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ...plan.objectives.map((obj) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SurfaceCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(22),
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
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
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
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.86),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Soha: ${obj.domain} • Mezon: ${obj.successCriteria ?? ''}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5.5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
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
        maxWidth: 1060,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassSurface(
              padding: const EdgeInsets.all(24),
              borderRadius: 18,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.trendingUp,
                      color: AppColors.success,
                      size: 23,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rivojlanish tendensiyasi xulosasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
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
            const SizedBox(height: 18),

            if (sorted.length >= 2) ...[
              SurfaceCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Baholash ko‘rsatkichlari grafigi (%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GlassWell(
                      borderRadius: 12,
                      padding: const EdgeInsets.fromLTRB(8, 18, 24, 10),
                      child: SizedBox(
                        height: 195,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 25,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.borderSlate.withValues(
                                  alpha: 0.7,
                                ),
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
                                  reservedSize: 36,
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
                                  reservedSize: 28,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (val != idx.toDouble() ||
                                        idx < 0 ||
                                        idx >= sorted.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return SideTitleWidget(
                                      meta: meta,
                                      space: 8,
                                      fitInside:
                                          SideTitleFitInsideData.fromTitleMeta(
                                        meta,
                                        distanceFromEdge: 0,
                                      ),
                                      child: Text(
                                        DateFormat(
                                          'dd.MM',
                                        ).format(sorted[idx].assessmentDate),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
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
                                  return FlSpot(
                                    i.toDouble(),
                                    pct.clamp(0, 100),
                                  );
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
                                      AppColors.primary.withValues(alpha: 0.22),
                                      AppColors.primary.withValues(alpha: 0.0),
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
              const SizedBox(height: 18),
            ],

            SurfaceCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monitoring baholarining vaqt bo‘yicha o‘zgarishi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (assessments.isEmpty)
                    const Text(
                      'Hozircha monitoring ballari kiritilmagan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    ...assessments.map((a) {
                      return GlassWell(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        borderRadius: 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                LucideIcons.activity,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                '${a.category}: ${a.title}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusPill(
                              label: '${a.totalScore.toInt()} ball (${a.trend})',
                              color: AppColors.primary,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.85),
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
        maxWidth: 1060,
        child: Column(
          children: referrals.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SurfaceCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.arrowUpRight,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${r.toSpecialistType}ga yo‘naltirish',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              StatusPill(
                                label: r.status,
                                color: AppColors.primary,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.85),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Yuborgan: ${r.fromSpecialistName}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Sababi: ${r.reason}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
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
        maxWidth: 1060,
        child: Column(
          children: docs.map((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SurfaceCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.fileText,
                      color: AppColors.error,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            doc.subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.download,
                        size: 19,
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
        maxWidth: 1060,
        child: Column(
          children: logs.map((log) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.history,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.details,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              Text(
                                '${log.userFullName} (${log.userRole})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                DateFormat('dd.MM HH:mm').format(log.timestamp),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSubtle,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
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
}
