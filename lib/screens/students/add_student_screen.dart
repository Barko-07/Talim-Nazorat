import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/namangan_data.dart';
import '../../core/utils/uz_phone.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_exceptions.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _otherNeedCtrl = TextEditingController();
  final List<_GuardianInput> _guardians = [_GuardianInput()];
  final _addressCtrl = TextEditingController();
  final _medicalNotesCtrl = TextEditingController();
  final _psychNotesCtrl = TextEditingController();

  String _gender = 'Erkak';
  // Sinf erkin kiritiladi: "3-B", "5-V", "Tayyorlov".
  final _gradeCtrl = TextEditingController();
  String _supportLevel = '2-daraja (O‘rta yordam - doimiy korreksiya)';
  String _primaryNeed =
      'Nutqiy rivojlanishdan orqada qolish (Fonetik-fonematik)';
  DateTime _dob = DateTime(2018, 5, 10);
  String _selectedDistrict = NamanganData.defaultDistrict;
  String _educationForm = StudentModel.educationForms.first;
  String _selectedInstitution = '';

  /// "3b", "3 B", "3-b" -> "3-B"; boshqa yozuv o'zgarishsiz qoladi.
  static String _normalizeGrade(String v) {
    final t = v.trim();
    final m = RegExp(
      r'^(\d{1,2})\s*[-\s]?\s*([A-Za-z\u0400-\u04FF])$',
    ).firstMatch(t);
    return m == null ? t : '${m.group(1)}-${m.group(2)!.toUpperCase()}';
  }

  final List<String> _needs = [
    'Nutqiy rivojlanishdan orqada qolish (Fonetik-fonematik)',
    'Umumiy nutq rivojlanmaganligi (1-3 darajalar)',
    'Diqqat yetishmasligi va giperaktivlik (ADHD)',
    'Kognitiv rivojlanish kechikishi',
    'Autizm spektri buzilishi (Yengil / O‘rta)',
    'Eshitish zaifligi (1-2 daraja)',
    'Bolalar serebral falaji (Harakat tayanch tizimi)',
    _otherNeed,
  ];

  static const _otherNeed = 'Boshqa';
  static const _maxGuardians = 4;

  final List<String> _supportLevels = [
    '1-daraja (Yengil - minimal moslashtirish)',
    '2-daraja (O‘rta yordam - doimiy korreksiya)',
    '3-daraja (Intensiv yordam - maxsus dastur)',
  ];

  @override
  void initState() {
    super.initState();
    // Odatiy holatda bola shu foydalanuvchining maktabiga qo'shiladi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      setState(() {
        if (user?.district != null &&
            NamanganData.districts.contains(user!.district)) {
          _selectedDistrict = user.district!;
        }
        final schools = NamanganData.getSchoolsForDistrict(_selectedDistrict);
        final own = user?.institutionName;
        _selectedInstitution =
            (own != null && schools.contains(own))
                ? own
                : (schools.isNotEmpty ? schools.first : (own ?? ''));
      });
    });
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _otherNeedCtrl.dispose();
    for (final g in _guardians) {
      g.dispose();
    }
    _addressCtrl.dispose();
    _gradeCtrl.dispose();
    _medicalNotesCtrl.dispose();
    _psychNotesCtrl.dispose();
    super.dispose();
  }

  /// Server rejimida tizim administratoridan boshqa hamma bolani faqat o'z
  /// maktabiga qo'shadi (buni server ham tekshiradi) — maktab tanlanmaydi.
  bool _ownSchoolOnly(UserModel? user) =>
      AppConfig.serverMode && user?.role != UserRole.superAdmin;

  void _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      final app = context.read<AppProvider>();
      final user = context.read<AuthProvider>().currentUser;
      final ownOnly = _ownSchoolOnly(user);
      final schoolName =
          ownOnly
              ? (user?.institutionName ?? '')
              : (_selectedInstitution.trim().isNotEmpty
                  ? _selectedInstitution.trim()
                  : (user?.institutionName ?? ''));
      // O'z maktabi bo'lsa — uning ID si; boshqa maktab tanlansa (tizim administratori) — nomidan
      final schoolId =
          ownOnly
              ? (user?.institutionId ?? '')
              : (user?.institutionName == schoolName &&
                  user?.institutionId != null)
              ? user!.institutionId!
              : 'inst_${schoolName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
      final address = _addressCtrl.text.trim();
      final newStudent = StudentModel(
        id: 'std_${const Uuid().v4().substring(0, 8)}',
        institutionId: schoolId,
        institutionName: schoolName,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        middleName:
            _middleNameCtrl.text.trim().isEmpty
                ? null
                : _middleNameCtrl.text.trim(),
        dateOfBirth: _dob,
        gender: _gender,
        grade: _normalizeGrade(_gradeCtrl.text),
        status: 'Faol',
        primaryNeed:
            _primaryNeed == _otherNeed
                ? _otherNeedCtrl.text.trim()
                : _primaryNeed,
        supportLevel: _supportLevel,
        educationForm: _educationForm,
        medicalNotes:
            _medicalNotesCtrl.text.trim().isEmpty
                ? null
                : _medicalNotesCtrl.text.trim(),
        psychologicalNotes:
            _psychNotesCtrl.text.trim().isEmpty
                ? null
                : _psychNotesCtrl.text.trim(),
        // Vasiy faqat ma'lumot kiritilgan bo'lsa saqlanadi (soxta telefon yoki ism yozilmaydi)
        guardians: [
          for (final g in _guardians)
            if (g.hasData)
              GuardianModel(
                id: 'g_${const Uuid().v4().substring(0, 6)}',
                fullName:
                    g.name.text.trim().isNotEmpty
                        ? g.name.text.trim()
                        : g.relation,
                relationship: g.relation,
                phone: UzPhone.normalize(g.phone.text) ?? '',
                address: address.isEmpty ? null : address,
              ),
        ],
        createdAt: DateTime.now(),
      );

      try {
        await app.addStudent(newStudent);
      } on AppException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newStudent.fullName} qo‘shildi'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _guardianBlock(int index, bool isCompact) {
    final g = _guardians[index];
    final relation = DropdownButtonFormField<String>(
      key: ObjectKey(g),
      initialValue: g.relation,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Kim bo‘ladi'),
      items: [
        for (final r in _GuardianInput.relations)
          DropdownMenuItem(value: r, child: Text(r)),
      ],
      onChanged: (v) => setState(() => g.relation = v!),
    );
    final phone = TextFormField(
      controller: g.phone,
      keyboardType: TextInputType.phone,
      inputFormatters: [UzPhone.formatter],
      decoration: InputDecoration(
        labelText: 'Telefon',
        hintText: UzPhone.hint,
        prefixIcon: Icon(
          LucideIcons.phone,
          size: 17,
          color: AppColors.textMuted,
        ),
      ),
      validator:
          (v) =>
              UzPhone.isEmpty(v ?? '') || UzPhone.isValid(v ?? '')
                  ? null
                  : UzPhone.error,
    );
    return Column(
      key: ObjectKey(g),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_guardians.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  '${index + 1}-vasiy',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed:
                      () => setState(() {
                        _guardians.removeAt(index).dispose();
                      }),
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Olib tashlash'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        TextFormField(
          controller: g.name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'F.I.Sh.',
            prefixIcon: Icon(
              LucideIcons.userCheck,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (isCompact) ...[
          relation,
          const SizedBox(height: 14),
          phone,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: relation),
              const SizedBox(width: 14),
              Expanded(child: phone),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Yangi bola')),
      body: AmbientMeshBackground(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: ResponsivePageContainer(
              maxWidth: 800,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 460;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Shaxsiy ma'lumotlar
                      SurfaceCard(
                        borderRadius: 26,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              icon: LucideIcons.userRoundPlus,
                              title: 'Shaxsiy ma’lumotlar',
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _lastNameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Familiyasi *',
                                prefixIcon: Icon(
                                  LucideIcons.user,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Familiyani kiriting'
                                          : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _firstNameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Ismi *',
                                prefixIcon: Icon(
                                  LucideIcons.user,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Ismni kiriting'
                                          : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _middleNameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Otasining ismi',
                                prefixIcon: Icon(
                                  LucideIcons.user,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _gender,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Jinsi',
                                    ),
                                    items:
                                        ['Erkak', 'Ayol']
                                            .map(
                                              (g) => DropdownMenuItem(
                                                value: g,
                                                child: Text(g),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (v) => setState(() => _gender = v!),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextFormField(
                                    controller: _gradeCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: const InputDecoration(
                                      labelText: 'Sinfi *',
                                      hintText: 'Masalan: 3-B',
                                    ),
                                    validator: (v) {
                                      final t = (v ?? '').trim();
                                      if (t.isEmpty) return 'Sinfni kiriting';
                                      if (t.length > 20) return 'Juda uzun';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: _pickDateOfBirth,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Tug‘ilgan sanasi *',
                                  prefixIcon: Icon(
                                    LucideIcons.calendar,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                child: Text(
                                  '${_dob.day.toString().padLeft(2, '0')}.${_dob.month.toString().padLeft(2, '0')}.${_dob.year}',
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _educationForm,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Ta’lim shakli',
                              ),
                              items:
                                  StudentModel.educationForms
                                      .map(
                                        (f) => DropdownMenuItem(
                                          value: f,
                                          child: Text(f),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _educationForm = v);
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            if (_ownSchoolOnly(
                              context.read<AuthProvider>().currentUser,
                            ))
                              _OwnSchoolField(
                                name:
                                    context
                                        .read<AuthProvider>()
                                        .currentUser
                                        ?.institutionName,
                              )
                            else ...[
                              DropdownButtonFormField<String>(
                                key: ValueKey('district_$_selectedDistrict'),
                                initialValue:
                                    NamanganData.districts.contains(
                                          _selectedDistrict,
                                        )
                                        ? _selectedDistrict
                                        : null,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Tuman / shahar',
                                ),
                                items:
                                    NamanganData.districts
                                        .map(
                                          (d) => DropdownMenuItem(
                                            value: d,
                                            child: Text(d),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final schools =
                                      NamanganData.getSchoolsForDistrict(v);
                                  setState(() {
                                    _selectedDistrict = v;
                                    _selectedInstitution =
                                        schools.isNotEmpty ? schools.first : '';
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                key: ValueKey(
                                  'school_${_selectedDistrict}_$_selectedInstitution',
                                ),
                                initialValue:
                                    NamanganData.getSchoolsForDistrict(
                                          _selectedDistrict,
                                        ).contains(_selectedInstitution)
                                        ? _selectedInstitution
                                        : null,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Ta’lim muassasasi *',
                                ),
                                items:
                                    NamanganData.getSchoolsForDistrict(
                                          _selectedDistrict,
                                        )
                                        .map(
                                          (sch) => DropdownMenuItem(
                                            value: sch,
                                            child: Text(
                                              sch,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedInstitution = v);
                                  }
                                },
                                validator:
                                    (v) =>
                                        (v == null || v.isEmpty) &&
                                                _selectedInstitution.isEmpty
                                            ? 'Ta’lim muassasasini tanlang'
                                            : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Ta'limiy ehtiyoj
                      SurfaceCard(
                        borderRadius: 26,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              icon: LucideIcons.heartHandshake,
                              title: 'Ta’lim ehtiyoji',
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              initialValue: _primaryNeed,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Asosiy ehtiyoj',
                              ),
                              items:
                                  _needs
                                      .map(
                                        (n) => DropdownMenuItem(
                                          value: n,
                                          child: Text(
                                            n,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _primaryNeed = v!),
                            ),
                            if (_primaryNeed == _otherNeed) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _otherNeedCtrl,
                                autofocus: true,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: 'Ehtiyojni yozing *',
                                  hintText: 'Masalan: Ko‘rish zaifligi',
                                ),
                                validator: (v) {
                                  final t = (v ?? '').trim();
                                  if (t.isEmpty) return 'Ehtiyojni yozing';
                                  if (t.length > 120) return 'Juda uzun';
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _supportLevel,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Qo‘llab-quvvatlash darajasi',
                              ),
                              items:
                                  _supportLevels
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(
                                            d,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _supportLevel = v!),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _medicalNotesCtrl,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Tibbiy cheklovlar (ixtiyoriy)',
                                hintText: 'Masalan: eshitish apparati taqadi',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Oila va Vasiylar
                      SurfaceCard(
                        borderRadius: 26,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              icon: LucideIcons.usersRound,
                              title: 'Vasiylar',
                              subtitle: 'Ota-ona yoki boshqa vasiy',
                            ),
                            const SizedBox(height: 20),
                            for (var i = 0; i < _guardians.length; i++) ...[
                              if (i > 0) ...[
                                const SizedBox(height: 16),
                                Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 12),
                              ],
                              _guardianBlock(i, isCompact),
                            ],
                            if (_guardians.length < _maxGuardians) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      () => setState(
                                        () => _guardians.add(_GuardianInput()),
                                      ),
                                  icon: const Icon(LucideIcons.plus, size: 16),
                                  label: const Text('Vasiy qo‘shish'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _addressCtrl,
                              decoration: InputDecoration(
                                labelText: 'Yashash manzili (ixtiyoriy)',
                                prefixIcon: Icon(
                                  LucideIcons.mapPin,
                                  size: 17,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(LucideIcons.circleCheck, size: 18),
                        label: const Text(
                          'Saqlash',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _saveStudent,
                      ),
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

/// O'z maktabi — o'zgartirib bo'lmaydigan maydon ko'rinishida.
class _OwnSchoolField extends StatelessWidget {
  const _OwnSchoolField({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Ta’lim muassasasi',
        helperText: 'Bola sizning maktabingizga qo‘shiladi',
        prefixIcon: Icon(
          LucideIcons.building2,
          size: 18,
          color: AppColors.primary,
        ),
      ),
      child: Text(
        (name ?? '').trim().isNotEmpty ? name!.trim() : 'O‘z maktabingiz',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Bitta vasiy maydonlari (ism, kim bo'ladi, telefon).
class _GuardianInput {
  static const relations = [
    'Onasi',
    'Otasi',
    'Bobosi',
    'Buvisi',
    'Akasi / opasi',
    'Vasiy',
  ];

  final name = TextEditingController();
  final phone = TextEditingController(text: UzPhone.prefix);
  String relation = relations.first;

  bool get hasData =>
      name.text.trim().isNotEmpty || !UzPhone.isEmpty(phone.text);

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}
