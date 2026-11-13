import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/psychologist_observation_model.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/theme/box_input_border.dart';

class PsychologistObservationsTab extends StatefulWidget {
  final StudentModel? preselectedStudent;

  const PsychologistObservationsTab({super.key, this.preselectedStudent});

  @override
  State<PsychologistObservationsTab> createState() =>
      _PsychologistObservationsTabState();
}

class _PsychologistObservationsTabState
    extends State<PsychologistObservationsTab> {
  String _search = '';
  String? _categoryFilter;
  String? _stateFilter;

  static const List<String> _categories = [
    'Darsdagi xulq-atvor',
    'Hissiy holat (Affektiv)',
    'Tengdoshlar bilan muloqot',
    'Kognitiv faollik va diqqat',
    'Sensor yoki xavotir belgilari',
  ];

  static const List<String> _emotionalStates = [
    'Barqaror / Ijobiy',
    'Xavotirli',
    'Tirishqoq / Chalg‘uvchan',
    'Agressiv / Qo‘zg‘aluvchan',
    'Passiv / Tortinchoq',
  ];

  void showAddObservationDialog(
    BuildContext context, {
    StudentModel? initialStudent,
  }) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final students = app.students;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kuzatuv qayd etish uchun birorta o‘quvchi mavjud emas.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    StudentModel selectedStudent = initialStudent ?? students.first;
    String selectedCategory = _categories.first;
    String selectedState = _emotionalStates.first;
    final triggerCtrl = TextEditingController(
      text: 'Dars jarayonida mustaqil topshiriq berilganda',
    );
    final textCtrl = TextEditingController();
    final recCtrl = TextEditingController();
    DateTime obsDate = DateTime.now();

    showDialog(
      context: context,
      builder:
          (dlgCtx) => StatefulBuilder(
            builder: (context, setDlgState) {
              final df = DateFormat('dd.MM.yyyy');

              return AlertDialog(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.notebookPen,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Kuzatuv Kundaligiga Yangi Qayd',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 540,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // O'quvchi
                        DropdownButtonFormField<StudentModel>(
                          initialValue:
                              students.contains(selectedStudent)
                                  ? selectedStudent
                                  : students.first,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kuzatilgan o‘quvchi *',
                          ),
                          items:
                              students
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        '${s.fullName} (${s.grade})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDlgState(() => selectedStudent = v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Sana
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: obsDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setDlgState(() => obsDate = picked);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Kuzatuv sanasi *',
                                    suffixIcon: Icon(
                                      LucideIcons.calendar,
                                      size: 18,
                                    ),
                                  ),
                                  child: Text(df.format(obsDate)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedState,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Emotsional holati *',
                                ),
                                items:
                                    _emotionalStates
                                        .map(
                                          (st) => DropdownMenuItem(
                                            value: st,
                                            child: Text(
                                              st,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDlgState(() => selectedState = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Kategoriya
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kuzatuv toifasi *',
                          ),
                          items:
                              _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDlgState(() => selectedCategory = v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Kontekst / Turtki
                        TextField(
                          controller: triggerCtrl,
                          decoration: const InputDecoration(
                            labelText:
                                'Vaziyat / Kontekst (Qachon va qanday sharoitda?)',
                            hintText:
                                'Masalan: Tanaffusda, yangi mavzu o‘tilayotganda...',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Asosiy kuzatuv bayoni
                        TextField(
                          controller: textCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText:
                                'Kuzatilgan xulq-atvor va o‘zgarishlar tavsifi *',
                            hintText:
                                'Bolaning reaksiyasi, xatti-harakati, mimikasi va diqqati...',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tavsiya
                        TextField(
                          controller: recCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText:
                                'Ko‘rilgan chora yoki pedagog/ota-onaga tavsiya',
                            hintText:
                                'Qo‘llanilgan korreksion yondashuv yoki berilgan ko‘rsatma...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dlgCtx),
                    child: const Text('Bekor qilish'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Kundalikka kiritish'),
                    onPressed: () async {
                      if (textCtrl.text.trim().isEmpty) return;

                      final newObs = PsychologicalObservationModel(
                        id: 'obs_${const Uuid().v4().substring(0, 8)}',
                        studentId: selectedStudent.id,
                        studentName: selectedStudent.fullName,
                        studentGrade: selectedStudent.grade,
                        psychologistId: currentUser?.id ?? 'user_psychologist',
                        psychologistName: currentUser?.fullName ?? '',
                        date: obsDate,
                        category: selectedCategory,
                        emotionalState: selectedState,
                        triggerOrContext:
                            triggerCtrl.text.trim().isNotEmpty
                                ? triggerCtrl.text.trim()
                                : null,
                        observationText: textCtrl.text.trim(),
                        recommendationOrAction:
                            recCtrl.text.trim().isNotEmpty
                                ? recCtrl.text.trim()
                                : null,
                        isConfidential: true,
                        createdAt: DateTime.now(),
                      );

                      final sm = ScaffoldMessenger.of(context);
                      await app.addObservation(newObs, byUser: currentUser);
                      if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                      sm.showSnackBar(
                        SnackBar(
                          content: Text(
                            '${selectedStudent.fullName} uchun kuzatuv qayd etildi!',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
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
    final allObservations = app.observations;
    final df = DateFormat('dd.MM.yyyy');

    final filtered =
        allObservations.where((o) {
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            final mName = o.studentName.toLowerCase().contains(q);
            final mText = o.observationText.toLowerCase().contains(q);
            if (!mName && !mText) return false;
          }
          if (_categoryFilter != null && o.category != _categoryFilter) {
            return false;
          }
          if (_stateFilter != null && o.emotionalState != _stateFilter) {
            return false;
          }
          return true;
        }).toList();

    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width < 600 ? 12.0 : 18.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        MediaQuery.paddingOf(context).top + (width >= 920 ? 82 : 74),
        horizontalPad,
        width < 920 ? (84 + MediaQuery.paddingOf(context).bottom) : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sarlavha (Minimalist Glassy Header)
          SurfaceCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final addBtn = HeaderActionButton(
                  label: 'Yangi Kuzatuv Qo‘shish',
                  compactLabel: 'Yangi kuzatuv',
                  icon: LucideIcons.notebookPen,
                  onPressed: () => showAddObservationDialog(context),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: StatusPill(
                            label: '${filtered.length} ta qayd',
                            color: AppColors.warning,
                            backgroundColor: AppColors.warningBg,
                            icon: LucideIcons.bookOpen,
                          ),
                        ),
                        if (!isCompact) ...[const SizedBox(width: 12), addBtn],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Psixologik Kuzatuv Jurnali',
                      style: TextStyle(
                        fontSize: isCompact ? 18.5 : 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bolaning darsdagi xulq-atvori, hissiy holati va dinamik o‘zgarishlari xronologik daftari',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    if (isCompact) ...[const SizedBox(height: 12), addBtn],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // FILTRLAR
          SurfaceCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, c) {
                InputDecoration inputDeco({
                  String? label,
                  String? hint,
                  Widget? prefixIcon,
                }) {
                  return InputDecoration(
                    labelText: label,
                    hintText: hint,
                    prefixIcon: prefixIcon,
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: BoxInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: BoxInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  );
                }

                final searchField = TextField(
                  onChanged: (v) => setState(() => _search = v.trim()),
                  decoration: inputDeco(
                    hint: 'O‘quvchi yoki kuzatuv matni bo‘yicha...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                  ),
                );
                final categoryField = DropdownButtonFormField<String?>(
                  initialValue: _categoryFilter,
                  isExpanded: true,
                  decoration: inputDeco(label: 'Toifa'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Barcha toifalar'),
                    ),
                    ..._categories.map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryFilter = v),
                );
                final stateField = DropdownButtonFormField<String?>(
                  initialValue: _stateFilter,
                  isExpanded: true,
                  decoration: inputDeco(label: 'Emotsional holat'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Barcha holatlar'),
                    ),
                    ..._emotionalStates.map(
                      (st) => DropdownMenuItem(
                        value: st,
                        child: Text(st, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _stateFilter = v),
                );

                if (c.maxWidth < 600) {
                  return Column(
                    children: [
                      searchField,
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: categoryField),
                          const SizedBox(width: 10),
                          Expanded(child: stateField),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 3, child: searchField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: categoryField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: stateField),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // KUZATUVLAR LISTI
          if (filtered.isEmpty)
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.notebookText,
                      size: 44,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kuzatuvlar topilmadi',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yangi kuzatuv qaydini kiritish uchun yuqoridagi tugmadan foydalaning',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final o = filtered[i];
                final isPositive = o.emotionalState.contains('Barqaror');

                return SurfaceCard(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 0.85,
                                  ),
                                ),
                                child: Text(
                                  df.format(o.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                '${o.studentName} (${o.studentGrade})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              StatusPill(
                                label: o.category,
                                color: AppColors.primary,
                                backgroundColor: AppColors.primaryLight,
                              ),
                            ],
                          ),
                          StatusPill(
                            label: o.emotionalState,
                            color:
                                isPositive
                                    ? AppColors.success
                                    : AppColors.warning,
                            backgroundColor:
                                isPositive
                                    ? AppColors.successBg
                                    : AppColors.warningBg,
                          ),
                        ],
                      ),
                      if (o.triggerOrContext != null &&
                          o.triggerOrContext!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Vaziyat: ${o.triggerOrContext}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        o.observationText,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      if (o.recommendationOrAction != null &&
                          o.recommendationOrAction!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        GlassWell(
                          padding: const EdgeInsets.all(12),
                          borderRadius: 12,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.lightbulb,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tavsiya/Chora: ${o.recommendationOrAction}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
