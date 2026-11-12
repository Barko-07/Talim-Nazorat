import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/iep_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';

/// Yangi ITR rejasi — alohida sahifa, uchta aniq bo'lim:
/// Reja, Holat va maqsad, Birinchi qisqa maqsad.
class NewIepScreen extends StatefulWidget {
  final UserModel currentUser;
  const NewIepScreen({super.key, required this.currentUser});

  @override
  State<NewIepScreen> createState() => _NewIepScreenState();
}

class _NewIepScreenState extends State<NewIepScreen> {
  static const domains = <String, String>{
    'Kognitiv': 'Kognitiv',
    'Nutq': 'Nutq va muloqot',
    'O‘quv': 'O‘quv ko‘nikmalari',
    'Ijtimoiy-hissiy': 'Ijtimoiy-hissiy',
    'Sensor-motorika': 'Sensor-motorika',
  };

  final _formKey = GlobalKey<FormState>();
  late String _studentId;
  late final _title = TextEditingController(
    text: '$_year o‘quv yili uchun ITR',
  );
  late final _yearCtrl = TextEditingController(text: _year);
  final _baseline = TextEditingController();
  final _goals = TextEditingController();
  final _strategies = TextEditingController();
  final _objTitle = TextEditingController();
  final _objStart = TextEditingController(text: '20%');
  final _objTarget = TextEditingController(text: '80%');
  final _objCriteria = TextEditingController();
  String _domain = 'Kognitiv';
  final DateTime _startDate = DateTime.now();
  DateTime _reviewDate = DateTime.now().add(const Duration(days: 90));
  bool _saving = false;

  /// Joriy o'quv yili: sentyabrdan boshlanadi.
  static String get _year {
    final now = DateTime.now();
    final y = now.month >= 9 ? now.year : now.year - 1;
    return '$y-${y + 1}';
  }

  @override
  void initState() {
    super.initState();
    _studentId = context.read<AppProvider>().students.first.id;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _yearCtrl,
      _baseline,
      _goals,
      _strategies,
      _objTitle,
      _objStart,
      _objTarget,
      _objCriteria,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v ?? '').trim().isEmpty ? 'To‘ldiring' : null;

