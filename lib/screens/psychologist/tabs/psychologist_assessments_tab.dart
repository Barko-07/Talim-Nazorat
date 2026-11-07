import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/assessment_model.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../assessment/assessment_compare_dialog.dart';
import '../assessment/assessment_result_screen.dart';
import '../assessment/conduct_assessment_screen.dart';
import '../assessment/create_assessment_flow.dart';
import '../assessment/question_library_view.dart';
import '../../../core/widgets/glass_widgets.dart';

class PsychologistAssessmentsTab extends StatefulWidget {
  final StudentModel? preselectedStudent;

  const PsychologistAssessmentsTab({super.key, this.preselectedStudent});

  @override
  State<PsychologistAssessmentsTab> createState() =>
      _PsychologistAssessmentsTabState();
}

class _PsychologistAssessmentsTabState
    extends State<PsychologistAssessmentsTab> {
  int _activeSubTab = 0; // 0: Baholashlar tarixi, 1: Savollar kutubxonasi

  String _search = '';
  String? _categoryFilter;
  String? _statusFilter; // null (barchasi), 'completed', 'draft'
  StudentModel? _filterStudent;

  static const List<String> _categories = [
    'Aralash kompleks diagnostika',
    'Kognitiv va intellektual rivojlanish',
    'Ixtiyoriy diqqat va aqliy ishchanlik',
    'Emotsional-irodaviy holat va xavotir',
    'Ijtimoiy moslashuv va motivatsiya',
    'Nutq va muloqot rivojlanishi',
  ];

  @override
  void initState() {
    super.initState();
    _filterStudent = widget.preselectedStudent;
  }

  void _startNewAssessment([StudentModel? student]) {
    CreateAssessmentFlow.start(
      context,
      initialStudent: student ?? _filterStudent,
    );
  }

  void _resumeDraft(AssessmentModel draft) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ConductAssessmentScreen(
              assessment: draft,
              selectedQuestions: const [],
              isNew: false,
            ),
      ),
    );
  }

  void _confirmDeleteAssessment(AssessmentModel a) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(LucideIcons.triangleAlert, color: Colors.red),
                SizedBox(width: 8),
                Text('Baholashni o‘chirish'),
              ],
            ),
            content: Text(
              'Haqiqatan ham "${a.studentName}" uchun "${a.title}" baholash protokolini o‘chirmoqchimisiz? Bu amal tizim auditida qayd etiladi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bekor qilish'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<AppProvider>().deleteAssessment(a.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Baholash protokoli o‘chirildi.'),
                        backgroundColor: AppColors.textSecondary,
                      ),
                    );
                  }
                },
                child: const Text('O‘chirish'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allAssessments = app.assessments;
    final students = app.students;
    final df = DateFormat('dd.MM.yyyy');

    final completedCount =
        allAssessments.where((a) => a.status == 'completed').length;
    final draftCount = allAssessments.where((a) => a.status == 'draft').length;

    final filtered =
        allAssessments.where((a) {
            if (_search.isNotEmpty) {
              final q = _search.toLowerCase();
              final mName = a.studentName.toLowerCase().contains(q);
              final mTitle = a.title.toLowerCase().contains(q);
              if (!mName && !mTitle) return false;
            }
            if (_categoryFilter != null && a.category != _categoryFilter) {
              return false;
            }
            if (_statusFilter != null && a.status != _statusFilter) {
              return false;
            }
            if (_filterStudent != null && a.studentId != _filterStudent!.id) {
              return false;
            }
            return true;
          }).toList()
          ..sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));

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
          // HEADER (Minimalist Glassy Card)
          SurfaceCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final pills = Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusPill(
                      label: '$completedCount ta yakunlangan',
                      color: AppColors.success,
                      backgroundColor: AppColors.successBg,
                      icon: LucideIcons.circleCheck,
                    ),
                    if (draftCount > 0)
                      StatusPill(
                        label: '$draftCount ta qoralama',
                        color: AppColors.warning,
                        backgroundColor: AppColors.warningBg,
                        icon: LucideIcons.calendarCog,
                      ),
                  ],
                );

                final newAssessmentBtn = HeaderActionButton(
                  label: 'Yangi Baholash Boshlash',
                  compactLabel: 'Yangi baholash',
                  icon: LucideIcons.listPlus,
                  onPressed: () => _startNewAssessment(),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: pills),
                        if (!isCompact) ...[
                          const SizedBox(width: 12),
                          newAssessmentBtn,
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Psixologik Baholash Tizimi',
                      style: TextStyle(
                        fontSize: isCompact ? 18.5 : 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kutubxona savollari asosida psixologik diagnostika va monitoring o‘tkazish',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    if (isCompact) ...[
                      const SizedBox(height: 12),
                      newAssessmentBtn,
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Sub-tabs: Baholashlar tarixi VS Savollar kutubxonasi
          ModernPillFilterBar(
            items: const ['Baholashlar tarixi', 'Savollar kutubxonasi'],
            selectedItem:
                _activeSubTab == 0
                    ? 'Baholashlar tarixi'
                    : 'Savollar kutubxonasi',
            counts: {
              'Baholashlar tarixi': allAssessments.length,
              'Savollar kutubxonasi': app.questions.length,
            },
            onSelected: (item) {
              setState(() {
                _activeSubTab = item == 'Baholashlar tarixi' ? 0 : 1;
              });
            },
          ),
          const SizedBox(height: 16),

          // AGAR SAVOLLAR KUTUBXONASI TANLANGAN BO'LSA
          if (_activeSubTab == 1)
            const QuestionLibraryView(isEmbedded: true)
          else ...[
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
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    );
                  }

                  final searchField = TextField(
                    onChanged: (v) => setState(() => _search = v.trim()),
                    decoration: inputDeco(
                      hint: 'O‘quvchi F.I.SH yoki mavzu...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                    ),
                  );
                  final studentField = DropdownButtonFormField<StudentModel?>(
                    initialValue: _filterStudent,
                    isExpanded: true,
                    decoration: inputDeco(label: 'O‘quvchi'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Barcha o‘quvchilar',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      ...students.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.fullName,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _filterStudent = v),
                  );
                  final categoryField = DropdownButtonFormField<String?>(
                    initialValue: _categoryFilter,
                    isExpanded: true,
                    decoration: inputDeco(label: 'Yo‘nalish'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Barcha yo‘nalishlar',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      ..._categories.map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryFilter = v),
                  );
                  final statusField = DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _statusFilter,
                    decoration: inputDeco(label: 'Holat'),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Barcha holatlar',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text(
                          'Yakunlangan',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'draft',
                        child: Text(
                          'Qoralama',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v),
                  );

                  final hasFilter =
                      _search.isNotEmpty ||
                      _categoryFilter != null ||
                      _statusFilter != null ||
                      _filterStudent != null;

                  final clearBtn =
                      hasFilter
                          ? TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _search = '';
                                _categoryFilter = null;
                                _statusFilter = null;
                                _filterStudent = null;
                              });
                            },
                            icon: const Icon(LucideIcons.listX, size: 16),
                            label: const Text('Filtrni tozalash'),
                          )
                          : null;

                  if (c.maxWidth < 640) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 10),
                        studentField,
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: categoryField),
                            const SizedBox(width: 10),
                            Expanded(child: statusField),
                          ],
                        ),
                        if (clearBtn != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: clearBtn,
                          ),
                        ],
                      ],
                    );
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(width: 240, child: searchField),
                      SizedBox(width: 210, child: studentField),
                      SizedBox(width: 220, child: categoryField),
                      SizedBox(width: 160, child: statusField),
                      if (clearBtn != null) clearBtn,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // BAHOLASHLAR RO'YXATI
            if (filtered.isEmpty)
              SurfaceCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.clipboardX,
                        size: 44,
                        color: AppColors.textSubtle,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mos keluvchi baholashlar topilmadi',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yangi baholash boshlash uchun yuqoridagi tugmadan foydalaning',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      HeaderActionButton(
                        label: 'Yangi baholash boshlash',
                        icon: LucideIcons.plus,
                        onPressed: () => _startNewAssessment(),
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
                  final a = filtered[i];
                  final isDraft = a.status == 'draft';
                  final childAssessments =
                      allAssessments
                          .where((x) => x.studentId == a.studentId)
                          .toList();

                  return SurfaceCard(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(18),
                    borderColor:
                        isDraft
                            ? AppColors.warning.withValues(alpha: 0.45)
                            : AppColors.cardGlassBorder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      isDraft
                                          ? LucideIcons.calendarCog
                                          : LucideIcons.brain,
                                      color:
                                          isDraft
                                              ? AppColors.warning
                                              : AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              a.studentName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15.5,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            StatusPill(
                                              label:
                                                  isDraft
                                                      ? 'Qoralama'
                                                      : 'Yakunlangan',
                                              color:
                                                  isDraft
                                                      ? AppColors.warning
                                                      : AppColors.success,
                                              backgroundColor:
                                                  isDraft
                                                      ? AppColors.warningBg
                                                      : AppColors.successBg,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${a.title} • ${a.category}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (!isDraft)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${a.totalScore.toStringAsFixed(1)} / ${a.maxScore.toStringAsFixed(0)} ball',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.5,
                                      color: AppColors.primary,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusPill(
                                    label: a.trend,
                                    color: AppColors.success,
                                    backgroundColor: AppColors.successBg,
                                  ),
                                ],
                              )
                            else
                              StatusPill(
                                label:
                                    '${a.responses.where((r) => r.isEvaluated).length}/${a.responses.length} savol',
                                color: AppColors.warning,
                                backgroundColor: AppColors.warningBg,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Xulosa snippet
                        if (a.notes.isNotEmpty ||
                            (a.generalConclusion != null &&
                                a.generalConclusion!.isNotEmpty))
                          GlassWell(
                            padding: const EdgeInsets.all(12),
                            borderRadius: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Psixolog xulosasi:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  (a.generalConclusion != null &&
                                          a.generalConclusion!.isNotEmpty)
                                      ? a.generalConclusion!
                                      : a.notes,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Pastki qism: Sana va Amallar
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Sana: ${df.format(a.assessmentDate)} • Mutaxassis: ${a.specialistName}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (isDraft)
                                  HeaderActionButton(
                                    label: 'Davom ettirish',
                                    icon: LucideIcons.play,
                                    onPressed: () => _resumeDraft(a),
                                  )
                                else ...[
                                  if (childAssessments.length > 1)
                                    IconButton.outlined(
                                      icon: Icon(
                                        LucideIcons.arrowLeftRight,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      tooltip: 'Taqqoslash',
                                      onPressed: () {
                                        AssessmentCompareDialog.show(
                                          context,
                                          currentAssessment: a,
                                          studentAssessments: childAssessments,
                                        );
                                      },
                                    ),
                                  HeaderActionButton(
                                    label: 'Natijalarni ko‘rish',
                                    compactLabel: 'Natija',
                                    icon: LucideIcons.eye,
                                    onPressed:
                                        () => AssessmentResultScreen.show(
                                          context,
                                          a,
                                        ),
                                  ),
                                ],
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    size: 17,
                                    color: AppColors.error,
                                  ),
                                  tooltip: 'O‘chirish',
                                  onPressed: () => _confirmDeleteAssessment(a),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
