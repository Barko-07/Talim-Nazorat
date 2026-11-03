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
import '../psychologist/assessment/assessment_result_screen.dart';
import '../psychologist/assessment/create_assessment_flow.dart';

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
          break;
        case UserRole.psychologist:
          _titleCtrl.text = 'Kognitiv jarayonlar va hissiy barqarorlik tahlili';
          break;
        case UserRole.specialEducation:
          _titleCtrl.text = 'Sensor integratsiya va motorika diagnostikasi';
          break;
        case UserRole.teacher:
          _titleCtrl.text =
              'Dars mashg‘ulotlari va o‘quv motivatsiyasi kuzatuvi';
          break;
        default:
          _titleCtrl.text = 'Oraliq pedagogik-psixologik monitoring';
          break;
      }

      // Mezonlarni klonlash (har biri uchun 'score' o'zgarishi mumkin)
      _criteriaList =
          role.assessmentCriteria.map((c) {
            return {
              'name': c['name'] as String,
              'max': (c['max'] as num).toDouble(),
              'score': 0.0,
              'rated': false,
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
      if (_criteriaList.any((criterion) => criterion['rated'] != true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saqlashdan oldin har bir mezonni baholang.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

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

      final results =
          _criteriaList.map((c) {
            return AssessmentCriterionResult(
              criterionName: c['name'] as String,
              score: c['score'] as double,
              maxScore: c['max'] as double,
            );
          }).toList();

      // Haqiqiy oldingi baholashni bazadan qidirish (soxta ball kiritmaslik)
      final pastAssessments =
          app.assessments
              .where(
                (a) =>
                    a.studentId == student.id &&
                    a.category == _category &&
                    a.isCompleted,
              )
              .toList();
      double? realPreviousScore;
      if (pastAssessments.isNotEmpty) {
        pastAssessments.sort(
          (a, b) => b.assessmentDate.compareTo(a.assessmentDate),
        );
        final latestComparable = pastAssessments
            .cast<AssessmentModel?>()
            .firstWhere(
              (previous) =>
                  previous != null &&
                  previous.specialistRole ==
                      (user?.role.label ?? 'Mutaxassis') &&
                  previous.type == _type &&
                  previous.criteria.length == results.length &&
                  previous.criteria.asMap().entries.every(
                    (entry) =>
                        entry.value.criterionName ==
                            results[entry.key].criterionName &&
                        entry.value.maxScore == results[entry.key].maxScore,
                  ),
              orElse: () => null,
            );
        realPreviousScore = latestComparable?.totalScore;
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
        notes: _notesCtrl.text.trim(),
        recommendations: _recommendationsCtrl.text.trim(),
        totalScore: total,
        maxScore: maxTotal,
        previousScore: realPreviousScore,
        criteria: results,
        followUpAction: _recommendationsCtrl.text.trim(),
        reviewDate: DateTime.now().add(const Duration(days: 30)),
      );

      await app.addAssessment(assessment);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentResultScreen(assessment: assessment),
          ),
        );
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

    if (role == UserRole.psychologist) {
      final initialStudent =
          widget.initialStudentId != null
              ? students
                  .where((s) => s.id == widget.initialStudentId)
                  .firstOrNull
              : null;
      return CreateAssessmentFlow(initialStudent: initialStudent);
    }

    if (!role.canCreateAssessments) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Baholash Huquqi Cheklangan')),
        body: AmbientMeshBackground(
          child: Center(
            child: ResponsivePageContainer(
              maxWidth: 520,
              child: SurfaceCard(
                borderRadius: 26,
                padding: const EdgeInsets.all(28),
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

    final categories =
        role.assessmentCategories.isNotEmpty
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
                    padding: const EdgeInsets.all(18),
                    borderRadius: 26,
                    opacity: 0.96,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: role.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: role.color.withValues(alpha: 0.18),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(roleIcon, color: role.color, size: 19),
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
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    tintColor: AppColors.infoBg,
                    borderColor: AppColors.infoBorder,
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
                    borderRadius: 26,
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
                          items:
                              students
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
                          onChanged:
                              (v) => setState(() => _selectedStudentId = v),
                          validator:
                              (v) => v == null ? 'O‘quvchini tanlang' : null,
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
                          items:
                              categories
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
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Nomini kiriting'
                                      : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. SOHAGA MOS RUBRIKA MEZONLARI
                  SurfaceCard(
                    borderRadius: 26,
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
                              backgroundColor: role.color.withValues(
                                alpha: 0.08,
                              ),
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
                        const SizedBox(height: 6),
                        const Text(
                          'Bu ichki pedagogik kuzatuv rubrikasi; standartlashtirilgan test yoki tibbiy tashxis o‘rnini bosmaydi. Faqat o‘tkazilgan kuzatuv natijalarini kiriting.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.warning,
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
                          final rated = item['rated'] as bool;

                          return GlassWell(
                            margin: const EdgeInsets.only(bottom: 12),
                            borderRadius: 12,
                            padding: const EdgeInsets.fromLTRB(15, 13, 15, 8),
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
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 0.85,
                                        ),
                                      ),
                                      child: Text(
                                        rated
                                            ? '${score.toInt()} / ${max.toInt()} ball'
                                            : 'Baholanmagan',
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
                                    onChangeStart: (_) {
                                      setState(() => item['rated'] = true);
                                    },
                                    onChanged: (v) {
                                      setState(() {
                                        item['score'] = v;
                                        item['rated'] = true;
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
                    borderRadius: 26,
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
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
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
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
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
