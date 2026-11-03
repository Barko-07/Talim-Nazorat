import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/assessment_model.dart';
import '../../../models/assessment_question_model.dart';
import '../../../models/assessment_response_model.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';
import 'conduct_assessment_screen.dart';

class CreateAssessmentFlow extends StatefulWidget {
  final StudentModel? initialStudent;

  const CreateAssessmentFlow({super.key, this.initialStudent});

  static Future<void> start(
    BuildContext context, {
    StudentModel? initialStudent,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAssessmentFlow(initialStudent: initialStudent),
      ),
    );
  }

  @override
  State<CreateAssessmentFlow> createState() => _CreateAssessmentFlowState();
}

class _CreateAssessmentFlowState extends State<CreateAssessmentFlow> {
  int _currentStep = 0;

  StudentModel? _selectedStudent;
  late TextEditingController _titleCtrl;
  String _selectedCategory = 'Aralash kompleks diagnostika';

  String _questionSearch = '';
  String? _questionDomainFilter;
  final List<AssessmentQuestionModel> _selectedQuestions = [];

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
    _selectedStudent = widget.initialStudent;
    _titleCtrl = TextEditingController(
      text:
          _selectedStudent != null
              ? '${_selectedStudent!.fullName} — Psixologik diagnostika'
              : 'Psixologik diagnostika va monitoring',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  bool _isRecommended(AssessmentQuestionModel q, StudentModel? student) {
    if (student == null) return false;
    final ageText = q.safeAgeRange.toLowerCase();
    final grade = student.grade.toLowerCase();
    if (ageText.contains(grade)) return true;
    if (grade.contains('1') ||
        grade.contains('2') ||
        grade.contains('3') ||
        grade.contains('4')) {
      if (ageText.contains('1-4') || ageText.contains('boshlang‘ich'))
        return true;
    }
    return false;
  }

  void _toggleQuestion(AssessmentQuestionModel q) {
    setState(() {
      final idx = _selectedQuestions.indexWhere((x) => x.id == q.id);
      if (idx >= 0) {
        _selectedQuestions.removeAt(idx);
      } else {
        _selectedQuestions.add(q);
      }
    });
  }

  void _reorderQuestion(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _selectedQuestions.removeAt(oldIndex);
      _selectedQuestions.insert(newIndex, item);
    });
  }

  Future<void> _saveAsDraft() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Iltimos, avval baholash o‘tkaziladigan bolani tanlang.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    final user = auth.currentUser;

    final responses =
        _selectedQuestions.map((q) {
          return AssessmentResponseModel(
            questionId: q.id,
            questionTitle: q.title,
            questionText: q.questionText,
            domain: q.domain,
            questionType: q.questionType,
            maxScore: q.maxScore,
            scoringSchema: q.scoringSchema,
            isEvaluated: false,
          );
        }).toList();

    final draft = AssessmentModel(
      id: 'ass_psy_${const Uuid().v4().substring(0, 8)}',
      studentId: _selectedStudent!.id,
      studentName: _selectedStudent!.fullName,
      specialistId: user?.id ?? 'user_psychologist',
      specialistName: user?.fullName ?? 'Amaliyotchi psixolog',
      specialistRole: 'Amaliyotchi psixolog',
      assessmentDate: DateTime.now(),
      type: 'Psixologik diagnostika (Kutubxona asosida)',
      category: _selectedCategory,
      title:
          _titleCtrl.text.trim().isNotEmpty
              ? _titleCtrl.text.trim()
              : 'Psixologik baholash',
      notes: '',
      recommendations: '',
      totalScore: 0.0,
      maxScore: _selectedQuestions.fold(0.0, (sum, q) => sum + q.maxScore),
      previousScore: null,
      reviewDate: DateTime.now().add(const Duration(days: 60)),
      questionIds: _selectedQuestions.map((q) => q.id).toList(),
      responses: responses,
      status: 'draft',
      createdAt: DateTime.now(),
    );

    await app.addAssessment(draft, byUser: user);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedStudent!.fullName} uchun baholash qoralama sifatida saqlandi!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _startAssessment() {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Iltimos, avval baholash o‘tkaziladigan bolani tanlang.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iltimos, kutubxonadan kamida 1 ta savol tanlang.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final responses =
        _selectedQuestions.map((q) {
          return AssessmentResponseModel(
            questionId: q.id,
            questionTitle: q.title,
            questionText: q.questionText,
            domain: q.domain,
            questionType: q.questionType,
            maxScore: q.maxScore,
            scoringSchema: q.scoringSchema,
            isEvaluated: false,
          );
        }).toList();

    final assessment = AssessmentModel(
      id: 'ass_psy_${const Uuid().v4().substring(0, 8)}',
      studentId: _selectedStudent!.id,
      studentName: _selectedStudent!.fullName,
      specialistId: user?.id ?? 'user_psychologist',
      specialistName: user?.fullName ?? 'Amaliyotchi psixolog',
      specialistRole: 'Amaliyotchi psixolog',
      assessmentDate: DateTime.now(),
      type: 'Psixologik diagnostika (Kutubxona asosida)',
      category: _selectedCategory,
      title:
          _titleCtrl.text.trim().isNotEmpty
              ? _titleCtrl.text.trim()
              : 'Psixologik baholash',
      notes: '',
      recommendations: '',
      totalScore: 0.0,
      maxScore: _selectedQuestions.fold(0.0, (sum, q) => sum + q.maxScore),
      previousScore: null,
      reviewDate: DateTime.now().add(const Duration(days: 60)),
      questionIds: _selectedQuestions.map((q) => q.id).toList(),
      responses: responses,
      status: 'draft',
      createdAt: DateTime.now(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => ConductAssessmentScreen(
              assessment: assessment,
              selectedQuestions: _selectedQuestions,
              isNew: true,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final students = app.students;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi Baholash Yaratish'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
        actions: [
          if (_currentStep == 2 && _selectedQuestions.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.bookmark_outline_rounded, size: 18),
              label: const Text('Qoralama saqlash'),
              onPressed: _saveAsDraft,
            ),
        ],
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepTapped: (step) {
          if (step == 1 && _selectedStudent == null) return;
          if (step == 2 && _selectedQuestions.isEmpty && _currentStep < 2)
            return;
          setState(() => _currentStep = step);
        },
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_selectedStudent == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Iltimos, baholash o‘tkaziladigan bolani tanlang.',
                  ),
                  backgroundColor: AppColors.warning,
                ),
              );
              return;
            }
            if (_titleCtrl.text.trim().isEmpty) {
              _titleCtrl.text =
                  '${_selectedStudent!.fullName} — Psixologik diagnostika';
            }
            setState(() => _currentStep = 1);
          } else if (_currentStep == 1) {
            if (_selectedQuestions.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Iltimos, kutubxonadan kamida 1 ta savol tanlang.',
                  ),
                  backgroundColor: AppColors.warning,
                ),
              );
              return;
            }
            setState(() => _currentStep = 2);
          } else if (_currentStep == 2) {
            _startAssessment();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (ctx, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Ortga'),
                    onPressed: details.onStepCancel,
                  ),
                const Spacer(),
                if (_currentStep == 1 && _selectedQuestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      onPressed: _saveAsDraft,
                      child: const Text('Qoralama saqlash'),
                    ),
                  ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0062CC),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: Icon(
                    _currentStep == 2
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _currentStep == 2 ? 'Baholashni boshlash' : 'Keyingisi',
                  ),
                  onPressed: details.onStepContinue,
                ),
              ],
            ),
          );
        },
        steps: [
          // 1-bosqich: Bola va Mavzu
          Step(
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            title: const Text('Bola & Mavzu'),
            content: _buildStep1Student(students),
          ),
          // 2-bosqich: Savollarni tanlash
          Step(
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            title: const Text('Savollar kutubxonasi'),
            content: _buildStep2QuestionSelection(app.questions),
          ),
          // 3-bosqich: Tekshirish va tartiblash
          Step(
            isActive: _currentStep >= 2,
            state: StepState.indexed,
            title: const Text('Tekshirish & Boshlash'),
            content: _buildStep3ReorderAndReview(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Student(List<StudentModel> students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1-bosqich: Baholash o‘tkaziladigan o‘quvchi va umumiy ma’lumotlar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bolani tanlang va ushbu diagnostika seansiga mos sarlavhani belgilang',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),

        // Bola tanlash
        DropdownButtonFormField<StudentModel>(
          value:
              _selectedStudent != null &&
                      students.any((s) => s.id == _selectedStudent!.id)
                  ? _selectedStudent
                  : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'O‘quvchini tanlang *',
            prefixIcon: Icon(Icons.person_search_rounded),
          ),
          items:
              students.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(
                    '${s.fullName} (${s.grade} • ${s.primaryNeed})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedStudent = v;
              if (v != null) {
                _titleCtrl.text = '${v.fullName} — Psixologik diagnostika';
              }
            });
          },
        ),
        const SizedBox(height: 14),

        // Tanlangan bola haqida tezkor karta
        if (_selectedStudent != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF0062CC).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0062CC),
                  child: Text(
                    _selectedStudent!.firstName.isNotEmpty
                        ? _selectedStudent!.firstName[0]
                        : 'B',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedStudent!.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_selectedStudent!.grade} sinf • ${_selectedStudent!.age} yosh • Ehtiyoj: ${_selectedStudent!.primaryNeed}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Muassasa: ${_selectedStudent!.institutionName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Yo'nalish
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Diagnostika yo‘nalishi *',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items:
              _categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedCategory = v);
          },
        ),
        const SizedBox(height: 14),

        // Sarlavha
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Baholash sarlavhasi / Mavzusi *',
            hintText: 'Masalan: 1-chorak kognitiv diagnostikasi',
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2QuestionSelection(
    List<AssessmentQuestionModel> allQuestions,
  ) {
    final filtered =
        allQuestions.where((q) {
          if (_questionSearch.isNotEmpty) {
            final qry = _questionSearch.toLowerCase();
            final matchTitle = (q.title ?? '').toLowerCase().contains(qry);
            final matchText = q.questionText.toLowerCase().contains(qry);
            if (!matchTitle && !matchText) return false;
          }
          if (_questionDomainFilter != null &&
              q.domain != _questionDomainFilter) {
            return false;
          }
          return true;
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2-bosqich: Savollar kutubxonasidan savollarni tanlang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tanlandi: ${_selectedQuestions.length} ta savol',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0062CC),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_selectedStudent != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF9EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Color(0xFF12803A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedStudent!.grade} uchun tavsiya etilganlar belgilandi',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF12803A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Qidiruv va filtr
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                onChanged: (v) => setState(() => _questionSearch = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Savol matni yoki mavzusi bo‘yicha qidiruv...',
                  prefixIcon: const Icon(Icons.search, size: 18),
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
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String?>(
                value: _questionDomainFilter,
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
                  ...allQuestions
                      .map((q) => q.domain)
                      .toSet()
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                ],
                onChanged: (v) => setState(() => _questionDomainFilter = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Savollar ro'yxati
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final q = filtered[i];
              final isSelected = _selectedQuestions.any((x) => x.id == q.id);
              final isRec = _isRecommended(q, _selectedStudent);

              return Card(
                elevation: 0,
                color: isSelected ? const Color(0xFFEAF3FD) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color:
                        isSelected ? const Color(0xFF0062CC) : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => _toggleQuestion(q),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: const Color(0xFF0062CC),
                          onChanged: (_) => _toggleQuestion(q),
                        ),
                        const SizedBox(width: 6),
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color:
                                            isSelected
                                                ? const Color(0xFF0062CC)
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isRec)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF9EC),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Tavsiya',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF12803A),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                q.questionText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    q.domain,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${q.safeAgeRange}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    q.questionType == 'open_text'
                                        ? 'Sifat tahlili'
                                        : 'Maks: ${q.maxScore.toStringAsFixed(0)} b',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0062CC),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep3ReorderAndReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3-bosqich: Tanlangan savollarni tekshirish va tartibini belgilash',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Savollar ketma-ketligini o‘zgartirishingiz yoki ortiqcha savollarni ro‘yxatdan chiqarishingiz mumkin',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),

        // Sarlavha xulosa kartasi
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                'O‘quvchi',
                _selectedStudent?.fullName ?? '-',
                Icons.person_outline,
              ),
              _buildMetricItem(
                'Savollar soni',
                '${_selectedQuestions.length} ta',
                Icons.quiz_outlined,
              ),
              _buildMetricItem(
                'Umumiy maksimal ball',
                '${_selectedQuestions.fold(0.0, (s, q) => s + q.maxScore).toStringAsFixed(0)} ball',
                Icons.star_outline_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Savollar ketma-ketligi (Tartibni almashtirish uchun suring):',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            itemCount: _selectedQuestions.length,
            onReorder: _reorderQuestion,
            itemBuilder: (ctx, i) {
              final q = _selectedQuestions[i];
              return Card(
                key: ValueKey(q.id),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0062CC),
                      ),
                    ),
                  ),
                  title: Text(
                    q.questionTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${q.domain} • ${q.questionType == 'open_text' ? "Sifatli javob" : "${q.maxScore.toStringAsFixed(0)} ball"}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _selectedQuestions.removeAt(i));
                        },
                        tooltip: 'Chiqarib tashlash',
                      ),
                      const Icon(Icons.drag_handle_rounded, color: Colors.grey),
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

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0062CC)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
