import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/assessment_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';

class NewAssessmentScreen extends StatefulWidget {
  final String? initialStudentId;

  const NewAssessmentScreen({super.key, this.initialStudentId});

  @override
  State<NewAssessmentScreen> createState() => _NewAssessmentScreenState();
}

class _NewAssessmentScreenState extends State<NewAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStudentId;
  String _category = '';
  final String _type = 'Standart balli (Rubrika)';

  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();

  // Dinamik kasbiy mezonlar va ularning ballari
  late List<Map<String, dynamic>> _criteriaList;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      final role = user?.role ?? UserRole.psychologist;

      final categories = role.assessmentCategories;
      if (categories.isNotEmpty) {
        _category = categories.first;
      } else {
        _category = 'Umumiy pedagogik kuzatuv';
      }

      // Kasbga mos sarlavha va shablon
      switch (role) {
        case UserRole.speechTherapist:
          _titleCtrl.text = 'Nutqiy rivojlanish va artikulyatsiya tekshiruvi';
          _notesCtrl.text = 'Nutq apparati harakatchanligi va tovushlar talaffuzida ijobiy dinamika kuzatildi.';
          _recommendationsCtrl.text = 'Artikulyatsion gimnastika mashg‘ulotlarini haftasiga 3 marta davom ettirish.';
          break;
        case UserRole.psychologist:
          _titleCtrl.text = 'Kognitiv jarayonlar va hissiy barqarorlik tahlili';
          _notesCtrl.text = 'Diqqatni jamlash ko‘rsatkichi va topshiriqqa bo‘lgan qiziqish barqarorlashmoqda.';
          _recommendationsCtrl.text = 'Sensor xonada relaksatsion va rivojlantiruvchi o‘yinlarni tavsiya etish.';
          break;
        case UserRole.specialEducation:
          _titleCtrl.text = 'Sensor integratsiya va motorika diagnostikasi';
          _notesCtrl.text = 'Mayda motorika va barmoqlar harakat koordinatsiyasida sezilarli ilgarilash bor.';
          _recommendationsCtrl.text = 'Grafomotor mashqlar va montessori vositalari bilan ishlashni kuchaytirish.';
          break;
        case UserRole.teacher:
          _titleCtrl.text =
              'Dars mashg‘ulotlari va o‘quv motivatsiyasi kuzatuvi';
          _notesCtrl.text = 'Sinf faoliyatida o‘qituvchi ko‘rsatmalarini to‘g‘ri qabul qilib, vazifani mustaqil bajarmoqda.';
          _recommendationsCtrl.text =
              'Sinfdoshlar bilan jamoaviy topshiriqlarda ko‘proq jalb qilish.';
          break;
        default:
          _titleCtrl.text = 'Oraliq pedagogik-psixologik monitoring';
          _notesCtrl.text = 'Rejali pedagogik-psixologik mezonlar tekshirildi.';
          _recommendationsCtrl.text =
              'Mashg‘ulotlarni belgilangan tartibda davom ettirish.';
          break;
      }

      // Mezonlarni klonlash (har biri uchun 'score' o'zgarishi mumkin)
      _criteriaList = role.defaultCriteria.map((c) {
        return {
          'name': c['name'] as String,
          'max': (c['max'] as num).toDouble(),
          'score': (c['default'] as num).toDouble(),
        };
      }).toList();

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _recommendationsCtrl.dispose();
    super.dispose();
  }

  double get _totalScore {
    return _criteriaList.fold(0.0, (sum, c) => sum + (c['score'] as double));
  }

  double get _maxTotalScore {
    return _criteriaList.fold(0.0, (sum, c) => sum + (c['max'] as double));
  }

  void _saveAssessment() async {
    if (_formKey.currentState!.validate()) {
      final app = context.read<AppProvider>();
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;

      if (_selectedStudentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iltimos, o‘quvchini tanlang!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final student = app.students.firstWhere(
        (s) => s.id == _selectedStudentId,
        orElse: () => app.students.first,
      );

      final total = _totalScore;
      final maxTotal = _maxTotalScore > 0 ? _maxTotalScore : 100.0;

      final results = _criteriaList.map((c) {
        return AssessmentCriterionResult(
          criterionName: c['name'] as String,
          score: c['score'] as double,
          maxScore: c['max'] as double,
        );
      }).toList();

      // Haqiqiy oldingi baholashni bazadan qidirish (soxta ball kiritmaslik)
      final pastAssessments = app.assessments
          .where(
            (a) =>
                a.studentId == student.id &&
                a.category == _category &&
                !a.isDraft,
          )
          .toList();
      double? realPreviousScore;
      if (pastAssessments.isNotEmpty) {
        pastAssessments.sort(
          (a, b) => b.assessmentDate.compareTo(a.assessmentDate),
        );
        realPreviousScore = pastAssessments.first.totalScore;
      }

      final assessment = AssessmentModel(
        id: 'ass_${const Uuid().v4().substring(0, 8)}',
        studentId: student.id,
        studentName: student.fullName,
        specialistId: user?.id ?? 'user_specialist',
        specialistName: user?.fullName ?? 'Mutaxassis',
        specialistRole: user?.role.label ?? 'Mutaxassis',
        assessmentDate: DateTime.now(),
        type: _type,
        category: _category,
        title: _titleCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isNotEmpty
            ? _notesCtrl.text.trim()
            : 'Rejali kasbiy diagnostika o‘tkazildi.',
        recommendations: _recommendationsCtrl.text.trim().isNotEmpty
            ? _recommendationsCtrl.text.trim()
            : 'Mashg‘ulotlarni belgilangan tartibda davom ettirish.',
        totalScore: total,
        maxScore: maxTotal,
        previousScore: realPreviousScore,
        criteria: results,
        followUpAction: _recommendationsCtrl.text.trim(),
        reviewDate: DateTime.now().add(const Duration(days: 30)),
      );

      await app.addAssessment(assessment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user?.role.label} xulosasi muvaffaqiyatli saqlandi!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final role = user?.role ?? UserRole.psychologist;
    final students = app.students;

    if (!role.canCreateAssessments) {
      return Scaffold(
        appBar: AppBar(title: const Text('Baholash Huquqi Cheklangan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.remove_circle_outline,
                  size: 64,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 16),
                Text(
                  '${role.label} hisobida baholash kiritish huquqi yo‘q',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kuzatuvchi va metodistlar tizimda faqat o‘qish va monitoring hisobotlarini tahlil qilish vakolatiga ega.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Orqaga qaytish'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _selectedStudentId ??= students.isNotEmpty ? students.first.id : null;

    final categories = role.assessmentCategories.isNotEmpty
        ? role.assessmentCategories
        : ['Umumiy pedagogik monitoring'];

    if (_category.isEmpty || !categories.contains(_category)) {
      _category = categories.first;
    }

    return Scaffold(
      appBar: AppBar(title: Text('${role.label} Baholashi')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. MUTAXASSISLIKNING RASMIY KASBIY VAKOLAT BANNERI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: role.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: role.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: role.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(role.icon, color: role.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                role.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: role.color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.lock_rounded,
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mutaxassis: ${user?.fullName ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Ushbu baholash faqat sizning kasbiy sohangiz doirasida rasmiylashtiriladi.',
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
              ),
              const SizedBox(height: 12),

              // Tibbiy tashxis emasligi haqida rasmiy eslatma
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Eslatma: Ushbu baholash kasbiy pedagogik-psixologik kuzatuv hisoblanadi va tibbiy tashxis qo‘yish uchun asos bo‘lmaydi.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. O'QUVCHI VA MA'LUMOTLAR
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Baholanayotgan O‘quvchi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // O'quvchini tanlash
                      DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        decoration: const InputDecoration(
                          labelText: 'O‘quvchini tanlang *',
                          prefixIcon: Icon(
                            Icons.person_search_rounded,
                            size: 20,
                          ),
                        ),
                        items: students
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  '${s.fullName} (${s.grade} - ${s.primaryNeed})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedStudentId = v),
                        validator: (v) =>
                            v == null ? 'O‘quvchini tanlang' : null,
                      ),
                      const SizedBox(height: 14),

                      // Sohaviy Diagnostika Kategoriyasi (Faqat shu mutaxassis vakolatiga tegishlilari)
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Kasbiy diagnostika yo‘nalishi *',
                          prefixIcon: Icon(
                            role.icon,
                            size: 20,
                            color: role.color,
                          ),
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                      const SizedBox(height: 14),

                      // Sarlavha
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Baholash mavzusi / Test nomi *',
                          prefixIcon: Icon(Icons.assignment_outlined, size: 20),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Nomini kiriting' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. SOHAGA MOS RUBRIKA MEZONLARI
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: role.color,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Kasbiy Rubrika Mezonlari',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: role.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Jami: ${_totalScore.toInt()} / ${_maxTotalScore.toInt()} ball',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: role.color,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Har bir mezon bo‘yicha bolaning haqiqiy o‘zlashtirish darajasini belgilang:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dinamik mezon slayderlari
                      ...List.generate(_criteriaList.length, (index) {
                        final item = _criteriaList[index];
                        final score = item['score'] as double;
                        final max = item['max'] as double;
                        final name = item['name'] as String;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${index + 1}. $name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: role.color.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '${score.toInt()} / ${max.toInt()} ball',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: role.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Slider(
                                value: score,
                                min: 0,
                                max: max,
                                divisions: max.toInt(),
                                activeColor: role.color,
                                label: '${score.toInt()}',
                                onChanged: (v) {
                                  setState(() {
                                    item['score'] = v;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. MUTAXASSIS XULOSASI VA TAVSIYALARI
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mutaxassis Xulosasi va Pedagogik Tavsiyalar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Diagnostik pedagogik-psixologik xulosa *',
                          hintText: 'Bola erishgan natijalar, dinamika va xususiyatlar...',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Xulosa matnini kiriting'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _recommendationsCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText:
                              'Ota-ona va fan o‘qituvchilariga tavsiyalar *',
                          hintText: 'Uyda va darslarda qo‘llanilishi lozim bo‘lgan uslublar...',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Tavsiyalarni kiriting'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // SAQLASH TUGMASI
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: role.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  '${role.label} Baholashini Saqlash',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _saveAssessment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
