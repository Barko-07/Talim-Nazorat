import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/assessment_question_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import 'question_editor_dialog.dart';

class QuestionLibraryView extends StatefulWidget {
  final bool isEmbedded;
  final Function(AssessmentQuestionModel)? onSelectQuestion;

  const QuestionLibraryView({
    super.key,
    this.isEmbedded = false,
    this.onSelectQuestion,
  });

  @override
  State<QuestionLibraryView> createState() => _QuestionLibraryViewState();
}

class _QuestionLibraryViewState extends State<QuestionLibraryView> {
  int _activeTabIndex = 0; // 0: Barcha savollar, 1: Mening savollarim
  String _search = '';
  String? _selectedDomain;
  String? _selectedType;
  String? _selectedStatus;

  static const List<String> _domains = [
    'Kognitiv va intellektual rivojlanish',
    'Ixtiyoriy diqqat va aqliy ishchanlik',
    'Emotsional-irodaviy holat va xavotir',
    'Ijtimoiy moslashuv va motivatsiya',
    'Nutq va muloqot rivojlanishi',
  ];

  static const Map<String, String> _typeNames = {
    'scale_1_5': '1–5 shkala',
    'single_choice': 'Bir variant',
    'multiple_choice': 'Bir nechta variant',
    'yes_no': 'Ha / Yo‘q',
    'open_text': 'Erkin javob',
  };

