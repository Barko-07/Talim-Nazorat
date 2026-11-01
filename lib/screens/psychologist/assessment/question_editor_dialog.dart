import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/assessment_question_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';

class QuestionEditorDialog extends StatefulWidget {
  final AssessmentQuestionModel? existingQuestion;

  const QuestionEditorDialog({super.key, this.existingQuestion});

  static Future<AssessmentQuestionModel?> show(
    BuildContext context, {
    AssessmentQuestionModel? existingQuestion,
  }) {
    return showDialog<AssessmentQuestionModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuestionEditorDialog(existingQuestion: existingQuestion),
    );
  }

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _textCtrl;
  late TextEditingController _criteriaCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _ageCtrl;

  late String _selectedDomain;
  late String _selectedType;
  late String _selectedStatus;
  late List<_OptionDraft> _options;

  static const List<String> _domains = [
    'Kognitiv va intellektual rivojlanish',
    'Ixtiyoriy diqqat va aqliy ishchanlik',
    'Emotsional-irodaviy holat va xavotir',
    'Ijtimoiy moslashuv va motivatsiya',
    'Nutq va muloqot rivojlanishi',
  ];

  static const Map<String, String> _typeNames = {
    'yes_no': 'Ha / Yo‘q (2 variantli)',
    'single_choice': 'Bir variantni tanlash (Yagona javob)',
    'multiple_choice': 'Bir nechta variantni tanlash',
    'scale_1_5': '1–5 balli shkala (Mezonli baholash)',
    'open_text': 'Erkin javob / Kuzatuv qaydi (Sifat tahlili)',
  };

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuestion;

    _titleCtrl = TextEditingController(text: q?.title ?? '');
    _textCtrl = TextEditingController(text: q?.questionText ?? '');
    _criteriaCtrl = TextEditingController(text: q?.scoringCriteria ?? '');
    _notesCtrl = TextEditingController(text: q?.psychologistNotes ?? '');
    _ageCtrl = TextEditingController(
      text: q?.targetAgeRange ?? '1-4 sinf (7-10 yosh)',
    );

    _selectedDomain = q?.domain ?? _domains.first;
    _selectedType = q?.questionType ?? 'scale_1_5';
    _selectedStatus = q?.status ?? 'ready';

    if (q != null && q.options.isNotEmpty) {
      _options = q.options
          .map((o) => _OptionDraft(text: o.text, score: o.score))
          .toList();
    } else {
      _options = _defaultOptionsForType(_selectedType);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    _criteriaCtrl.dispose();
    _notesCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  List<_OptionDraft> _defaultOptionsForType(String type) {
    if (type == 'yes_no') {
      return [
        _OptionDraft(text: 'Ha (To‘liq namoyon bo‘ladi)', score: 5.0),
        _OptionDraft(text: 'Yo‘q (Kuzatilmadi)', score: 0.0),
      ];
    } else if (type == 'single_choice' || type == 'multiple_choice') {
      return [
        _OptionDraft(text: 'Mustaqil va aniq bajaradi', score: 5.0),
        _OptionDraft(text: 'Kichik yordam bilan uddalaydi', score: 3.0),
        _OptionDraft(text: 'Qiyinchilikka uchraydi yoki bajara olmaydi', score: 1.0),
      ];
    } else if (type == 'scale_1_5') {
      return [
        _OptionDraft(text: '1 — Juda past / deyarli kuzatilmadi', score: 1.0),
        _OptionDraft(text: '2 — Qoniqarsiz / doimiy yordam kerak', score: 2.0),
        _OptionDraft(text: '3 — O‘rta / qisman mustaqil', score: 3.0),
        _OptionDraft(text: '4 — Yaxshi / kam xatolik', score: 4.0),
        _OptionDraft(text: '5 — A’lo / to‘liq mustaqil va erkin', score: 5.0),
      ];
    }
    return [];
  }

  void _onTypeChanged(String? newType) {
    if (newType == null || newType == _selectedType) return;
    setState(() {
      _selectedType = newType;
      _options = _defaultOptionsForType(newType);
    });
  }

  void _addOption() {
    setState(() {
      _options.add(
        _OptionDraft(
          text: 'Yangi javob varianti ${_options.length + 1}',
          score: 1.0,
        ),
      );
    });
  }

  void _removeOption(int index) {
    if (_options.length <= 1) return;
    setState(() {
      _options.removeAt(index);
    });
  }

  double _calculateMaxScore() {
    if (_selectedType == 'open_text') return 0.0;
    if (_selectedType == 'scale_1_5') return 5.0;
    if (_selectedType == 'multiple_choice') {
      double sum = 0.0;
      for (final opt in _options) {
        if (opt.score > 0) sum += opt.score;
      }
      return sum > 0 ? sum : 5.0;
    }
    if (_options.isEmpty) return 5.0;
    double max = 0.0;
    for (final opt in _options) {
      if (opt.score > max) max = opt.score;
    }
    return max > 0 ? max : 5.0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    final currentUser = auth.currentUser;

    final isNew = widget.existingQuestion == null;
    final now = DateTime.now();

    final maxScore = _calculateMaxScore();
    final minScore = _selectedType == 'open_text' ? 0.0 : 0.0;

    final parsedOptions = _options.map((o) {
      return AssessmentQuestionOption(
        id: 'opt_${const Uuid().v4().substring(0, 6)}',
        text: o.text.trim(),
        score: o.score,
      );
    }).toList();

    final question = AssessmentQuestionModel(
      id: widget.existingQuestion?.id ??
          'q_custom_${const Uuid().v4().substring(0, 8)}',
      title: _titleCtrl.text.trim().isEmpty
          ? _textCtrl.text.trim()
          : _titleCtrl.text.trim(),
      text: _textCtrl.text.trim(),
      domain: _selectedDomain,
      targetAgeRange: _ageCtrl.text.trim(),
      questionType: _selectedType,
      options: parsedOptions,
      scoringCriteria: _criteriaCtrl.text.trim(),
      psychologistNotes: _notesCtrl.text.trim(),
      authorId: widget.existingQuestion?.authorId ??
          currentUser?.id ??
          'user_psychologist',
      authorName: widget.existingQuestion?.authorName ??
          currentUser?.fullName ??
          'Amaliyotchi psixolog',
      isStandard: widget.existingQuestion?.isStandard ?? false,
      status: _selectedStatus,
      createdAt: widget.existingQuestion?.createdAt ?? now,
      updatedAt: now,
    );

    if (isNew) {
      await app.addQuestion(question);
    } else {
      await app.updateQuestion(question);
    }

    if (mounted) {
      Navigator.pop(context, question);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existingQuestion == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sarlavha
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNew
                                ? 'Yangi Psixologik Savol Yaratish'
                                : 'Savolni Tahrirlash',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isNew
                                ? 'Kutubxonaga yangi diagnostika savoli qo‘shish'
                                : 'Savol matni va baholash mezonlarini yangilash',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Yopish',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Form qismi (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Savol nomi (ixtiyoriy)
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Savol nomi / Mavzusi (ixtiyoriy)',
                            hintText: 'Masalan: Serial mantiqiy qatorlar tahlili',
                            prefixIcon: Icon(Icons.label_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Savol matni (majburiy)
                        TextFormField(
                          controller: _textCtrl,
                          maxLines: 3,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Iltimos, savol yoki topshiriq matnini kiriting'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Savol yoki topshiriq matni *',
                            hintText:
                                'Bola oldiga qo‘yiladigan vazifa, suhbat savoli yoki kuzatuv talabi...',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.edit_note_rounded, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Yo'nalish va Yosh/sinf oralig'i (2 ustun)
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _selectedDomain,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Baholash yo‘nalishi *',
                                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                                ),
                                items: _domains
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(
                                          d,
                                          style: const TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedDomain = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _ageCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Yosh / Sinf oralig‘i',
                                  hintText: 'Masalan: 1-4 sinf',
                                  prefixIcon: Icon(Icons.school_outlined, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Savol turi va Holati
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _selectedType,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Savol turi *',
                                  prefixIcon: Icon(Icons.tune_rounded, size: 20),
                                ),
                                items: _typeNames.entries
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(
                                          e.value,
                                          style: const TextStyle(fontSize: 12.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _onTypeChanged,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Holati',
                                  prefixIcon: Icon(Icons.flag_outlined, size: 20),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ready',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 16,
                                          color: Color(0xFF059669),
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Tayyor',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'draft',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.pending_outlined,
                                          size: 16,
                                          color: Color(0xFFD97706),
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Qoralama',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedStatus = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Dinamik javob variantlari bo'limi
                        _buildDynamicOptionsSection(),

                        const SizedBox(height: 18),

                        // Baholash mezonlari
                        TextFormField(
                          controller: _criteriaCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Baholash mezonlari va qoidalari',
                            hintText:
                                'Natijani qanday talqin qilish kerak (masalan: 3-5 ball me’yor, 1-2 ball korreksiya talab qiladi)...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 24),
                              child: Icon(Icons.rule_folder_outlined, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Psixolog uchun qo'shimcha ko'rsatma / izoh
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Psixolog uchun metodik ko‘rsatma / izoh',
                            hintText:
                                'Tekshiruv vaqtida bolaning qanday reaksiyalariga e’tibor qaratish kerak...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 24),
                              child: Icon(Icons.tips_and_updates_outlined, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Tugmalar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Bekor qilish'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: Text(isNew ? 'Savolni saqlash' : 'O‘zgarishlarni saqlash'),
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicOptionsSection() {
    if (_selectedType == 'open_text') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.notes_rounded, color: Color(0xFF64748B), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ushbu savol erkin matnli javob yoki psixologik kuzatuv qaydiga mo‘ljallangan. '
                'Baholash jarayonida psixolog matnli xulosa kiritadi (sonli ball hisoblanmaydi).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final isScale = _selectedType == 'scale_1_5';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isScale
                    ? '1–5 shkala mezonlari (Darajalar)'
                    : 'Javob variantlari va ballar (${_options.length} ta):',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!isScale && _selectedType != 'yes_no')
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Variant qo‘shish', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ..._options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      initialValue: opt.text,
                      onChanged: (v) => opt.text = v,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Variant matni...',
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
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      initialValue: opt.score.toStringAsFixed(
                        opt.score.truncateToDouble() == opt.score ? 0 : 1,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final val = double.tryParse(v);
                        if (val != null) opt.score = val;
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Ball',
                        suffixText: 'b',
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
                  if (!isScale && _selectedType != 'yes_no' && _options.length > 2)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _removeOption(idx),
                      tooltip: 'Variantni o‘chirish',
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OptionDraft {
  String text;
  double score;

  _OptionDraft({required this.text, required this.score});
}
