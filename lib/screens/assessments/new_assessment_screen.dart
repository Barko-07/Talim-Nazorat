import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
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
          _notesCtrl.text =
              'Nutq apparati harakatchanligi va tovushlar talaffuzida ijobiy dinamika kuzatildi.';
          _recommendationsCtrl.text =
              'Artikulyatsion gimnastika mashg‘ulotlarini haftasiga 3 marta davom ettirish.';
          break;
        case UserRole.psychologist:
          _titleCtrl.text = 'Kognitiv jarayonlar va hissiy barqarorlik tahlili';
          _notesCtrl.text =
              'Diqqatni jamlash ko‘rsatkichi va topshiriqqa bo‘lgan qiziqish barqarorlashmoqda.';
          _recommendationsCtrl.text =
              'Sensor xonada relaksatsion va rivojlantiruvchi o‘yinlarni tavsiya etish.';
          break;
        case UserRole.specialEducation:
          _titleCtrl.text = 'Sensor integratsiya va motorika diagnostikasi';
          _notesCtrl.text =
              'Mayda motorika va barmoqlar harakat koordinatsiyasida sezilarli ilgarilash bor.';
          _recommendationsCtrl.text =
              'Grafomotor mashqlar va montessori vositalari bilan ishlashni kuchaytirish.';
          break;
        case UserRole.teacher:
          _titleCtrl.text =
              'Dars mashg‘ulotlari va o‘quv motivatsiyasi kuzatuvi';
          _notesCtrl.text =
              'Sinf faoliyatida o‘qituvchi ko‘rsatmalarini to‘g‘ri qabul qilib, vazifani mustaqil bajarmoqda.';
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
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Baholash Huquqi Cheklangan')),
        body: AmbientMeshBackground(
          child: Center(
            child: ResponsivePageContainer(
              maxWidth: 520,
              child: SurfaceCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.shieldAlert,
                        size: 36,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${role.label} hisobida baholash kiritish huquqi yo‘q',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kuzatuvchi va metodistlar tizimda faqat o‘qish va monitoring hisobotlarini tahlil qilish vakolatiga ega.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      icon: const Icon(LucideIcons.arrowLeft, size: 16),
                      onPressed: () => Navigator.pop(context),
                      label: const Text('Orqaga qaytish'),
                    ),
                  ],
                ),
              ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${role.label} Baholashi')),
      body: AmbientMeshBackground(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: ResponsivePageContainer(
              maxWidth: 820,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. MUTAXASSISLIKNING RASMIY KASBIY VAKOLAT BANNERI
                  GlassSurface(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 16,
                    borderColor: role.color.withValues(alpha: 0.25),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: role.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(role.icon, color: role.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  StatusPill(
                                    label: role.label,
                                    color: role.color,
                                    icon: LucideIcons.lock,
                                  ),
                                  Text(
                                    user?.fullName ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Ushbu baholash faqat sizning kasbiy sohangiz doirasida rasmiylashtiriladi.',
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
                  const SizedBox(height: 12),

                  // Tibbiy tashxis emasligi haqida rasmiy eslatma
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.info,
                          color: AppColors.info,
                          size: 17,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Eslatma: Ushbu baholash kasbiy pedagogik-psixologik kuzatuv hisoblanadi va tibbiy tashxis qo‘yish uchun asos bo‘lmaydi.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. O'QUVCHI VA MA'LUMOTLAR
                  SurfaceCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Baholanayotgan O‘quvchi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // O'quvchini tanlash (isExpanded: true — iPhone'da overflow bo'lmaydi)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStudentId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'O‘quvchini tanlang *',
                            prefixIcon: Icon(LucideIcons.userSearch, size: 18),
                          ),
                          items: students
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    '${s.fullName} (${s.grade} - ${s.primaryNeed})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
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

                        // Sohaviy Diagnostika Kategoriyasi
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Kasbiy diagnostika yo‘nalishi *',
                            prefixIcon: Icon(
                              role.icon,
                              size: 19,
                              color: role.color,
                            ),
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    overflow: TextOverflow.ellipsis,
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
                            prefixIcon: Icon(
                              LucideIcons.clipboardList,
                              size: 18,
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nomini kiriting'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. SOHAGA MOS RUBRIKA MEZONLARI
                  SurfaceCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  LucideIcons.slidersHorizontal,
                                  size: 18,
                                  color: role.color,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Kasbiy Rubrika Mezonlari',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: role.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: role.color.withValues(alpha: 0.24),
                                ),
                              ),
                              child: Text(
                                'Jami: ${_totalScore.toInt()} / ${_maxTotalScore.toInt()} ball',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: role.color,
                                  fontSize: 12.5,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairlineBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${index + 1}. $name',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: role.color.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '${score.toInt()} / ${max.toInt()} ball',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                          color: role.color,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 5,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7.5,
                                    ),
                                  ),
                                  child: Slider(
                                    value: score,
                                    min: 0,
                                    max: max,
                                    divisions: max.toInt(),
                                    activeColor: role.color,
                                    inactiveColor: role.color.withValues(
                                      alpha: 0.16,
                                    ),
                                    label: '${score.toInt()}',
                                    onChanged: (v) {
                                      setState(() {
                                        item['score'] = v;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. MUTAXASSIS XULOSASI VA TAVSIYALARI
                  SurfaceCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mutaxassis Xulosasi va Pedagogik Tavsiyalar',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText:
                                'Diagnostik pedagogik-psixologik xulosa *',
                            hintText:
                                'Bola erishgan natijalar, dinamika va xususiyatlar...',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
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
                            hintText:
                                'Uyda va darslarda qo‘llanilishi lozim bo‘lgan uslublar...',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Tavsiyalarni kiriting'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // SAQLASH TUGMASI
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: role.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(LucideIcons.circleCheck, size: 18),
                    label: Text(
                      '${role.label} Baholashini Saqlash',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: _saveAssessment,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
