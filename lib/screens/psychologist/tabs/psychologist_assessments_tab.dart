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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Psixologik Baholash Tizimi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '$completedCount ta yakunlangan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        if (draftCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '$draftCount ta qoralama',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kutubxona savollari asosida psixologik diagnostika va monitoring o‘tkazish',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onPressed: () => _startNewAssessment(),
                icon: const Icon(LucideIcons.listPlus, size: 18),
                label: const Text('Yangi Baholash Boshlash'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Sub-tabs: Baholashlar tarixi VS Savollar kutubxonasi
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('Baholashlar tarixi (${allAssessments.length})'),
                selected: _activeSubTab == 0,
                onSelected: (s) {
                  if (s) setState(() => _activeSubTab = 0);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Savollar kutubxonasi (${app.questions.length})'),
                selected: _activeSubTab == 1,
                onSelected: (s) {
                  if (s) setState(() => _activeSubTab = 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AGAR SAVOLLAR KUTUBXONASI TANLANGAN BO'LSA
          if (_activeSubTab == 1)
            const QuestionLibraryView(isEmbedded: true)
          else ...[
            // FILTRLAR
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Qidiruv
                    SizedBox(
                      width: 260,
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'O‘quvchi F.I.SH yoki mavzu...',
                          prefixIcon: const Icon(LucideIcons.search, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    // O'quvchi bo'yicha
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<StudentModel?>(
                        value: _filterStudent,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'O‘quvchi',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
                      ),
                    ),
                    // Yo'nalish
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String?>(
                        value: _categoryFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Yo‘nalish',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'Barcha yo‘nalishlar',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ..._categories.map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _categoryFilter = v),
                      ),
                    ),
                    // Holati (Barchasi, Yakunlangan, Qoralama)
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: _statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Holat',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
                      ),
                    ),
                    if (_search.isNotEmpty ||
                        _categoryFilter != null ||
                        _statusFilter != null ||
                        _filterStudent != null)
                      TextButton.icon(
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
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // BAHOLASHLAR RO'YXATI
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.clipboardX,
                      size: 48,
                      color: AppColors.textMuted,
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
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Yangi baholash boshlash'),
                      onPressed: () => _startNewAssessment(),
                    ),
                  ],
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

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            isDraft
                                ? AppColors.warning.withValues(alpha: 0.5)
                                : AppColors.border,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            isDraft
                                                ? AppColors.warningBg
                                                : AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  a.studentName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15.5,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isDraft
                                                          ? AppColors.warningBg
                                                          : AppColors.successBg,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color:
                                                        isDraft
                                                            ? AppColors.warning
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                )
                                                            : AppColors.success
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                  ),
                                                ),
                                                child: Text(
                                                  isDraft
                                                      ? 'Qoralama'
                                                      : 'Yakunlangan',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        isDraft
                                                            ? AppColors.warning
                                                            : AppColors.success,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${a.title} • ${a.category}',
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
                              ),
                              if (!isDraft)
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${a.totalScore.toStringAsFixed(1)} / ${a.maxScore.toStringAsFixed(0)} ball',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.successBg,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          a.trend,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${a.responses.where((r) => r.isEvaluated).length}/${a.responses.length} ta savol kiritilgan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Xulosa snippet
                          if (a.notes.isNotEmpty ||
                              (a.generalConclusion != null &&
                                  a.generalConclusion!.isNotEmpty))
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    (a.generalConclusion != null &&
                                            a.generalConclusion!.isNotEmpty)
                                        ? a.generalConclusion!
                                        : a.notes,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),

                          // Pastki qism: Sana va Amallar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Sana: ${df.format(a.assessmentDate)} • Mutaxassis: ${a.specialistName}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (isDraft)
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.warning,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        icon: const Icon(
                                          LucideIcons.play,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Davom ettirish',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        onPressed: () => _resumeDraft(a),
                                      )
                                    else ...[
                                      if (childAssessments.length > 1)
                                        IconButton(
                                          icon: Icon(
                                            LucideIcons.arrowLeftRight,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          tooltip: 'Taqqoslash',
                                          onPressed: () {
                                            AssessmentCompareDialog.show(
                                              context,
                                              currentAssessment: a,
                                              studentAssessments:
                                                  childAssessments,
                                            );
                                          },
                                        ),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        icon: const Icon(
                                          LucideIcons.eye,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Natijalarni ko‘rish',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        onPressed:
                                            () => AssessmentResultScreen.show(
                                              context,
                                              a,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'O‘chirish',
                                      onPressed:
                                          () => _confirmDeleteAssessment(a),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
