import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/namangan_data.dart';
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
  final _guardianNameCtrl = TextEditingController();
  final _guardianPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _medicalNotesCtrl = TextEditingController();
  final _psychNotesCtrl = TextEditingController();

  String _gender = 'Erkak';
  String _grade = '1-A';
  String _supportLevel = '2-daraja (O‘rta yordam - doimiy korreksiya)';
  String _primaryNeed =
      'Nutqiy rivojlanishdan orqada qolish (Fonetik-fonematik)';
  String _guardianRelation = 'Onasi';
  DateTime _dob = DateTime(2018, 5, 10);
  String _selectedDistrict = NamanganData.defaultDistrict;
  String _educationForm = StudentModel.educationForms.first;
  String _selectedInstitution = '';

  static const List<String> _grades = [
    'Tayyorlov guruhi',
    '1-A',
    '1-B',
    '2-A',
    '2-B',
    '3-A',
    '3-B',
    '4-A',
    '4-B',
    '5-A',
    '5-B',
    '6-A',
    '7-A',
    '8-A',
    '9-A',
    '10-A',
    '11-A',
  ];

  final List<String> _needs = [
    'Nutqiy rivojlanishdan orqada qolish (Fonetik-fonematik)',
    'Umumiy nutq rivojlanmaganligi (1-3 darajalar)',
    'Diqqat yetishmasligi va giperaktivlik (ADHD)',
    'Kognitiv rivojlanish kechikishi',
    'Autizm spektri buzilishi (Yengil / O‘rta)',
    'Eshitish zaifligi (1-2 daraja)',
    'Bolalar serebral falaji (Harakat tayanch tizimi)',
  ];

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
    _guardianNameCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    _addressCtrl.dispose();
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
      final guardianName = _guardianNameCtrl.text.trim();
      final guardianPhone = _guardianPhoneCtrl.text.trim();
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
        grade: _grade,
        status: 'Faol',
        primaryNeed: _primaryNeed,
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
          if (guardianName.isNotEmpty || guardianPhone.isNotEmpty)
            GuardianModel(
              id: 'g_${const Uuid().v4().substring(0, 6)}',
              fullName:
                  guardianName.isNotEmpty ? guardianName : _guardianRelation,
              relationship: _guardianRelation,
              phone: guardianPhone,
              address:
                  _addressCtrl.text.trim().isEmpty
                      ? null
                      : _addressCtrl.text.trim(),
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
            content: Text(
              '${newStudent.fullName} muvaffaqiyatli ro‘yxatga olindi!',
            ),
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
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.glassWellFill,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.glassInnerBorder, width: 1.0),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.1,
                  wordSpacing: 0.35,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Yangi o‘quvchini ro‘yxatga olish')),
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
                              title: '1. O‘quvchining Shaxsiy Ma’lumotlari',
                              subtitle:
                                  'Asosiy F.I.Sh., jinsi va biriktirilgan sinf',
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
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _grade,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Sinfi',
                                    ),
                                    items:
                                        _grades
                                            .map(
                                              (g) => DropdownMenuItem(
                                                value: g,
                                                child: Text(g),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (v) => setState(() => _grade = v!),
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
                              title: '2. Alohida Ta’limiy Ehtiyoj',
                              subtitle:
                                  'Ehtiyoj toifasi, qo‘llab-quvvatlash darajasi va tavsiyalar',
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              initialValue: _primaryNeed,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Asosiy ta’limiy ehtiyoj toifasi',
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
                                labelText: 'Tibbiy xulosalar va cheklovlar',
                                hintText:
                                    'Masalan: Eshitish apparati taqqan, jismoniy zo‘riqish taqiqlangan',
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
                              title: '3. Qonuniy Vasiy (Ota-ona)',
                              subtitle:
                                  'Bog‘lanish uchun aloqa va manzil ma’lumotlari',
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _guardianNameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Vasiy to‘liq F.I.Sh.',
                                prefixIcon: Icon(
                                  LucideIcons.userCheck,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (isCompact) ...[
                              DropdownButtonFormField<String>(
                                initialValue: _guardianRelation,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Qarindoshligi',
                                ),
                                items:
                                    [
                                          'Onasi',
                                          'Otasi',
                                          'Bobosi',
                                          'Buvasi',
                                          'Vasiy',
                                        ]
                                        .map(
                                          (r) => DropdownMenuItem(
                                            value: r,
                                            child: Text(r),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) =>
                                        setState(() => _guardianRelation = v!),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _guardianPhoneCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Telefon raqami',
                                  hintText: '+998 90 123-45-67',
                                  prefixIcon: Icon(
                                    LucideIcons.phone,
                                    size: 17,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ] else
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _guardianRelation,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Qarindoshligi',
                                      ),
                                      items:
                                          [
                                                'Onasi',
                                                'Otasi',
                                                'Bobosi',
                                                'Buvasi',
                                                'Vasiy',
                                              ]
                                              .map(
                                                (r) => DropdownMenuItem(
                                                  value: r,
                                                  child: Text(r),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (v) => setState(
                                            () => _guardianRelation = v!,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _guardianPhoneCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Telefon raqami',
                                        hintText: '+998 90 123-45-67',
                                        prefixIcon: Icon(
                                          LucideIcons.phone,
                                          size: 17,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _addressCtrl,
                              decoration: InputDecoration(
                                labelText: 'Yashash manzili',
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
                          'O‘quvchini tizimga saqlash',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
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
