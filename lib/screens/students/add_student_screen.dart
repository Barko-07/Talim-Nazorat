import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/student_model.dart';
import '../../providers/app_provider.dart';

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
  final DateTime _dob = DateTime(2018, 5, 10);

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

  void _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      final app = context.read<AppProvider>();
      final newStudent = StudentModel(
        id: 'std_${const Uuid().v4().substring(0, 8)}',
        institutionId: 'inst_tashkent_14',
        institutionName: 'Toshkent shahar 14-Inklyuziv maktab',
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim().isEmpty
            ? null
            : _middleNameCtrl.text.trim(),
        dateOfBirth: _dob,
        gender: _gender,
        grade: _grade,
        status: 'Faol',
        primaryNeed: _primaryNeed,
        supportLevel: _supportLevel,
        medicalNotes: _medicalNotesCtrl.text.trim().isEmpty
            ? null
            : _medicalNotesCtrl.text.trim(),
        psychologicalNotes: _psychNotesCtrl.text.trim().isEmpty
            ? null
            : _psychNotesCtrl.text.trim(),
        guardians: [
          GuardianModel(
            id: 'g_${const Uuid().v4().substring(0, 6)}',
            fullName: _guardianNameCtrl.text.trim().isNotEmpty
                ? _guardianNameCtrl.text.trim()
                : 'Vasiy',
            relationship: _guardianRelation,
            phone: _guardianPhoneCtrl.text.trim().isNotEmpty
                ? _guardianPhoneCtrl.text.trim()
                : '+998 90 000-00-00',
            address: _addressCtrl.text.trim().isEmpty
                ? null
                : _addressCtrl.text.trim(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      await app.addStudent(newStudent);

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
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
                        borderRadius: 18,
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
                              decoration: const InputDecoration(
                                labelText: 'Familiyasi *',
                                prefixIcon: Icon(
                                  LucideIcons.user,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Familiyani kiriting'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _firstNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Ismi *',
                                prefixIcon: Icon(
                                  LucideIcons.user,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Ismni kiriting'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _middleNameCtrl,
                              decoration: const InputDecoration(
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
                                    items: ['Erkak', 'Ayol']
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(g),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _gender = v!),
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
                                    items: [
                                      '1-A',
                                      '1-B',
                                      '2-A',
                                      '2-B',
                                      '3-A',
                                      '3-B',
                                      '4-A',
                                      '5-A',
                                    ]
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(g),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _grade = v!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Ta'limiy ehtiyoj
                      SurfaceCard(
                        borderRadius: 18,
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
                              items: _needs
                                  .map(
                                    (n) => DropdownMenuItem(
                                      value: n,
                                      child: Text(
                                        n,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _primaryNeed = v!),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _supportLevel,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Qo‘llab-quvvatlash darajasi',
                              ),
                              items: _supportLevels
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _supportLevel = v!),
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
                        borderRadius: 18,
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
                              decoration: const InputDecoration(
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
                                items: [
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
                                onChanged: (v) =>
                                    setState(() => _guardianRelation = v!),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _guardianPhoneCtrl,
                                decoration: const InputDecoration(
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
                                      items: [
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
                                      onChanged: (v) => setState(
                                        () => _guardianRelation = v!,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _guardianPhoneCtrl,
                                      decoration: const InputDecoration(
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
                              decoration: const InputDecoration(
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
                            fontSize: 15,
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
