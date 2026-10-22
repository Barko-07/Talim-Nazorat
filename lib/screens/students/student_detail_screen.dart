import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
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

  void _showArchiveDialog(BuildContext context, StudentModel student, UserModel currentUser) {
    final reasonController = TextEditingController();
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
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Arxivlash sababi *',
                hintText: 'Masalan: Boshqa maktabga ko‘chib o‘tdi yoki bosqichni yakunladi',
                border: OutlineInputBorder(),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Iltimos, arxivlash sababini yozing')),
                );
                return;
              }
              Navigator.pop(ctx);
              await context.read<AppProvider>().deactivateStudent(student.id, reason, byUser: currentUser);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('O‘quvchi muvaffaqiyatli arxivlandi')),
                );
              }
            },
            child: const Text('Arxivlash'),
          ),
        ],
      ),
    );
  }

  void _showUnarchiveDialog(BuildContext context, StudentModel student, UserModel currentUser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O‘quvchini qayta faollashtirish'),
        content: Text(
          '${student.fullName} anketasini arxivdan qayta faol holatga o‘tkazishni tasdiqlaysizmi?',
          style: const TextStyle(fontSize: 13),
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
              await context.read<AppProvider>().updateStudent(updated, byUser: currentUser);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('O‘quvchi qayta faollashtirildi')),
                );
              }
            },
            child: const Text('Faollashtirish'),
          ),
        ],
      ),
    );
  }

  void _showAssignSpecialistDialog(BuildContext context, StudentModel student, UserModel currentUser) {
    final app = context.read<AppProvider>();
    final availableSpecialists = app.specialists.where((u) => !student.assignedSpecialistIds.contains(u.id)).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mutaxassis biriktirish'),
        content: SizedBox(
          width: 400,
          child: availableSpecialists.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Barcha mutaxassislar allaqachon biriktirilgan yoki mutaxassislar ro‘yxati bo‘sh.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableSpecialists.length,
                  itemBuilder: (c, i) {
                    final sp = availableSpecialists[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: sp.role.color.withOpacity(0.15),
                        child: Icon(Icons.person, color: sp.role.color),
                      ),
                      title: Text(sp.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${sp.role.label} • ${sp.institutionName ?? ''}', style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await app.assignSpecialistToStudent(student.id, sp.id, byUser: currentUser);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${sp.fullName} ushbu o‘quvchiga biriktirildi')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yopish')),
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
        orElse: () => app.students.isNotEmpty ? app.students.first : app.allStudentsIncludingArchived.first,
      ),
    );

    final assessments = app.assessments.where((a) => a.studentId == student.id).toList();
    final sessions = app.sessions.where((s) => s.studentId == student.id).toList();
    final iepPlans = app.iepPlans.where((p) => p.studentId == student.id).toList();
    final referrals = app.referrals.where((r) => r.studentId == student.id).toList();
    final auditLogs = app.auditLogs.where((a) => a.details.contains(student.firstName) || a.details.contains(student.id)).toList();

    final isArchived = student.status == 'Arxivlangan';
    final canArchive = currentUser != null && _access.canArchiveStudent(currentUser, student);

    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (canArchive && !isArchived)
            IconButton(
              icon: const Icon(Icons.archive_outlined, color: AppColors.warning),
              tooltip: 'O‘quvchini arxivlash',
              onPressed: () => _showArchiveDialog(context, student, currentUser),
            ),
          if (canArchive && isArchived)
            IconButton(
              icon: const Icon(Icons.unarchive_outlined, color: AppColors.success),
              tooltip: 'Arxivdan qaytarish',
              onPressed: () => _showUnarchiveDialog(context, student, currentUser),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. UMUMIY MA'LUMOT
          _buildGeneralTab(student, currentUser, app),

          // 2. BAHOLASHLAR
          _buildAssessmentsTab(assessments, student),

          // 3. MASHG'ULOTLAR
          _buildSessionsTab(sessions),

          // 4. INDIVIDUAL TA'LIM REJASI (ITR)
          _buildIepTab(context, iepPlans, student),

          // 5. RIVOJLANISH DINAMIKASI
          _buildDynamicsTab(assessments),

          // 6. YO'NALTIRISHLAR
          _buildReferralsTab(referrals),

          // 7. HUJJATLAR
          _buildDocumentsTab(),

          // 8. FAOLIYAT TARIXI (AUDIT)
          _buildAuditTab(auditLogs),
        ],
      ),
    );
  }

  // --- TAB 1: UMUMIY MA'LUMOT ---
  Widget _buildGeneralTab(StudentModel s, UserModel? currentUser, AppProvider app) {
    final df = DateFormat('dd.MM.yyyy');
    final isArchived = s.status == 'Arxivlangan';
    final canViewMedical = currentUser != null && _access.canViewSensitiveMedical(currentUser);
    final canManageAssignments = currentUser != null &&
        (_access.canManageUsers(currentUser) || currentUser.role == UserRole.coordinator);

    // Biriktirilgan mutaxassislar obyektlarini topish
    final assignedStaff = app.allUsers.where((u) => s.assignedSpecialistIds.contains(u.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isArchived)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.archive, color: AppColors.warning, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ushbu o‘quvchi anketasi arxivlangan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          'Sababi: ${s.deactivationReason ?? 'Ko‘rsatilmagan'} • Sana: ${s.deactivatedAt != null ? df.format(s.deactivatedAt!) : 'Noma’lum'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Profil Karta
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: isArchived ? AppColors.borderLight : AppColors.primaryLight,
                    child: Text(
                      s.firstName.isNotEmpty ? s.firstName.substring(0, 1) : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isArchived ? AppColors.textMuted : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Maktab: ${s.institutionName ?? 'Biriktirilmagan'} • Sinfi: ${s.grade}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tug‘ilgan kuni: ${df.format(s.dateOfBirth)} (${s.age} yosh)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isArchived ? AppColors.warningBg : AppColors.successBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Holati: ${s.status}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isArchived ? AppColors.warning : AppColors.success,
                                ),
                              ),
                            ),
                            if (s.coordinatorName != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.infoBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Koordinator: ${s.coordinatorName}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ta'limiy Ehtiyoj va Daraja
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ta’limiy Ehtiyoj Va Qo‘llab-quvvatlash Darajasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.psychology, color: AppColors.primary),
                    title: const Text('Asosiy ta’limiy ehtiyoj', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    subtitle: Text(s.primaryNeed, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.verified, color: AppColors.info),
                    title: const Text('Qo‘llab-quvvatlash darajasi', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    subtitle: Text(s.supportLevel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.medical_services_outlined, color: AppColors.warning),
                    title: const Text('Tibbiy xulosa va tavsiyalar', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    subtitle: canViewMedical
                        ? Text(s.medicalNotes ?? 'Tibbiy ma’lumot kiritilmagan', style: const TextStyle(fontSize: 13))
                        : Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Maxfiy tibbiy ma’lumot — faqat vakolatli tibbiy va defektologik mutaxassislar uchun ochiq',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Biriktirilgan Mutaxassislar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mas’ul Mutaxassislar Jamasi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (canManageAssignments && currentUser != null)
                        TextButton.icon(
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Biriktirish', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showAssignSpecialistDialog(context, s, currentUser),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (assignedStaff.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Ushbu o‘quvchiga hali maxsus mutaxassis biriktirilmagan',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    )
                  else
                    ...assignedStaff.map((staff) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: staff.role.color.withOpacity(0.15),
                          child: Icon(Icons.person, color: staff.role.color, size: 20),
                        ),
                        title: Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('${staff.role.label} (${staff.specialization ?? staff.role.name}) • Tel: ${staff.phone ?? 'Mavjud emas'}'),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vasiylar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ota-ona yoki Qonuniy Vasiylar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  if (s.guardians.isEmpty)
                    const Text('Vasiy ma’lumotlari kiritilmagan')
                  else
                    ...s.guardians.map((g) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.borderLight,
                          child: Icon(Icons.person, color: AppColors.textSecondary),
                        ),
                        title: Text(g.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${g.relationship} • Tel: ${g.phone}\nManzil: ${g.address ?? 'Ko‘rsatilmagan'}'),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: BAHOLASHLAR ---
  Widget _buildAssessmentsTab(List<dynamic> assessments, StudentModel student) {
    final auth = context.watch<AuthProvider>();
    final currentRole = auth.currentUser?.role ?? UserRole.psychologist;
    final df = DateFormat('dd.MM.yyyy');

    return Column(
      children: [
        // Mutaxassis uchun tezkor baholash kiritish paneli
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'O‘tkazilgan baholashlar: ${assessments.length} ta',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              if (currentRole.canCreateAssessments)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: currentRole.color,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.add_task_rounded, size: 16),
                  label: Text('Yangi ${currentRole.label} baholashi', style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewAssessmentScreen(initialStudentId: student.id),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        Expanded(
          child: assessments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'Ushbu o‘quvchiga hali baholash o‘tkazilmagan',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      if (currentRole.canCreateAssessments) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: Text('${currentRole.label} sifatida baholash kiritish'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewAssessmentScreen(initialStudentId: student.id),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: assessments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final a = assessments[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Yo‘nalish: ${a.category}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${a.totalScore.toInt()} / ${a.maxScore.toInt()} ball',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  'Mutaxassis: ${a.specialistName}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    a.specialistRole,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  df.format(a.assessmentDate),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Xulosa: ${a.notes}', style: const TextStyle(fontSize: 13, height: 1.4)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tavsiya: ${a.recommendations}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 3: MASHG'ULOTLAR ---
  Widget _buildSessionsTab(List<dynamic> sessions) {
    if (sessions.isEmpty) {
      return const Center(child: Text('Hozircha darslar tarixi mavjud emas'));
    }
    final df = DateFormat('dd.MM.yyyy HH:mm');
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final s = sessions[index];
        final isDone = s.status == 'Bajarildi';
        return Card(
          child: ListTile(
            leading: Icon(
              isDone ? Icons.check_circle : Icons.schedule,
              color: isDone ? AppColors.success : AppColors.info,
            ),
            title: Text(s.topic, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${s.specialistName} • ${df.format(s.scheduledAt)}\n${s.activities ?? ''}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDone ? AppColors.successBg : AppColors.infoBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                s.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDone ? AppColors.success : AppColors.info,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 4: INDIVIDUAL TA'LIM REJASI (ITR) ---
  Widget _buildIepTab(BuildContext context, List<dynamic> iepPlans, StudentModel student) {
    if (iepPlans.isEmpty) {
      return const Center(child: Text('Ushbu o‘quvchiga ITR rejasi ochilmagan'));
    }
    final plan = iepPlans.first;
    final app = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'O‘quv yili: ${plan.academicYear} • Mas’ul: ${plan.responsibleTeacherName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Chop etish'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IepPrintScreen(plan: plan, student: student),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Maqsadlar va progress slayderi
          const Text(
            'Rejalashtirilgan o‘lchanadigan maqsadlar va ularning bajarilishi:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),

          ...plan.objectives.map((obj) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            obj.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${obj.progressPercent}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Soha: ${obj.domain} • Mezon: ${obj.successCriteria ?? ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 8),

                    // Inline Progress Slider
                    Slider(
                      value: obj.progressPercent.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.primary,
                      label: '${obj.progressPercent}%',
                      onChanged: (val) {
                        app.updateObjectiveProgress(plan.id, obj.id, val.toInt());
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- TAB 5: RIVOJLANISH DINAMIKASI ---
  Widget _buildDynamicsTab(List<dynamic> assessments) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Rivojlanish tendensiyasi xulosasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 10),
                  Text(
                    'Oxirgi 3 ta diagnostika natijalariga ko‘ra, o‘quvchida barqaror ijobiy dinamika (+14%) kuzatilmoqda. Ayniqsa, nutqiy muloqot va fonematik idrok sohasida sezilarli siljish mavjud.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monitoring baholarining vaqt bo‘yicha o‘zgarishi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 16),
                  ...assessments.map((a) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.timeline, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('${a.category}: ${a.title}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          Text('${a.totalScore.toInt()} ball (${a.trend})', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 6: YO'NALTIRISHLAR ---
  Widget _buildReferralsTab(List<dynamic> referrals) {
    if (referrals.isEmpty) {
      return const Center(child: Text('Tashqi yoki ichki yo‘naltirishlar mavjud emas'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: referrals.length,
      itemBuilder: (context, index) {
        final r = referrals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.alt_route, color: AppColors.primary),
            title: Text('${r.toSpecialistType}ga yo‘naltirish', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Yuborgan: ${r.fromSpecialistName}\nSababi: ${r.reason}'),
            trailing: Chip(
              label: Text(r.status, style: const TextStyle(fontSize: 11)),
              backgroundColor: AppColors.primaryLight,
            ),
          ),
        );
      },
    );
  }

  // --- TAB 7: HUJJATLAR ---
  Widget _buildDocumentsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
            title: const Text('PMPK Xulosasi va Yo‘llanmasi (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Shahar pedagogik-tibbiy komissiyasi • 14.08.2026'),
            trailing: IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hujjat yuklab olindi.')),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
            title: const Text('Tibbiy Ko‘rik Karta Ma’lumotnomasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('12-sonli bolalar poliklinikasi • 20.08.2026'),
            trailing: IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hujjat yuklab olindi.')),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 8: AUDIT TARIXI ---
  Widget _buildAuditTab(List<dynamic> logs) {
    if (logs.isEmpty) {
      return const Center(child: Text('Ushbu o‘quvchi bo‘yicha hozircha audit yozuvlari yo‘q'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.history, color: AppColors.textMuted),
            title: Text(log.details, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('${log.userFullName} (${log.userRole})'),
            trailing: Text(
              DateFormat('dd.MM HH:mm').format(log.timestamp),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        );
      },
    );
  }
}
