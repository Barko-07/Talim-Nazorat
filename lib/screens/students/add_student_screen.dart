import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
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
  String _supportLevel = '2-daraja (O‘rta yordam)';
  String _primaryNeed = 'Nutqiy rivojlanishdan orqada qolish (Fonetik-fonematik)';
  String _guardianRelation = 'Onasi';
  DateTime _dob = DateTime(2018, 5, 10);

  final List<String> _needs = [
    'Nutqiy rivojlanishdan orqada qolish (Fonetik-fonematik)',
    'Umumiy nutq rivojlanmaganligi (1-3 darajalar)',
    'Diqqat yetishmasligi va giperaktivlik (ADHD)',
    'Kognitiv rivojlanish kechikishi',
    'Autizm spektri buzilishi (Yengil / O‘rta)',
    'Eshitish zaifligi (1-2 daraja)',
    'Bolalar serebral falaji (Harakat tayanch tizimi)',
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
        middleName: _middleNameCtrl.text.trim().isEmpty ? null : _middleNameCtrl.text.trim(),
        dateOfBirth: _dob,
        gender: _gender,
        grade: _grade,
        status: 'Faol',
        primaryNeed: _primaryNeed,
        supportLevel: _supportLevel,
        medicalNotes: _medicalNotesCtrl.text.trim().isEmpty ? null : _medicalNotesCtrl.text.trim(),
        psychologicalNotes: _psychNotesCtrl.text.trim().isEmpty ? null : _psychNotesCtrl.text.trim(),
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
            address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      await app.addStudent(newStudent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newStudent.fullName} muvaffaqiyatli ro‘yxatga olindi!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi o‘quvchini ro‘yxatga olish'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Shaxsiy ma'lumotlar
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. O‘quvchining Shaxsiy Ma’lumotlari',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(labelText: 'Familiyasi *'),
                        validator: (v) => v == null || v.isEmpty ? 'Familiyani kiriting' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(labelText: 'Ismi *'),
                        validator: (v) => v == null || v.isEmpty ? 'Ismni kiriting' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _middleNameCtrl,
                        decoration: const InputDecoration(labelText: 'Otasining ismi'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(labelText: 'Jinsi'),
                              items: ['Erkak', 'Ayol'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (v) => setState(() => _gender = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _grade,
                              decoration: const InputDecoration(labelText: 'Sinfi'),
                              items: ['1-A', '1-B', '2-A', '2-B', '3-A', '3-B', '4-A', '5-A']
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (v) => setState(() => _grade = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Ta'limiy ehtiyoj
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2. Alohida Ta’limiy Ehtiyoj va Qo‘llab-quvvatlash',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _primaryNeed,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Asosiy ta’limiy ehtiyoj toifasi'),
                        items: _needs.map((n) => DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => _primaryNeed = v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _supportLevel,
                        decoration: const InputDecoration(labelText: 'Qo‘llab-quvvatlash darajasi'),
                        items: [
                          '1-daraja (Yengil - minimal moslashtirish)',
                          '2-daraja (O‘rta yordam - doimiy korreksiya)',
                          '3-daraja (Intensiv yordam - maxsus dastur)',
                        ].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => _supportLevel = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _medicalNotesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Tibbiy xulosalar va cheklovlar',
                          hintText: 'Masalan: Eshitish apparati taqqan, jismoniy zo‘riqish taqiqlangan',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Oila va Vasiylar
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '3. Qonuniy Vasiy (Ota-ona) Ma’lumotlari',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _guardianNameCtrl,
                        decoration: const InputDecoration(labelText: 'Vasiy to‘liq F.I.Sh.'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _guardianRelation,
                              decoration: const InputDecoration(labelText: 'Qarindoshligi'),
                              items: ['Onasi', 'Otasi', 'Bobosi', 'Buvasi', 'Vasiy']
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                  .toList(),
                              onChanged: (v) => setState(() => _guardianRelation = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _guardianPhoneCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Telefon raqami',
                                hintText: '+998 90 123-45-67',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(labelText: 'Yashash manzili'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Saqlash tugmasi
              FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('O‘quvchini tizimga saqlash', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: _saveStudent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