  Future<void> _pickReviewDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reviewDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _reviewDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppProvider>();
    final user = widget.currentUser;
    final student = app.students.firstWhere((s) => s.id == _studentId);
    final now = DateTime.now().millisecondsSinceEpoch;
    final objective = PlanObjectiveModel(
      id: 'obj_$now',
      title: _objTitle.text.trim(),
      domain: _domain,
      startingLevel: _objStart.text.trim(),
      targetLevel: _objTarget.text.trim(),
      measurementCriteria: _objCriteria.text.trim(),
      responsibleSpecialistId: user.id,
      responsibleSpecialistName: user.fullName,
      startDate: _startDate,
      targetDate: _reviewDate,
      status: 'Jarayonda',
      progressPercent: 0,
      successCriteria: _objCriteria.text.trim(),
    );
    final plan = IndividualEducationPlanModel(
      id: 'iep_$now',
      studentId: student.id,
      studentName: student.fullName,
      studentGrade: student.grade,
      institutionName: student.institutionName,
      title: _title.text.trim(),
      academicYear: _yearCtrl.text.trim(),
      startDate: _startDate,
      reviewDate: _reviewDate,
      responsibleTeacherId: user.id,
      responsibleTeacherName: user.fullName,
      coordinatorId: student.coordinatorId ?? user.id,
      coordinatorName: student.coordinatorName ?? user.fullName,
      status: 'Faol',
      baselineSummary: _baseline.text.trim(),
      longTermGoals: _goals.text.trim(),
      supportStrategies: _strategies.text.trim(),
      objectives: [objective],
    );
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await app.addIepPlan(plan, byUser: user);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text('${student.fullName} uchun reja saqlandi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<AppProvider>().students;
    final df = DateFormat('dd.MM.yyyy');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Yangi ITR rejasi')),
      body: AmbientMeshBackground(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: ResponsivePageContainer(
              maxWidth: 760,
              child: LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 520;
                  Widget pair(Widget a, Widget b) =>
                      narrow
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [a, const SizedBox(height: 16), b],
                          )
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: a),
                              const SizedBox(width: 16),
                              Expanded(child: b),
                            ],
                          );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Section(
                        icon: LucideIcons.fileText,
                        title: 'Reja',
                        children: [
                          _Labeled(
                            'Bola',
                            DropdownButtonFormField<String>(
                              initialValue: _studentId,
                              isExpanded: true,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              items: [
                                for (final s in students)
                                  DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      '${s.fullName} · ${s.grade} sinf',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _studentId = v!),
                            ),
                          ),
                          _Labeled(
                            'Reja nomi',
                            TextFormField(
                              controller: _title,
                              validator: _required,
                            ),
                          ),
                          pair(
                            _Labeled(
                              'O‘quv yili',
                              TextFormField(
                                controller: _yearCtrl,
                                validator: _required,
                              ),
                              gap: false,
                            ),
                            _Labeled(
                              'Ko‘rib chiqish sanasi',
                              InkWell(
                                onTap: _pickReviewDate,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    suffixIcon: Icon(
                                      LucideIcons.calendar,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  child: Text(df.format(_reviewDate)),
                                ),
                              ),
                              gap: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        icon: LucideIcons.target,
                        title: 'Holat va maqsad',
                        children: [
                          _Labeled(
                            'Hozirgi holat',
                            TextFormField(
                              controller: _baseline,
                              maxLines: 3,
                              minLines: 2,
                              validator: _required,
                              decoration: const InputDecoration(
                                hintText: 'Bola hozir nimani qila oladi',
                              ),
                            ),
                          ),
                          _Labeled(
                            'Yil oxiridagi maqsad',
                            TextFormField(
                              controller: _goals,
                              maxLines: 3,
                              minLines: 2,
                              validator: _required,
                              decoration: const InputDecoration(
                                hintText: 'O‘quv yili oxirida nimaga erishadi',
                              ),
                            ),
                          ),
                          _Labeled(
                            'Yordam usullari',
                            optional: true,
                            TextFormField(
                              controller: _strategies,
                              maxLines: 3,
                              minLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Usullar, jihozlar, moslashtirishlar',
                              ),
                            ),
                            gap: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        icon: LucideIcons.flag,
                        title: 'Birinchi qisqa maqsad',
                        subtitle: 'Keyin reja ichida yana qo‘shish mumkin',
                        children: [
                          _Labeled(
                            'Maqsad',
                            TextFormField(
                              controller: _objTitle,
                              validator: _required,
                              decoration: const InputDecoration(
                                hintText:
                                    'Masalan: 20 ta yangi so‘zni ishlatadi',
                              ),
                            ),
                          ),
                          _Labeled(
                            'Soha',
                            DropdownButtonFormField<String>(
                              initialValue: _domain,
                              isExpanded: true,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              items: [
                                for (final e in domains.entries)
                                  DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _domain = v!),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Labeled(
                                  'Hozirgi daraja',
                                  TextFormField(controller: _objStart),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _Labeled(
                                  'Kutilgan daraja',
                                  TextFormField(controller: _objTarget),
                                ),
                              ),
                            ],
                          ),
                          _Labeled(
                            'Qanday tekshiriladi',
                            TextFormField(
                              controller: _objCriteria,
                              validator: _required,
                              decoration: const InputDecoration(
                                hintText:
                                    'Masalan: 10 tadan 8 tasini to‘g‘ri aytadi',
                              ),
                            ),
                            gap: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving ? 'Saqlanmoqda…' : 'Saqlash',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  const _Section({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                subtitle!,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Nomi maydon ustida (ramka ichida suzib yurmaydi, kesilmaydi).
class _Labeled extends StatelessWidget {
  final String label;
  final Widget field;
  final bool optional;
  final bool gap;
  const _Labeled(
    this.label,
    this.field, {
    this.optional = false,
    this.gap = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: gap ? 16 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (optional)
                  TextSpan(
                    text: '  ixtiyoriy',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          field,
        ],
      ),
    );
  }
}
