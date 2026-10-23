import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/session_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  String _filter = 'Barchasi';

  void _showAddSessionDialog(BuildContext context) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final students = app.students;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hozircha birorta o‘quvchi mavjud emas.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    String selectedStdId = students.first.id;
    final topicCtrl = TextEditingController(
      text: 'Korreksion rivojlantiruvchi mashg‘ulot',
    );
    final activitiesCtrl = TextEditingController();
    String sessionType = 'Individual';
    int durationMinutes = 45;
    DateTime scheduledDate = DateTime.now().add(const Duration(hours: 2));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text(
            'Yangi Mashg‘ulot Rejalashtirish',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStdId,
                  decoration: const InputDecoration(
                    labelText: 'O‘quvchini tanlang *',
                  ),
                  items: students
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.fullName} (${s.grade})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDlgState(() => selectedStdId = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mashg‘ulot mavzusi *',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sessionType,
                  decoration: const InputDecoration(
                    labelText: 'Mashg‘ulot shakli',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Individual',
                      child: Text('Individual'),
                    ),
                    DropdownMenuItem(
                      value: 'Kichik guruhda',
                      child: Text('Kichik guruhda (2-4 bola)'),
                    ),
                  ],
                  onChanged: (v) => setDlgState(() => sessionType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: durationMinutes,
                  decoration: const InputDecoration(labelText: 'Davomiyligi'),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 daqiqa')),
                    DropdownMenuItem(
                      value: 45,
                      child: Text('45 daqiqa (Standart)'),
                    ),
                    DropdownMenuItem(value: 60, child: Text('60 daqiqa')),
                  ],
                  onChanged: (v) => setDlgState(() => durationMinutes = v!),
                ),
                const SizedBox(height: 12),
                // Sana va vaqt
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Mashg‘ulot vaqti',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  subtitle: Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(scheduledDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: scheduledDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 7),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (pickedDate != null && ctx.mounted) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(scheduledDate),
                        );
                        if (pickedTime != null) {
                          setDlgState(() {
                            scheduledDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: const Text('O‘zgartirish'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: activitiesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Rejalashtirilgan mashqlar va maqsad',
                    hintText: 'Masalan: Artikulyatsion mashqlar, kartalar bilan ishlash...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () async {
                if (topicCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Iltimos, mashg‘ulot mavzusini kiriting!'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final student = students.firstWhere(
                  (s) => s.id == selectedStdId,
                );
                final newSession = SessionModel(
                  id: 'ses_${const Uuid().v4().substring(0, 8)}',
                  studentId: student.id,
                  studentName: student.fullName,
                  specialistId: user?.id ?? 'user_spec',
                  specialistName: user?.fullName ?? 'Mutaxassis',
                  specialistRole: user?.role.label ?? 'Mutaxassis',
                  scheduledAt: scheduledDate,
                  durationMinutes: durationMinutes,
                  sessionType: sessionType,
                  status: 'Rejalashtirilgan',
                  topic: topicCtrl.text.trim(),
                  activities: activitiesCtrl.text.trim(),
                );

                final result = await app.addSession(newSession, byUser: user);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (result['success'] == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] as String),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Mashg‘ulot muvaffaqiyatli rejalashtirildi!',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Rejalashtirish'),
            ),
          ],
        ),
      ),
    );
  }

  /// Mashg'ulotni bajarilgan deb rasmiylashtirish dialogi (Kuzatuv xulosasi va davomat bilan)
  void _showCompleteSessionDialog(BuildContext context, SessionModel session) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final observationsCtrl = TextEditingController();
    final nextStepsCtrl = TextEditingController();
    bool attendanceConfirmed = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(
            '${session.studentName} — Natijani qayd etish',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mavzu: ${session.topic}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: attendanceConfirmed,
                  title: const Text(
                    'O‘quvchi mashg‘ulotda to‘liq qatnashdi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  onChanged: (v) =>
                      setDlgState(() => attendanceConfirmed = v ?? true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: observationsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mutaxassis kuzatuvi va dars natijasi *',
                    hintText: 'Bola topshiriqni qanday bajardi? Qanday qiyinchilik yoki yutuqlar bo‘ldi?',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nextStepsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Keyingi tavsiya etilgan harakat / Uyga vazifa',
                    hintText: 'Ota-ona yoki sinf rahbariga tavsiya...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () async {
                if (observationsCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Iltimos, mashg‘ulot bo‘yicha professional kuzatuv xulosangizni yozing!',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                await app.completeSession(
                  session.id,
                  observations: observationsCtrl.text.trim(),
                  nextSteps: nextStepsCtrl.text.trim().isNotEmpty
                      ? nextStepsCtrl.text.trim()
                      : null,
                  byUser: user,
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mashg‘ulot yakunlandi va natijalar saqlandi!',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Tasdiqlash va Saqlash'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allSessions = app.sessions;

    final filtered = _filter == 'Barchasi'
        ? allSessions
        : allSessions.where((s) => s.status == _filter).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Sarlavha va Qo'shish tugmasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mashg‘ulotlar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Jami ${filtered.length} ta korreksion dars',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Rejalashtirish',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _showAddSessionDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Holat filtri (Scrollable Chips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'Barchasi',
                  'Bajarildi',
                  'Rejalashtirilgan',
                  'Qatnashmadi',
                  'Bekor qilindi',
                ].map((f) {
                  final isSel = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      label: Text(
                        f,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSel ? AppColors.primary : AppColors.border,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (val) => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Ro'yxat
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Mashg‘ulotlar topilmadi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        final isDone = s.status == 'Bajarildi';
                        final isAbsent = s.status == 'Qatnashmadi';
                        final df = DateFormat('dd.MM.yyyy HH:mm');

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border, width: 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? AppColors.successBg
                                            : (isAbsent ? AppColors.errorBg : AppColors.primaryLight),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isDone
                                            ? Icons.check_circle_rounded
                                            : (isAbsent ? Icons.cancel_rounded : Icons.schedule_rounded),
                                        color: isDone
                                            ? AppColors.success
                                            : (isAbsent ? AppColors.error : AppColors.primary),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  s.topic,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isDone
                                                      ? AppColors.successBg
                                                      : (isAbsent ? AppColors.errorBg : AppColors.primaryLight),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isDone
                                                        ? AppColors.successBorder
                                                        : (isAbsent ? AppColors.errorBorder : AppColors.primaryTint),
                                                  ),
                                                ),
                                                child: Text(
                                                  s.status,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDone
                                                        ? AppColors.success
                                                        : (isAbsent ? AppColors.error : AppColors.primary),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'O‘quvchi: ${s.studentName} • ${s.specialistName}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${s.sessionType} • ${df.format(s.scheduledAt)} (${s.durationMinutes} daq)',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (s.observations != null && s.observations!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                      border: const Border(
                                        left: BorderSide(color: AppColors.primary, width: 2.5),
                                      ),
                                    ),
                                    child: Text(
                                      'Kuzatuv: ${s.observations}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                                if (!isDone && !isAbsent) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.check_rounded, size: 15),
                                          label: const Text(
                                            'Bajarildi',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () => _showCompleteSessionDialog(context, s),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            side: const BorderSide(color: AppColors.errorBorder),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.close_rounded, size: 15),
                                          label: const Text(
                                            'Qatnashmadi',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () {
                                            app.updateSessionStatus(
                                              s.id,
                                              'Qatnashmadi',
                                              notes: 'Mashg‘ulotga kelmadi.',
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
