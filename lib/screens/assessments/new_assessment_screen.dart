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
    final roleIcon = premiumRoleIcon(role);

    if (!role.canCreateAssessments) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Baholash Huquqi Cheklangan')),
        body: AmbientMeshBackground(
          child: Center(
            child: ResponsivePageContainer(
              maxWidth: 520,
              child: SurfaceCard(
                borderRadius: 28,
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.shieldAlert,
                      size: 40,
                      color: AppColors.warning,
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
              maxWidth: 840,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. MUTAXASSISLIKNING RASMIY KASBIY VAKOLAT BANNERI
                  GlassSurface(
                    padding: const EdgeInsets.all(22),
                    borderRadius: 26,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            roleIcon,
                            color: role.color,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
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
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'Ushbu baholash faqat sizning kasbiy sohangiz doirasida rasmiylashtiriladi.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tibbiy tashxis emasligi haqida rasmiy eslatma
                  GlassWell(
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    tintColor: AppColors.infoBg,
                    borderColor: Colors.white,
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            LucideIcons.info,
                            color: AppColors.info,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Eslatma: Ushbu baholash kasbiy pedagogik-psixologik kuzatuv hisoblanadi va tibbiy tashxis qo‘yish uchun asos bo‘lmaydi.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. O'QUVCHI VA MA'LUMOTLAR
                  SurfaceCard(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              LucideIcons.userRoundCheck,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Baholanayotgan O‘quvchi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

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

                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Kasbiy diagnostika yo‘nalishi *',
                            prefixIcon: Icon(
                              roleIcon,
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
                  const SizedBox(height: 20),

                  // 3. SOHAGA MOS RUBRIKA MEZONLARI
                  SurfaceCard(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.slidersHorizontal,
                                  size: 20,
                                  color: role.color,
                                ),
                                const SizedBox(width: 10),
                                const Flexible(
                                  child: Text(
                                    'Kasbiy Rubrika Mezonlari',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            StatusPill(
                              label:
                                  'Jami: ${_totalScore.toInt()} / ${_maxTotalScore.toInt()} ball',
                              color: role.color,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.78),
                              icon: LucideIcons.award,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Har bir mezon bo‘yicha bolaning haqiqiy o‘zlashtirish darajasini belgilang:',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Dinamik mezon slayderlari
                        ...List.generate(_criteriaList.length, (index) {
                          final item = _criteriaList[index];
                          final score = item['score'] as double;
                          final max = item['max'] as double;
                          final name = item['name'] as String;

                          return GlassWell(
                            margin: const EdgeInsets.only(bottom: 14),
                            borderRadius: 18,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: AppColors.textPrimary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.2,
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
                                const SizedBox(height: 6),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 5.5,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8,
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
                  const SizedBox(height: 20),

                  // 4. MUTAXASSIS XULOSASI VA TAVSIYALARI
                  SurfaceCard(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mutaxassis Xulosasi va Pedagogik Tavsiyalar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
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
                        const SizedBox(height: 14),
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
                  const SizedBox(height: 24),

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
