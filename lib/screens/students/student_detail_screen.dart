import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final student = app.students.firstWhere(
      (s) => s.id == widget.studentId,
      orElse: () => app.students.first,
    );

    final assessments = app.assessments.where((a) => a.studentId == student.id).toList();
    final sessions = app.sessions.where((s) => s.studentId == student.id).toList();
    final iepPlans = app.iepPlans.where((p) => p.studentId == student.id).toList();
    final referrals = app.referrals.where((r) => r.studentId == student.id).toList();
    final auditLogs = app.auditLogs.where((a) => a.details.contains(student.firstName)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          _buildGeneralTab(student),

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
  Widget _buildGeneralTab(StudentModel s) {
    final df = DateFormat('dd.MM.yyyy');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil Karta
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      s.firstName.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
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
                          'Sinfi: ${s.grade} • Tug‘ilgan kuni: ${df.format(s.dateOfBirth)} (${s.age} yosh)',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Holati: ${s.status}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
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
                  if (s.medicalNotes != null) ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.medical_services_outlined, color: AppColors.warning),
                      title: const Text('Tibbiy xulosa va tavsiyalar', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      subtitle: Text(s.medicalNotes!, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
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
