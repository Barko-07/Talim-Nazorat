import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/iep_model.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';

class PsychologistSupportPlansTab extends StatefulWidget {
  final StudentModel? preselectedStudent;

  const PsychologistSupportPlansTab({super.key, this.preselectedStudent});

  @override
  State<PsychologistSupportPlansTab> createState() =>
      _PsychologistSupportPlansTabState();
}

class _PsychologistSupportPlansTabState
    extends State<PsychologistSupportPlansTab> {
  String? _selectedStudentId;
  String? _selectedStatus;

  void _showUpdateProgressDialog(
    BuildContext context,
    IndividualEducationPlanModel plan,
    PlanObjectiveModel objective,
  ) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    int currentProgress = objective.progressPercent;
    final notesCtrl = TextEditingController(
      text: objective.evidenceNotes ?? '',
    );

    showDialog(
      context: context,
      builder:
          (dlgCtx) => StatefulBuilder(
            builder:
                (context, setDlgState) => AlertDialog(
                  title: const Text('Maqsad bo‘yicha progressni yangilash'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maqsad: ${objective.title}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bajarilish darajasi:',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '$currentProgress%',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: currentProgress.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: AppColors.primary,
                        label: '$currentProgress%',
                        onChanged:
                            (v) =>
                                setDlgState(() => currentProgress = v.toInt()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText:
                              'Dalil va pedagogik-psixologik kuzatuv izohi',
                          hintText:
                              'O‘tkazilgan testlar va erishilgan natija...',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dlgCtx),
                      child: const Text('Bekor qilish'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        await app.updateObjectiveProgress(
                          plan.id,
                          objective.id,
                          currentProgress,
                          evidenceNotes: notesCtrl.text.trim(),
                          byUser: auth.currentUser,
                        );
                        if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Maqsad progressi yangilandi!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: const Text('Saqlash'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showAddObjectiveDialog(
    BuildContext context,
    IndividualEducationPlanModel plan,
  ) {
    final app = context.read<AppProvider>();
    final titleCtrl = TextEditingController();
    final criteriaCtrl = TextEditingController(
      text: 'Mustaqil ravishda 10 tadan 8 tasini to‘g‘ri bajarish',
    );
    String domain = 'Kognitiv';
    DateTime targetDate = DateTime.now().add(const Duration(days: 90));

    showDialog(
      context: context,
      builder:
          (dlgCtx) => StatefulBuilder(
            builder: (context, setDlgState) {
              final df = DateFormat('dd.MM.yyyy');

              return AlertDialog(
                title: const Text('Yangi Psixologik Yordam Maqsadi Qo‘shish'),
                content: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Maqsad nomi *',
                          hintText:
                              'Masalan: Ixtiyoriy diqqatni 20 daqiqa ushlab turish',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: domain,
                        decoration: const InputDecoration(labelText: 'Soha'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Kognitiv',
                            child: Text('Kognitiv va intellekt'),
                          ),
                          DropdownMenuItem(
                            value: 'Ijtimoiy-hissiy',
                            child: Text('Emotsional-irodaviy soha'),
                          ),
                          DropdownMenuItem(
                            value: 'Diqqat',
                            child: Text('Diqqat va ishchanlik'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setDlgState(() => domain = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: criteriaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'O‘lchov mezoni',
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: targetDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setDlgState(() => targetDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Kutilayotgan erishish sanasi',
                            suffixIcon: Icon(LucideIcons.calendar, size: 18),
                          ),
                          child: Text(df.format(targetDate)),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dlgCtx),
                    child: const Text('Bekor qilish'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;

                      final newObj = PlanObjectiveModel(
                        id: 'obj_psy_${const Uuid().v4().substring(0, 8)}',
                        title: titleCtrl.text.trim(),
                        domain: domain,
                        startingLevel: '30%',
                        targetLevel: '85%',
                        measurementCriteria: criteriaCtrl.text.trim(),
                        responsibleSpecialistId: 'user_psychologist',
                        responsibleSpecialistName:
                            'Usmonova Dilnoza (Psixolog)',
                        startDate: DateTime.now(),
                        targetDate: targetDate,
                        status: 'Rejalashtirilgan',
                        progressPercent: 30,
                      );

                      final updatedPlan = plan.copyWith(
                        objectives: [...plan.objectives, newObj],
                      );

                      await app.updateIepPlan(updatedPlan);
                      if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Yangi psixologik maqsad rejaga kiritildi!',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    child: const Text('Rejaga qo‘shish'),
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
    final students = app.students;
    final allPlans = app.iepPlans;
    final df = DateFormat('dd.MM.yyyy');

    final filteredPlans =
        allPlans.where((p) {
          if (_selectedStudentId != null && p.studentId != _selectedStudentId) {
            return false;
          }
          if (_selectedStatus != null && p.status != _selectedStatus) {
            return false;
          }
          return true;
        }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Psixologik Yordam Rejalari (ITR)',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${filteredPlans.length} ta reja',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bolaning kognitiv, emotsional va xulq-atvor maqsadlari, korreksion ishlar va erishilgan natijalar',
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
          const SizedBox(height: 18),

          // FILTRLAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String?>(
                      value: _selectedStudentId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'O‘quvchi bo‘yicha filter',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Barcha o‘quvchilar'),
                        ),
                        ...students.map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              '${s.fullName} (${s.grade})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedStudentId = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      value: _selectedStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Holati',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Barcha holatlar'),
                        ),
                        DropdownMenuItem(
                          value: 'Faol',
                          child: Text('Faol rejalar'),
                        ),
                        DropdownMenuItem(
                          value: 'Yakunlangan',
                          child: Text('Yakunlangan'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedStatus = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // REJALAR RO'YXATI
          if (filteredPlans.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    LucideIcons.clipboardList,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Yordam rejalari topilmadi',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredPlans.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final p = filteredPlans[i];
                final avgProgress = p.averageProgress;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reja sarvaraqasi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.studentName,
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMuted,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${p.studentGrade} • ${p.academicYear}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$avgProgress%',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'Umumiy o‘zlashtirish',
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
                        const SizedBox(height: 14),

                        // Boshlang'ich holat va maqsadlar
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dastlabki holat (Baseline): ${p.baselineSummary}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kutilayotgan uzoq muddatli natija: ${p.longTermGoals}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // MAQSADLAR RO'YXATI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Psixologik korreksion vazifalar (${p.objectives.length} ta):',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed:
                                  () => _showAddObjectiveDialog(context, p),
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text(
                                'Maqsad qo‘shish',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ...p.objectives.map((obj) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              obj.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              obj.domain,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mezon: ${obj.measurementCriteria ?? "Mustaqil bajarish"} • Muddat: ${df.format(obj.targetDate)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: obj.progressPercent / 100.0,
                                        backgroundColor: AppColors.border,
                                        color:
                                            obj.progressPercent >= 80
                                                ? AppColors.success
                                                : AppColors.primary,
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${obj.progressPercent}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed:
                                          () => _showUpdateProgressDialog(
                                            context,
                                            p,
                                            obj,
                                          ),
                                      child: const Text(
                                        'Yangilash',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
