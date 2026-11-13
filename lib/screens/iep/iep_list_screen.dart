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
import 'new_iep_screen.dart';

class IepListScreen extends StatefulWidget {
  const IepListScreen({super.key});

  @override
  State<IepListScreen> createState() => _IepListScreenState();
}

class _IepListScreenState extends State<IepListScreen> {
  final AccessControlService _access = AccessControlService();
  String _selectedStatus = 'Barchasi';

  void _showCreateIepDialog(BuildContext context, UserModel currentUser) {
    if (context.read<AppProvider>().students.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avval bola qo‘shing')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewIepScreen(currentUser: currentUser)),
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
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                title: Text('Maqsad qo‘shish · ${plan.studentName}'),
                content: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8),
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
                                  labelText: 'Hozir',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: targetLevelController,
                                decoration: const InputDecoration(
                                  labelText: 'Maqsad',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: criteriaController,
                          decoration: const InputDecoration(
                            labelText: 'Qanday tekshiriladi *',
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
                          const SnackBar(
                            content: Text('Maqsad nomini kiriting'),
                          ),
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
                          const SnackBar(content: Text('Maqsad qo‘shildi')),
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
            currentUser.role == UserRole.specialEdTeacher ||
            currentUser.role == UserRole.speechTherapist ||
            currentUser.role == UserRole.psychologist ||
            currentUser.role == UserRole.teacher);

    final filterItems = ['Barchasi', 'Faol', 'Yakunlangan'];
    final counts = <String, int>{
      'Barchasi': allPlans.length,
      'Faol': allPlans.where((p) => p.averageProgress < 100).length,
      'Yakunlangan': allPlans.where((p) => p.averageProgress >= 100).length,
    };

    final plans =
        allPlans.where((p) {
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
            art: PageArtKind.plan,
            title: 'ITR rejalari',
            icon: LucideIcons.fileText,
            subtitle: '${allPlans.length} ta reja',
            action:
                canCreateIep
                    ? HeaderActionButton(
                      icon: LucideIcons.plus,
                      label: 'Yangi ITR',
                      onPressed:
                          () => _showCreateIepDialog(context, currentUser),
                    )
                    : null,
          ),
          const SizedBox(height: 9),
          ModernPillFilterBar(
            items: filterItems,
            selectedItem: _selectedStatus,
            counts: counts,
            onSelected: (val) => setState(() => _selectedStatus = val),
          ),
          const SizedBox(height: 9),
          Expanded(
            child:
                plans.isEmpty
                    ? SurfaceCard(
                      borderRadius: 20,
                      padding: EdgeInsets.zero,
                      margin: EdgeInsets.only(
                        bottom: width < 920 ? 92 + mediaPadding.bottom : 20,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ArtEmptyState(
                          kind: PageArtKind.plan,
                          title:
                              allPlans.isEmpty
                                  ? 'Hali reja yo‘q'
                                  : 'Bu holatda reja yo‘q',
                          message:
                              'Bola uchun maqsad va muddatlarni yozib, ITR rejasini tuzing',
                          actionLabel: canCreateIep ? 'Reja tuzish' : null,
                          onAction:
                              canCreateIep
                                  ? () =>
                                      _showCreateIepDialog(context, currentUser)
                                  : null,
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
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = plans[index];
                        final student = app.students.firstWhere(
                          (s) => s.id == p.studentId,
                          orElse:
                              () => app.allStudentsIncludingArchived.firstWhere(
                                (s) => s.id == p.studentId,
                                orElse:
                                    () =>
                                        app.students.isNotEmpty
                                            ? app.students.first
                                            : app
                                                .allStudentsIncludingArchived
                                                .first,
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
        appBar: AppBar(title: const Text('ITR rejalari')),
        body: AmbientMeshBackground(child: content),
      );
    }

    return Scaffold(backgroundColor: Colors.transparent, body: content);
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
    final progressColor =
        avg >= 75
            ? AppColors.success
            : avg >= 40
            ? AppColors.primary
            : AppColors.warning;

    return SurfaceCard(
      borderRadius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 540;

          final printButton = OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.border, width: 1.0),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            ),
            icon: const Icon(LucideIcons.printer, size: 15),
            label: const Text(
              'Chop etish',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
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
                          builder:
                              (_) => StudentDetailScreen(studentId: student.id),
                        ),
                      );
                    },
                    child: Text(
                      '${p.studentName} (${p.studentGrade}-sinf)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    'O‘quv yili: ${p.academicYear}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Mas’ul: ${p.responsibleTeacherName}',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  Text(
                    '${df.format(p.startDate)} — ${df.format(p.reviewDate)}',
                    style: TextStyle(
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
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Hozirgi holat: ',
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
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.primaryDark,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Yil oxiridagi maqsad: ',
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
                        style: TextStyle(
                          fontSize: 13,
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
                      Icon(
                        LucideIcons.target,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'O‘lchanadigan maqsadlar (${p.completedObjectivesCount}/${p.totalObjectivesCount} bajarildi)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed:
                          () =>
                              _showAddObjectiveDialog(context, p, currentUser),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              ...p.objectives.map((obj) {
                final objPercent = obj.progressPercent;
                final objColor =
                    objPercent >= 80
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
                          onChanged:
                              canEdit
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
                          fontWeight: FontWeight.w700,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${obj.domain} • Mezon: ${obj.measurementCriteria ?? obj.successCriteria ?? ''}',
                      style: TextStyle(
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
                  child:
                      isCompact
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
