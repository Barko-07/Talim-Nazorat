import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/iep_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/access_control_service.dart';
import '../students/student_detail_screen.dart';
import 'iep_print_screen.dart';

class IepListScreen extends StatefulWidget {
  const IepListScreen({super.key});

  @override
  State<IepListScreen> createState() => _IepListScreenState();
}

class _IepListScreenState extends State<IepListScreen> {
  final AccessControlService _access = AccessControlService();
  String _selectedStatus = 'Barchasi';

  void _showCreateIepDialog(BuildContext context, UserModel currentUser) {
    final app = context.read<AppProvider>();
    final students = app.students;
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avval o‘quvchi ro‘yxatdan o‘tgan bo‘lishi kerak'),
        ),
      );
      return;
    }

    String selectedStudentId = students.first.id;
    final titleController = TextEditingController(
      text: '2026-2027 o‘quv yili uchun ITR',
    );
    final academicYearController = TextEditingController(text: '2026-2027');
    final baselineController = TextEditingController();
    final goalsController = TextEditingController();
    final strategiesController = TextEditingController();
    final objTitleController = TextEditingController();
    String selectedDomain = 'Kognitiv';
    final objStartingLevelController = TextEditingController(text: '20%');
    final objTargetLevelController = TextEditingController(text: '80%');
    final objCriteriaController = TextEditingController(
      text: 'Mustaqil ravishda 10 tadan 8 tasini to‘g‘ri bajarish',
    );

    final DateTime startDate = DateTime.now();
    DateTime reviewDate = DateTime.now().add(const Duration(days: 90));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final df = DateFormat('dd.MM.yyyy');
          return AlertDialog(
            title: const Text('Yangi Individual Ta’lim Rejasi (ITR) yaratish'),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 430;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'O‘quvchini tanlang *',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStudentId,
                          isExpanded: true,
                          items: students.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.fullName} (${s.grade}-sinf)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedStudentId = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'ITR Nomi *',
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isNarrow) ...[
                          TextField(
                            controller: academicYearController,
                            decoration: const InputDecoration(
                              labelText: 'O‘quv yili *',
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(LucideIcons.calendar, size: 16),
                              label: Text(
                                'Ko‘rib chiqish: ${df.format(reviewDate)}',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: reviewDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setModalState(() => reviewDate = picked);
                                }
                              },
                            ),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: academicYearController,
                                  decoration: const InputDecoration(
                                    labelText: 'O‘quv yili *',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
                                  ),
                                  icon: const Icon(
                                    LucideIcons.calendar,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Ko‘rib chiqish: ${df.format(reviewDate)}',
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: reviewDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      setModalState(() => reviewDate = picked);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: baselineController,
                          decoration: const InputDecoration(
                            labelText: 'Boshlang‘ich holat (Baseline) *',
                            hintText:
                                'Diagnostika va kuzatuvlar asosidagi joriy ta’limiy tayyorgarlik darajasi',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: goalsController,
                          decoration: const InputDecoration(
                            labelText: 'Uzoq muddatli maqsadlar *',
                            hintText:
                                'O‘quv yili oxirigacha erishilishi kutilayotgan umumiy natija',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: strategiesController,
                          decoration: const InputDecoration(
                            labelText:
                                'Qo‘llab-quvvatlash choralari va moslashtirishlar',
                            hintText:
                                'Pedagogik usullar, yordamchi jihozlar, adaptatsiyalar',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Birinchi o‘lchanadigan oraliq maqsad:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: objTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Oraliq maqsad tavsifi *',
                            hintText:
                                'Masalan: Lug‘at boyligini 20 ta so‘zga oshirish',
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isNarrow) ...[
                          DropdownButtonFormField<String>(
                            initialValue: selectedDomain,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Soha',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Kognitiv',
                                child: Text('Kognitiv'),
                              ),
                              DropdownMenuItem(
                                value: 'Nutq',
                                child: Text('Nutq va muloqot'),
                              ),
                              DropdownMenuItem(
                                value: 'O‘quv',
                                child: Text('O‘quv ko‘nikmalari'),
                              ),
                              DropdownMenuItem(
                                value: 'Ijtimoiy-hissiy',
                                child: Text('Ijtimoiy-hissiy'),
                              ),
                              DropdownMenuItem(
                                value: 'Sensor-motorika',
                                child: Text('Sensor-motorika'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedDomain = val);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: objStartingLevelController,
                                  decoration: const InputDecoration(
                                    labelText: 'Boshlang‘ich',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: objTargetLevelController,
                                  decoration: const InputDecoration(
                                    labelText: 'Maqsadli',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: selectedDomain,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Soha',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Kognitiv',
                                      child: Text('Kognitiv'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Nutq',
                                      child: Text('Nutq va muloqot'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'O‘quv',
                                      child: Text('O‘quv ko‘nikmalari'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Ijtimoiy-hissiy',
                                      child: Text('Ijtimoiy-hissiy'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Sensor-motorika',
                                      child: Text('Sensor-motorika'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => selectedDomain = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: objStartingLevelController,
                                  decoration: const InputDecoration(
                                    labelText: 'Boshlang‘ich daraja',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: objTargetLevelController,
                                  decoration: const InputDecoration(
                                    labelText: 'Maqsadli daraja',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: objCriteriaController,
                          decoration: const InputDecoration(
                            labelText: 'Muvaffaqiyat o‘lchov mezoni *',
                            hintText: 'Natijani aniq tekshirish mezoni',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor qilish'),
              ),
              FilledButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty ||
                      baselineController.text.trim().isEmpty ||
                      goalsController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Iltimos, barcha majburiy maydonlarni to‘ldiring',
                        ),
                      ),
                    );
                    return;
                  }

                  final targetStudent = students.firstWhere(
                    (s) => s.id == selectedStudentId,
                  );
                  final planId = 'iep_${DateTime.now().millisecondsSinceEpoch}';

                  final initialObjective = PlanObjectiveModel(
                    id: 'obj_${DateTime.now().millisecondsSinceEpoch}',
                    title: objTitleController.text.trim().isNotEmpty
                        ? objTitleController.text.trim()
                        : 'Dastlabki o‘quv ko‘nikmalarini shakllantirish',
                    domain: selectedDomain,
                    startingLevel: objStartingLevelController.text.trim(),
                    targetLevel: objTargetLevelController.text.trim(),
                    measurementCriteria: objCriteriaController.text.trim(),
                    responsibleSpecialistId: currentUser.id,
                    responsibleSpecialistName: currentUser.fullName,
                    startDate: startDate,
                    targetDate: reviewDate,
                    status: 'Jarayonda',
                    progressPercent: 0,
                    successCriteria: objCriteriaController.text.trim(),
                  );

                  final newPlan = IndividualEducationPlanModel(
                    id: planId,
                    studentId: targetStudent.id,
                    studentName: targetStudent.fullName,
                    studentGrade: targetStudent.grade,
                    institutionName: targetStudent.institutionName,
                    title: titleController.text.trim(),
                    academicYear: academicYearController.text.trim(),
                    startDate: startDate,
                    reviewDate: reviewDate,
                    responsibleTeacherId: currentUser.id,
                    responsibleTeacherName: currentUser.fullName,
                    coordinatorId:
                        targetStudent.coordinatorId ?? currentUser.id,
                    coordinatorName:
                        targetStudent.coordinatorName ?? currentUser.fullName,
                    status: 'Faol',
                    baselineSummary: baselineController.text.trim(),
                    longTermGoals: goalsController.text.trim(),
                    supportStrategies: strategiesController.text.trim(),
                    objectives: [initialObjective],
                  );

                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  await app.addIepPlan(newPlan, byUser: currentUser);
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Individual Ta’lim Rejasi muvaffaqiyatli yaratildi',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Saqlash va Tasdiqlash'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddObjectiveDialog(
    BuildContext context,
    IndividualEducationPlanModel plan,
    UserModel currentUser,
  ) {
    final titleController = TextEditingController();
    String selectedDomain = 'Kognitiv';
    final startLevelController = TextEditingController(text: '0%');
    final targetLevelController = TextEditingController(text: '100%');
    final criteriaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('${plan.studentName} uchun oraliq maqsad qo‘shish'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Maqsad nomi *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDomain,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Soha'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Kognitiv',
                          child: Text('Kognitiv'),
                        ),
                        DropdownMenuItem(
                          value: 'Nutq',
                          child: Text('Nutq va muloqot'),
                        ),
                        DropdownMenuItem(
                          value: 'O‘quv',
                          child: Text('O‘quv ko‘nikmalari'),
                        ),
                        DropdownMenuItem(
                          value: 'Ijtimoiy-hissiy',
                          child: Text('Ijtimoiy-hissiy'),
                        ),
                        DropdownMenuItem(
                          value: 'Sensor-motorika',
                          child: Text('Sensor-motorika'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedDomain = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startLevelController,
                            decoration: const InputDecoration(
                              labelText: 'Boshlang‘ich daraja',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: targetLevelController,
                            decoration: const InputDecoration(
                              labelText: 'Maqsadli daraja',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: criteriaController,
                      decoration: const InputDecoration(
                        labelText: 'Muvaffaqiyat o‘lchov mezoni *',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor qilish'),
              ),
              FilledButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maqsad nomini kiriting')),
                    );
                    return;
                  }

                  final newObj = PlanObjectiveModel(
                    id: 'obj_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleController.text.trim(),
                    domain: selectedDomain,
                    startingLevel: startLevelController.text.trim(),
                    targetLevel: targetLevelController.text.trim(),
                    measurementCriteria: criteriaController.text.trim(),
                    responsibleSpecialistId: currentUser.id,
                    responsibleSpecialistName: currentUser.fullName,
                    startDate: DateTime.now(),
                    targetDate: plan.reviewDate,
                    status: 'Jarayonda',
                    progressPercent: 0,
                    successCriteria: criteriaController.text.trim(),
                  );

                  final updated = plan.copyWith(
                    objectives: [...plan.objectives, newObj],
                  );

                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  await context.read<AppProvider>().updateIepPlan(
                    updated,
                    byUser: currentUser,
                  );
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Yangi oraliq maqsad ITRga qo‘shildi'),
                      ),
                    );
                  }
                },
                child: const Text('Qo‘shish'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final allPlans = app.iepPlans;
    final canPop = Navigator.canPop(context);

    final canCreateIep =
        currentUser != null &&
        (currentUser.role == UserRole.superAdmin ||
            currentUser.role == UserRole.institutionAdmin ||
            currentUser.role == UserRole.coordinator ||
            currentUser.role == UserRole.specialEducation ||
            currentUser.role == UserRole.teacher);

    final filterItems = ['Barchasi', 'Faol', 'Yakunlangan'];
    final counts = <String, int>{
      'Barchasi': allPlans.length,
      'Faol': allPlans.where((p) => p.averageProgress < 100).length,
      'Yakunlangan': allPlans.where((p) => p.averageProgress >= 100).length,
    };

    final plans = allPlans.where((p) {
      if (_selectedStatus == 'Faol') return p.averageProgress < 100;
      if (_selectedStatus == 'Yakunlangan') return p.averageProgress >= 100;
      return true;
    }).toList();

    final width = MediaQuery.sizeOf(context).width;
    final mediaPadding = MediaQuery.paddingOf(context);

    final content = ResponsivePageContainer(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptivePageHeader(
            title: 'Individual rejalar (ITR)',
            subtitle:
                'Shaxsiy o‘quv rejalari va maqsadlar • ${allPlans.length} ta',
            action: canCreateIep
                ? HeaderActionButton(
                    icon: LucideIcons.plus,
                    label: 'Yangi ITR',
                    onPressed: () => _showCreateIepDialog(context, currentUser),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          ModernPillFilterBar(
            items: filterItems,
            selectedItem: _selectedStatus,
            counts: counts,
            onSelected: (val) => setState(() => _selectedStatus = val),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: plans.isEmpty
                ? Center(
                    child: SurfaceCard(
                      borderRadius: 22,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 36,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.bookOpen,
                            size: 34,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Tanlangan filtr bo‘yicha ITR rejalari topilmadi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'O‘quvchi uchun yangi individual ta’lim rejasini shakllantirishingiz mumkin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                          if (canCreateIep) ...[
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text('ITR rejasi tuzish'),
                              onPressed: () =>
                                  _showCreateIepDialog(context, currentUser),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      width < 920 ? (84.0 + mediaPadding.bottom) : 24.0,
                    ),
                    itemCount: plans.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = plans[index];
                      final student = app.students.firstWhere(
                        (s) => s.id == p.studentId,
                        orElse: () =>
                            app.allStudentsIncludingArchived.firstWhere(
                              (s) => s.id == p.studentId,
                              orElse: () => app.students.isNotEmpty
                                  ? app.students.first
                                  : app.allStudentsIncludingArchived.first,
                            ),
                      );
                      return _buildIepCard(context, p, student, currentUser);
                    },
                  ),
          ),
        ],
      ),
    );

    if (canPop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Individual Ta’lim Rejalari')),
        body: AmbientMeshBackground(child: content),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: content,
    );
  }

  Widget _buildIepCard(
    BuildContext context,
    IndividualEducationPlanModel p,
    StudentModel student,
    UserModel? currentUser,
  ) {
    final app = context.watch<AppProvider>();
    final df = DateFormat('dd.MM.yyyy');
    final canEdit =
        currentUser != null &&
        (_access.canManageUsers(currentUser) ||
            currentUser.role == UserRole.coordinator ||
            currentUser.role == UserRole.specialEducation ||
            p.responsibleTeacherId == currentUser.id);

    final avg = p.averageProgress;
    final progressColor = avg >= 75
        ? AppColors.success
        : avg >= 40
            ? AppColors.primary
            : AppColors.warning;

    return SurfaceCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 540;

          final printButton = OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border, width: 1.0),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            ),
            icon: const Icon(LucideIcons.printer, size: 15),
            label: const Text(
              'Rasmiy Blank',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IepPrintScreen(plan: p, student: student),
                ),
              );
            },
          );

          final titleAndMeta = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.25,
                    ),
                  ),
                  StatusPill(
                    label: 'O‘rtacha ijro: ${avg.toStringAsFixed(0)}%',
                    color: progressColor,
                    showDot: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentDetailScreen(studentId: student.id),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.userRound,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '${p.studentName} (${p.studentGrade}-sinf)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'O‘quv yili: ${p.academicYear}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Mas’ul: ${p.responsibleTeacherName}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    '${df.format(p.startDate)} — ${df.format(p.reviewDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact) ...[
                titleAndMeta,
                const SizedBox(height: 14),
                printButton,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleAndMeta),
                    const SizedBox(width: 16),
                    printButton,
                  ],
                ),
              const SizedBox(height: 16),

              // Boshlang'ich daraja va uzoq muddatli maqsadlar
              GlassWell(
                borderRadius: 12,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Boshlang‘ich holat (Baseline): ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(text: p.baselineSummary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.primaryDark,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Uzoq muddatli maqsad: ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: p.longTermGoals,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (p.supportStrategies != null &&
                        p.supportStrategies!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Qo‘llab-quvvatlash: ${p.supportStrategies!}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Maqsadlar sarlavhasi
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.target,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'O‘lchanadigan maqsadlar (${p.completedObjectivesCount}/${p.totalObjectivesCount} bajarildi)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (canEdit)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(LucideIcons.plus, size: 15),
                      label: const Text(
                        'Maqsad qo‘shish',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () =>
                          _showAddObjectiveDialog(context, p, currentUser),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              ...p.objectives.map((obj) {
                final objPercent = obj.progressPercent;
                final objColor = objPercent >= 80
                    ? AppColors.success
                    : objPercent >= 40
                        ? AppColors.primary
                        : AppColors.warning;

                final sliderRow = Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5.5,
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7.5,
                          ),
                        ),
                        child: Slider(
                          value: objPercent.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          activeColor: objColor,
                          inactiveColor: objColor.withValues(alpha: 0.16),
                          label: '$objPercent%',
                          onChanged: canEdit
                              ? (val) {
                                  app.updateObjectiveProgress(
                                    p.id,
                                    obj.id,
                                    val.toInt(),
                                    byUser: currentUser,
                                  );
                                }
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      width: 52,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$objPercent%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: objColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                );

                final objectiveInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obj.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${obj.domain} • Mezon: ${obj.measurementCriteria ?? obj.successCriteria ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                );

                return GlassWell(
                  margin: const EdgeInsets.only(bottom: 10),
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            objectiveInfo,
                            const SizedBox(height: 8),
                            sliderRow,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(flex: 5, child: objectiveInfo),
                            const SizedBox(width: 14),
                            Expanded(flex: 4, child: sliderRow),
                          ],
                        ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
