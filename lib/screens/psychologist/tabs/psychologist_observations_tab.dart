import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/psychologist_observation_model.dart';
import '../../../models/student_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';

class PsychologistObservationsTab extends StatefulWidget {
  final StudentModel? preselectedStudent;

  const PsychologistObservationsTab({super.key, this.preselectedStudent});

  @override
  State<PsychologistObservationsTab> createState() =>
      _PsychologistObservationsTabState();
}

class _PsychologistObservationsTabState
    extends State<PsychologistObservationsTab> {
  String _search = '';
  String? _categoryFilter;
  String? _stateFilter;

  static const List<String> _categories = [
    'Darsdagi xulq-atvor',
    'Hissiy holat (Affektiv)',
    'Tengdoshlar bilan muloqot',
    'Kognitiv faollik va diqqat',
    'Sensor yoki xavotir belgilari',
  ];

  static const List<String> _emotionalStates = [
    'Barqaror / Ijobiy',
    'Xavotirli',
    'Tirishqoq / Chalg‘uvchan',
    'Agressiv / Qo‘zg‘aluvchan',
    'Passiv / Tortinchoq',
  ];

  void showAddObservationDialog(BuildContext context, {StudentModel? initialStudent}) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final students = app.students;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuzatuv qayd etish uchun birorta o‘quvchi mavjud emas.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    StudentModel selectedStudent = initialStudent ?? students.first;
    String selectedCategory = _categories.first;
    String selectedState = _emotionalStates.first;
    final triggerCtrl = TextEditingController(
      text: 'Dars jarayonida mustaqil topshiriq berilganda',
    );
    final textCtrl = TextEditingController();
    final recCtrl = TextEditingController();
    DateTime obsDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final df = DateFormat('dd.MM.yyyy');

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Kuzatuv Kundaligiga Yangi Qayd',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // O'quvchi
                    DropdownButtonFormField<StudentModel>(
                      value: students.contains(selectedStudent)
                          ? selectedStudent
                          : students.first,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kuzatilgan o‘quvchi *',
                      ),
                      items: students
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                '${s.fullName} (${s.grade})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDlgState(() => selectedStudent = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Sana
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: obsDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setDlgState(() => obsDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Kuzatuv sanasi *',
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(df.format(obsDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedState,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Emotsional holati *',
                            ),
                            items: _emotionalStates
                                .map(
                                  (st) => DropdownMenuItem(
                                    value: st,
                                    child: Text(st, style: const TextStyle(fontSize: 12)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setDlgState(() => selectedState = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Kategoriya
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kuzatuv toifasi *',
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDlgState(() => selectedCategory = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Kontekst / Turtki
                    TextField(
                      controller: triggerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vaziyat / Kontekst (Qachon va qanday sharoitda?)',
                        hintText: 'Masalan: Tanaffusda, yangi mavzu o‘tilayotganda...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Asosiy kuzatuv bayoni
                    TextField(
                      controller: textCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Kuzatilgan xulq-atvor va o‘zgarishlar tavsifi *',
                        hintText: 'Bolaning reaksiyasi, xatti-harakati, mimikasi va diqqati...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tavsiya
                    TextField(
                      controller: recCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Ko‘rilgan chora yoki pedagog/ota-onaga tavsiya',
                        hintText: 'Qo‘llanilgan korreksion yondashuv yoki berilgan ko‘rsatma...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text('Bekor qilish'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                ),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Kundalikka kiritish'),
                onPressed: () async {
                  if (textCtrl.text.trim().isEmpty) return;

                  final newObs = PsychologicalObservationModel(
                    id: 'obs_${const Uuid().v4().substring(0, 8)}',
                    studentId: selectedStudent.id,
                    studentName: selectedStudent.fullName,
                    studentGrade: selectedStudent.grade,
                    psychologistId: currentUser?.id ?? 'user_psychologist',
                    psychologistName:
                        currentUser?.fullName ?? '',
                    date: obsDate,
                    category: selectedCategory,
                    emotionalState: selectedState,
                    triggerOrContext: triggerCtrl.text.trim().isNotEmpty
                        ? triggerCtrl.text.trim()
                        : null,
                    observationText: textCtrl.text.trim(),
                    recommendationOrAction: recCtrl.text.trim().isNotEmpty
                        ? recCtrl.text.trim()
                        : null,
                    isConfidential: true,
                    createdAt: DateTime.now(),
                  );

                  await app.addObservation(newObs, byUser: currentUser);
                  if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${selectedStudent.fullName} uchun kuzatuv qayd etildi!',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allObservations = app.observations;
    final df = DateFormat('dd.MM.yyyy');

    final filtered = allObservations.where((o) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final mName = o.studentName.toLowerCase().contains(q);
        final mText = o.observationText.toLowerCase().contains(q);
        if (!mName && !mText) return false;
      }
      if (_categoryFilter != null && o.category != _categoryFilter) {
        return false;
      }
      if (_stateFilter != null && o.emotionalState != _stateFilter) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sarlavha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Psixologik Kuzatuv Jurnali',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFD97706).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${filtered.length} ta qayd',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bolaning darsdagi xulq-atvori, hissiy holati va dinamik o‘zgarishlari xronologik daftari',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: () => showAddObservationDialog(context),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('+ Yangi Kuzatuv Qo‘shish'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // FILTRLAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'O‘quvchi yoki kuzatuv matni bo‘yicha...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      value: _categoryFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Toifa',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Barcha toifalar'),
                        ),
                        ..._categories.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _categoryFilter = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      value: _stateFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Emotsional holat',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Barcha holatlar'),
                        ),
                        ..._emotionalStates.map(
                          (st) => DropdownMenuItem(value: st, child: Text(st)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _stateFilter = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // KUZATUVLAR LISTI
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.notes_rounded, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'Kuzatuvlar topilmadi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Yangi kuzatuv qaydini kiritish uchun yuqoridagi tugmadan foydalaning',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final o = filtered[i];

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    df.format(o.date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${o.studentName} (${o.studentGrade})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    o.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: o.emotionalState.contains('Barqaror')
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                o.emotionalState,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: o.emotionalState.contains('Barqaror')
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (o.triggerOrContext != null &&
                            o.triggerOrContext!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Vaziyat: ${o.triggerOrContext}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          o.observationText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        if (o.recommendationOrAction != null &&
                            o.recommendationOrAction!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF059669),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tavsiya/Chora: ${o.recommendationOrAction}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF065F46),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