  void _openQuestionEditor([AssessmentQuestionModel? question]) async {
    final result = await QuestionEditorDialog.show(
      context,
      existingQuestion: question,
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            question == null
                ? 'Yangi savol kutubxonaga muvaffaqiyatli saqlandi!'
                : 'Savol o‘zgarishlari saqlandi!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _confirmDeleteQuestion(AssessmentQuestionModel q) {
    if (q.isStandard) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Standart bazaviy metodika savolini o‘chirib bo‘lmaydi. Faqat o‘zingiz yaratgan savollarni o‘chirishingiz mumkin.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(LucideIcons.triangleAlert, color: Colors.red),
                SizedBox(width: 8),
                Text('Savolni o‘chirish'),
              ],
            ),
            content: Text(
              'Haqiqatan ham "${q.title}" savolini o‘chirmoqchimisiz? Bu amalni ortga qaytarib bo‘lmaydi.',
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
                  await context.read<AppProvider>().deleteQuestion(q.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${q.title}" savoli o‘chirildi.'),
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

  void _showQuestionDetails(AssessmentQuestionModel q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.fileQuestion,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.questionTitle,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${q.domain} • ${q.safeAgeRange}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(q.status),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Savol / Topshiriq matni:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            q.questionText,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (q.options.isNotEmpty) ...[
                            Text(
                              'Javob variantlari va shkala (${_typeNames[q.questionType] ?? q.questionType}):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...q.options.map((opt) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.circleCheck,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        opt.text,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${opt.score.toStringAsFixed(opt.score.truncateToDouble() == opt.score ? 0 : 1)} ball',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 14),
                          ],
                          if (q.safeCriteria.isNotEmpty) ...[
                            Text(
                              'Baholash mezonlari:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              q.safeCriteria,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (q.safeNotes.isNotEmpty) ...[
                            Text(
                              'Psixolog uchun metodik ko‘rsatma:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warningBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                q.safeNotes,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Row(
                            children: [
                              Icon(
                                q.isStandard
                                    ? LucideIcons.shieldCheck
                                    : LucideIcons.user,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                q.isStandard
                                    ? 'Standart metodika bazasi'
                                    : 'Muallif: ${q.authorName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(LucideIcons.edit, size: 16),
                        label: const Text('Tahrirlash'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openQuestionEditor(q);
                        },
                      ),
                      if (widget.onSelectQuestion != null) ...[
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          icon: const Icon(LucideIcons.listPlus, size: 16),
                          label: const Text('Baholashga qo‘shish'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onSelectQuestion!(q);
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isReady = status == 'ready';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isReady ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isReady
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? LucideIcons.circleCheck : LucideIcons.hourglass,
            size: 12,
            color: isReady ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isReady ? 'Tayyor' : 'Qoralama',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isReady ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.currentUser?.id ?? 'user_psychologist';

    // Ro'yxatni olish
    final allQuestions =
        _activeTabIndex == 0
            ? app.questions
            : app.questions.where((q) => q.authorId == currentUserId).toList();

    // Filtrlash
    final filtered =
        allQuestions.where((q) {
          if (_search.isNotEmpty) {
            final qry = _search.toLowerCase();
            final matchTitle = (q.title ?? '').toLowerCase().contains(qry);
            final matchText = q.questionText.toLowerCase().contains(qry);
            final matchCrit = (q.scoringCriteria ?? '').toLowerCase().contains(
              qry,
            );
            if (!matchTitle && !matchText && !matchCrit) return false;
          }
          if (_selectedDomain != null && q.domain != _selectedDomain) {
            return false;
          }
          if (_selectedType != null && q.questionType != _selectedType) {
            return false;
          }
          if (_selectedStatus != null && q.status != _selectedStatus) {
            return false;
          }
          return true;
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sarlavha paneli
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Savollar Kutubxonasi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${filtered.length} ta savol',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Psixologik diagnostika metodikalari va test topshiriqlari banki',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('+ Yangi savol'),
              onPressed: () => _openQuestionEditor(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tablar: Barcha savollar vs Mening savollarim
        Row(
          children: [
            ChoiceChip(
              label: Text('Barcha savollar (${app.questions.length})'),
              selected: _activeTabIndex == 0,
              onSelected: (s) {
                if (s) setState(() => _activeTabIndex = 0);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(
                'Mening savollarim (${app.questions.where((q) => q.authorId == currentUserId).length})',
              ),
              selected: _activeTabIndex == 1,
              onSelected: (s) {
                if (s) setState(() => _activeTabIndex = 1);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filtrlar qatori
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Qidiruv
                SizedBox(
                  width: 240,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Savol matni yoki mavzusi...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Yo'nalish
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String?>(
                    value: _selectedDomain,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Yo‘nalish',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
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
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      ..._domains.map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedDomain = v),
                  ),
                ),
                // Savol turi
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String?>(
                    value: _selectedType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Savol turi',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text(
                          'Barcha turlar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      ..._typeNames.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
                ),
                // Holati
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Holat',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Barchasi', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'ready',
                        child: Text('Tayyor', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'draft',
                        child: Text('Qoralama', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedStatus = v),
                  ),
                ),
                if (_search.isNotEmpty ||
                    _selectedDomain != null ||
                    _selectedType != null ||
                    _selectedStatus != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _search = '';
                        _selectedDomain = null;
                        _selectedType = null;
                        _selectedStatus = null;
                      });
                    },
                    icon: const Icon(LucideIcons.listX, size: 16),
                    label: const Text(
                      'Tozalash',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Savollar ro'yxati
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  LucideIcons.fileQuestion,
                  size: 44,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mos keluvchi savollar topilmadi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qidiruv yoki filtr parametrlarini o‘zgartirib ko‘ring yoki yangi savol qo‘shing',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Yangi savol yaratish'),
                  onPressed: () => _openQuestionEditor(),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final q = filtered[i];
              return _buildQuestionCard(q);
            },
          ),
      ],
    );
  }

  Widget _buildQuestionCard(AssessmentQuestionModel q) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _showQuestionDetails(q),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.circleHelp,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                q.questionTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _buildStatusBadge(q.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q.questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildTag(
                    LucideIcons.shapes,
                    q.domain,
                    AppColors.primary,
                    AppColors.primaryLight,
                  ),
                  _buildTag(
                    LucideIcons.slidersHorizontal,
                    _typeNames[q.questionType] ?? q.questionType,
                    AppColors.info,
                    AppColors.infoBg,
                  ),
                  _buildTag(
                    LucideIcons.school,
                    q.safeAgeRange,
                    AppColors.textSecondary,
                    AppColors.surfaceMuted,
                  ),
                  if (q.questionType != 'open_text')
                    _buildTag(
                      LucideIcons.star,
                      'Maks: ${q.maxScore.toStringAsFixed(0)} ball',
                      AppColors.success,
                      AppColors.successBg,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    q.isStandard
                        ? 'Standart metodika'
                        : 'Muallif: ${q.authorName}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.eye, size: 18),
                        tooltip: 'Ko‘rish',
                        onPressed: () => _showQuestionDetails(q),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.edit, size: 18),
                        tooltip: 'Tahrirlash',
                        onPressed: () => _openQuestionEditor(q),
                      ),
                      if (!q.isStandard)
                        IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: Colors.red,
                          ),
                          tooltip: 'O‘chirish',
                          onPressed: () => _confirmDeleteQuestion(q),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
