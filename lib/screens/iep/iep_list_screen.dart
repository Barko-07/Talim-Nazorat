import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/iep_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/access_control_service.dart';
import 'iep_print_screen.dart';

class IepListScreen extends StatefulWidget {
  const IepListScreen({super.key});

  @override
  State<IepListScreen> createState() => _IepListScreenState();
}

class _IepListScreenState extends State<IepListScreen> {
  final AccessControlService _access = AccessControlService();

  void _showCreateIepDialog(BuildContext context, UserModel currentUser) {
    final app = context.read<AppProvider>();
    final students = app.students;
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avval o‘quvchi ro‘yxatdan o‘tgan bo‘lishi kerak')),
      );
      return;
    }

    String selectedStudentId = students.first.id;
    final titleController = TextEditingController(text: '2026-2027 o‘quv yili uchun ITR');
    final academicYearController = TextEditingController(text: '2026-2027');
    final baselineController = TextEditingController();
    final goalsController = TextEditingController();
    final strategiesController = TextEditingController();
    final objTitleController = TextEditingController();
    String selectedDomain = 'Kognitiv';
    final objStartingLevelController = TextEditingController(text: '20%');
    final objTargetLevelController = TextEditingController(text: '80%');
    final objCriteriaController = TextEditingController(text: 'Mustaqil ravishda 10 tadan 8 tasini to‘g‘ri bajarish');

    DateTime startDate = DateTime.now();
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('O‘quvchini tanlang *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedStudentId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: students.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.fullName} (${s.grade}-sinf)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedStudentId = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'ITR Nomi *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: academicYearController,
                            decoration: const InputDecoration(labelText: 'O‘quv yili *', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: Text('Ko‘rib chiqish: ${df.format(reviewDate)}', style: const TextStyle(fontSize: 12)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: reviewDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        hintText: 'Diagnostika va kuzatuvlar asosidagi joriy ta’limiy tayyorgarlik darajasi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: goalsController,
                      decoration: const InputDecoration(
                        labelText: 'Uzoq muddatli maqsadlar *',
                        hintText: 'O‘quv yili oxirigacha erishilishi kutilayotgan umumiy natija',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: strategiesController,
                      decoration: const InputDecoration(
                        labelText: 'Qo‘llab-quvvatlash choralari va moslashtirishlar',
                        hintText: 'Pedagogik usullar, yordamchi jihozlar, adaptatsiyalar',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    const Divider(),
                    const Text('Birinchi o‘lchanadigan oraliq maqsad:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 8),

                    TextField(
                      controller: objTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Oraliq maqsad tavsifi *',
                        hintText: 'Masalan: Lug‘at boyligini 20 ta so‘zga oshirish',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDomain,
                            decoration: const InputDecoration(labelText: 'Soha', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'Kognitiv', child: Text('Kognitiv')),
                              DropdownMenuItem(value: 'Nutq', child: Text('Nutq va muloqot')),
                              DropdownMenuItem(value: 'O‘quv', child: Text('O‘quv ko‘nikmalari')),
                              DropdownMenuItem(value: 'Ijtimoiy-hissiy', child: Text('Ijtimoiy-hissiy')),
                              DropdownMenuItem(value: 'Sensor-motorika', child: Text('Sensor-motorika')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedDomain = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: objStartingLevelController,
                            decoration: const InputDecoration(labelText: 'Boshlang‘ich daraja', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: objTargetLevelController,
                            decoration: const InputDecoration(labelText: 'Maqsadli daraja', border: OutlineInputBorder()),
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
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
              FilledButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty ||
                      baselineController.text.trim().isEmpty ||
                      goalsController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Iltimos, barcha majburiy maydonlarni to‘ldiring')),
                    );
                    return;
                  }

                  final targetStudent = students.firstWhere((s) => s.id == selectedStudentId);
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
                    institutionName: targetStudent.institutionName ?? currentUser.institutionName ?? '14-sonli maktab',
                    title: titleController.text.trim(),
                    academicYear: academicYearController.text.trim(),
                    startDate: startDate,
                    reviewDate: reviewDate,
                    responsibleTeacherId: currentUser.id,
                    responsibleTeacherName: currentUser.fullName,
                    coordinatorId: targetStudent.coordinatorId ?? currentUser.id,
                    coordinatorName: targetStudent.coordinatorName ?? currentUser.fullName,
                    status: 'Faol',
                    baselineSummary: baselineController.text.trim(),
                    longTermGoals: goalsController.text.trim(),
                    supportStrategies: strategiesController.text.trim(),
                    objectives: [initialObjective],
                  );

                  Navigator.pop(ctx);
                  await app.addIepPlan(newPlan, byUser: currentUser);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Individual Ta’lim Rejasi muvaffaqiyatli yaratildi')),
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

  void _showAddObjectiveDialog(BuildContext context, IndividualEducationPlanModel plan, UserModel currentUser) {
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
                      decoration: const InputDecoration(labelText: 'Maqsad nomi *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDomain,
                      decoration: const InputDecoration(labelText: 'Soha', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Kognitiv', child: Text('Kognitiv')),
                        DropdownMenuItem(value: 'Nutq', child: Text('Nutq va muloqot')),
                        DropdownMenuItem(value: 'O‘quv', child: Text('O‘quv ko‘nikmalari')),
                        DropdownMenuItem(value: 'Ijtimoiy-hissiy', child: Text('Ijtimoiy-hissiy')),
                        DropdownMenuItem(value: 'Sensor-motorika', child: Text('Sensor-motorika')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDomain = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startLevelController,
                            decoration: const InputDecoration(labelText: 'Boshlang‘ich daraja', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: targetLevelController,
                            decoration: const InputDecoration(labelText: 'Maqsadli daraja', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: criteriaController,
                      decoration: const InputDecoration(labelText: 'Muvaffaqiyat o‘lchov mezoni *', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
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

                  Navigator.pop(ctx);
                  await context.read<AppProvider>().updateIepPlan(updated, byUser: currentUser);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yangi oraliq maqsad ITRga qo‘shildi')),
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
    final plans = app.iepPlans;

    final canCreateIep = currentUser != null &&
        (currentUser.role == UserRole.superAdmin ||
            currentUser.role == UserRole.institutionAdmin ||
            currentUser.role == UserRole.coordinator ||
            currentUser.role == UserRole.specialEducation ||
            currentUser.role == UserRole.teacher);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Individual Ta’lim Rejalari (ITR)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alohida ta’lim ehtiyoji bo‘lgan o‘quvchilarning shaxsiy ta’limiy rejalari (${plans.length} ta)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                if (canCreateIep)
                  FilledButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Yangi ITR yaratish'),
                    onPressed: () => _showCreateIepDialog(context, currentUser),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: plans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('Hozircha ITR rejalari mavjud emas', style: TextStyle(fontWeight: FontWeight.w600)),
                          if (canCreateIep) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('ITR rejasi tuzish'),
                              onPressed: () => _showCreateIepDialog(context, currentUser),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: plans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final p = plans[index];
                        final student = app.students.firstWhere(
                          (s) => s.id == p.studentId,
                          orElse: () => app.allStudentsIncludingArchived.firstWhere(
                            (s) => s.id == p.studentId,
                            orElse: () => app.students.isNotEmpty ? app.students.first : app.allStudentsIncludingArchived.first,
                          ),
                        );
                        return _buildIepCard(context, p, student, currentUser);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIepCard(BuildContext context, IndividualEducationPlanModel p, dynamic student, UserModel? currentUser) {
    final app = context.watch<AppProvider>();
    final df = DateFormat('dd.MM.yyyy');
    final canEdit = currentUser != null &&
        (_access.canManageUsers(currentUser) ||
            currentUser.role == UserRole.coordinator ||
            currentUser.role == UserRole.specialEducation ||
            p.responsibleTeacherId == currentUser.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'O‘rtacha ijro: ${p.averageProgress.toStringAsFixed(0)}%',
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
                      Text(
                        'O‘quvchi: ${p.studentName} (${p.studentGrade}-sinf) • O‘quv yili: ${p.academicYear}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Mas’ul: ${p.responsibleTeacherName} • Muddat: ${df.format(p.startDate)} — ${df.format(p.reviewDate)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Rasmiy Blank'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IepPrintScreen(plan: p, student: student),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Boshlang'ich daraja va Maqsadlar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Boshlang‘ich daraja (Baseline): ${p.baselineSummary}', style: const TextStyle(fontSize: 12, height: 1.3)),
                  const SizedBox(height: 4),
                  Text('Uzoq muddatli maqsad: ${p.longTermGoals}', style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                  if (p.supportStrategies != null && p.supportStrategies!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Qo‘llab-quvvatlash: ${p.supportStrategies!}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Maqsadlar ro'yxati
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'O‘lchanadigan maqsadlar (${p.completedObjectivesCount}/${p.totalObjectivesCount} bajarildi):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (canEdit)
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Maqsad qo‘shish', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showAddObjectiveDialog(context, p, currentUser),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            ...p.objectives.map((obj) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(obj.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                            '${obj.domain} • Mezon: ${obj.measurementCriteria ?? obj.successCriteria ?? ''}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Slider(
                        value: obj.progressPercent.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: AppColors.primary,
                        label: '${obj.progressPercent}%',
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
                    SizedBox(
                      width: 45,
                      child: Text('${obj.progressPercent}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

