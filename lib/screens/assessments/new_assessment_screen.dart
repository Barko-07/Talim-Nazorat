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
          SnackBar(
            content: Text('Har bir mezonga daraja qo‘ying'),
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
          SnackBar(
            content: Text('Bolani tanlang'),
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
        appBar: AppBar(title: const Text('Baholash')),
        body: AmbientMeshBackground(
          child: Center(
            child: ResponsivePageContainer(
              maxWidth: 520,
              child: SurfaceCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.lock, size: 32, color: AppColors.textSubtle),
                    const SizedBox(height: 12),
                    Text(
                      'Baholash kiritish huquqi yo‘q',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sizning rolingiz faqat ko‘rish uchun',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Orqaga'),
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

    Widget sectionTitle(String text, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Yangi baholash')),
      body: AmbientMeshBackground(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: ResponsivePageContainer(
              maxWidth: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Bola
                  SurfaceCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sectionTitle('Bola'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStudentId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Bola *',
                            prefixIcon: Icon(LucideIcons.user, size: 18),
                          ),
                          items: [
                            for (final st in students)
                              DropdownMenuItem(
                                value: st.id,
                                child: Text(
                                  '${st.fullName} · ${st.grade} sinf',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged:
                              (v) => setState(() => _selectedStudentId = v),
                          validator: (v) => v == null ? 'Bolani tanlang' : null,
                        ),
                        if (categories.length > 1) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Yo‘nalish',
                            ),
                            items: [
                              for (final c in categories)
                                DropdownMenuItem(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Baholash nomi *',
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
                  const SizedBox(height: 16),

                  // 2. Mezonlar: har biri 0–5 daraja (bir daraja = max/5 ball)
                  SurfaceCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sectionTitle(
                          'Mezonlar',
                          trailing: Text(
                            '${_totalScore.toInt()} / ${_maxTotalScore.toInt()} ball',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        Text(
                          '0 — shakllanmagan, 5 — to‘liq mustaqil',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < _criteriaList.length; i++)
                          _CriterionLevels(
                            name: _criteriaList[i]['name'] as String,
                            max: _criteriaList[i]['max'] as double,
                            score: _criteriaList[i]['score'] as double,
                            rated: _criteriaList[i]['rated'] as bool,
                            onPick: (level) => setState(() {
                              final max = _criteriaList[i]['max'] as double;
                              _criteriaList[i]['score'] = max * level / 5;
                              _criteriaList[i]['rated'] = true;
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Xulosa
                  SurfaceCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sectionTitle('Xulosa'),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Xulosa *',
                            alignLabelWithHint: true,
                          ),
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Xulosani kiriting'
                                      : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _recommendationsCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Tavsiyalar (ixtiyoriy)',
                            hintText: 'Jamoa va o‘qituvchi uchun',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _saveAssessment,
                    child: const Text(
                      'Saqlash',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pedagogik kuzatuv, tibbiy tashxis emas',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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

/// Bitta mezon: nomi va 0–5 daraja tugmalari (tanlangani ajralib turadi).
class _CriterionLevels extends StatelessWidget {
  final String name;
  final double max;
  final double score;
  final bool rated;
  final ValueChanged<int> onPick;

  const _CriterionLevels({
    required this.name,
    required this.max,
    required this.score,
    required this.rated,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final level = rated && max > 0 ? (score / max * 5).round() : -1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                rated ? '${score.toInt()} / ${max.toInt()}' : '—',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var l = 0; l <= 5; l++) ...[
                if (l > 0) const SizedBox(width: 6),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: l == level,
                    label: '$name: $l',
                    child: InkWell(
                      onTap: () => onPick(l),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: l == level ? AppColors.primaryLight : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: l == level ? AppColors.primary : AppColors.border,
                            width: l == level ? 1.6 : 1,
                          ),
                        ),
                        child: Text(
                          '$l',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: l == level ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

