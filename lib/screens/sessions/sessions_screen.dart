import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/session_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../students/student_detail_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  String _filter = 'Barchasi';

  static const List<String> _filters = [
    'Barchasi',
    'Rejalashtirilgan',
    'Bajarildi',
    'Qatnashmadi',
    'Bekor qilindi',
  ];

  void _showAddSessionDialog(BuildContext context) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final students = app.students;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDlgState) => AlertDialog(
                  title: const Text('Yangi mashg‘ulot rejalashtirish'),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedStdId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'O‘quvchini tanlang *',
                            ),
                            items:
                                students
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(
                                          '${s.fullName} (${s.grade})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setDlgState(() => selectedStdId = v!),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: topicCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Mashg‘ulot mavzusi *',
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: sessionType,
                            isExpanded: true,
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
                            onChanged:
                                (v) => setDlgState(() => sessionType = v!),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            initialValue: durationMinutes,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Davomiyligi',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 30,
                                child: Text('30 daqiqa'),
                              ),
                              DropdownMenuItem(
                                value: 45,
                                child: Text('45 daqiqa (Standart)'),
                              ),
                              DropdownMenuItem(
                                value: 60,
                                child: Text('60 daqiqa'),
                              ),
                            ],
                            onChanged:
                                (v) => setDlgState(() => durationMinutes = v!),
                          ),
                          const SizedBox(height: 14),
                          GlassWell(
                            borderRadius: 12,
                            padding: const EdgeInsets.all(14),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.calendarClock,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mashg‘ulot vaqti',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        Text(
                                          DateFormat(
                                            'dd.MM.yyyy HH:mm',
                                          ).format(scheduledDate),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            fontFeatures: [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                OutlinedButton(
                                  onPressed: () async {
                                    final pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: scheduledDate,
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 7),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 90),
                                      ),
                                    );
                                    if (pickedDate != null && ctx.mounted) {
                                      final pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(
                                          scheduledDate,
                                        ),
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
                                  child: const Text('Tanlash'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: activitiesCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Rejalashtirilgan mashqlar va maqsad',
                              hintText:
                                  'Masalan: Artikulyatsion mashqlar, kartalar bilan ishlash...',
                            ),
                          ),
                        ],
                      ),
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
                            SnackBar(
                              content: Text(
                                'Iltimos, mashg‘ulot mavzusini kiriting!',
                              ),
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

                        final result = await app.addSession(
                          newSession,
                          byUser: user,
                        );
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
                              SnackBar(
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

  void _showCompleteSessionDialog(BuildContext context, SessionModel session) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final observationsCtrl = TextEditingController();
    final nextStepsCtrl = TextEditingController();
    bool attendanceConfirmed = true;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDlgState) => AlertDialog(
                  title: Text('${session.studentName} — Natijani qayd etish'),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mavzu: ${session.topic}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: attendanceConfirmed,
                            title: const Text(
                              'O‘quvchi mashg‘ulotda to‘liq qatnashdi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onChanged:
                                (v) => setDlgState(
                                  () => attendanceConfirmed = v ?? true,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: observationsCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText:
                                  'Mutaxassis kuzatuvi va dars natijasi *',
                              hintText:
                                  'Bola topshiriqni qanday bajardi? Qanday yutuqlar bo‘ldi?',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: nextStepsCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Keyingi tavsiya / Uyga vazifa',
                              hintText:
                                  'Ota-ona yoki sinf rahbariga tavsiya...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Bekor qilish'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      onPressed: () async {
                        if (observationsCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
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
                          nextSteps:
                              nextStepsCtrl.text.trim().isNotEmpty
                                  ? nextStepsCtrl.text.trim()
                                  : null,
                          byUser: user,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Mashg‘ulot yakunlandi va natijalar saqlandi!',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      child: const Text('Tasdiqlash va saqlash'),
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
    final canPop = Navigator.canPop(context);

    final filtered =
        _filter == 'Barchasi'
            ? allSessions
            : allSessions.where((s) => s.status == _filter).toList();

    final counts = <String, int>{
      'Barchasi': allSessions.length,
      for (final f in _filters.skip(1))
        f: allSessions.where((s) => s.status == f).length,
    };
    final width = MediaQuery.sizeOf(context).width;
    final mediaPadding = MediaQuery.paddingOf(context);

    final pageBody = ResponsivePageContainer(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptivePageHeader(
            title: 'Mashg‘ulotlar jadvali',
            icon: LucideIcons.calendar,
            subtitle:
                'Jami ${filtered.length} ta rejalashtirilgan va o‘tilgan dars',
            action: HeaderActionButton(
              icon: LucideIcons.calendarPlus,
              label: 'Rejalashtirish',
              onPressed: () => _showAddSessionDialog(context),
            ),
          ),
          const SizedBox(height: 9),

          ModernPillFilterBar(
            items: _filters,
            selectedItem: _filter,
            counts: counts,
            onSelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 9),

          Expanded(
            child:
                filtered.isEmpty
                    ? Center(
                      child: SurfaceCard(
                        borderRadius: 26,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 36,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.calendarX,
                              size: 34,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Mashg‘ulotlar topilmadi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Boshqa holat filtrini tanlang yoki yangi dars rejalashtiring.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        0,
                        0,
                        width < 920 ? (84.0 + mediaPadding.bottom) : 24.0,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        final isDone = s.status == 'Bajarildi';
                        final isAbsent = s.status == 'Qatnashmadi';
                        final isCancelled = s.status == 'Bekor qilindi';
                        final accent =
                            isDone
                                ? AppColors.success
                                : (isAbsent || isCancelled
                                    ? AppColors.error
                                    : AppColors.primary);
                        final accentBg =
                            isDone
                                ? AppColors.successBg
                                : (isAbsent || isCancelled
                                    ? AppColors.errorBg
                                    : AppColors.primaryLight);
                        final df = DateFormat('dd.MM.yyyy HH:mm');

                        return SurfaceCard(
                          borderRadius: 26,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 20,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => StudentDetailScreen(
                                      studentId: s.studentId,
                                    ),
                              ),
                            );
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isVeryNarrow = constraints.maxWidth < 360;

                              final statusBadge = StatusPill(
                                label: s.status,
                                color: accent,
                                backgroundColor: accentBg,
                                showDot: true,
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.topic,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15.5,
                                                color: AppColors.textPrimary,
                                                letterSpacing: -0.25,
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${s.studentName} • ${s.specialistName}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w600,
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${s.sessionType} • ${df.format(s.scheduledAt)} (${s.durationMinutes} daqiqa)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                                fontFeatures: [
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      statusBadge,
                                    ],
                                  ),
                                  if (s.observations != null &&
                                      s.observations!.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    GlassWell(
                                      borderRadius: 12,
                                      padding: const EdgeInsets.all(15),
                                      child: Text(
                                        'Kuzatuv: ${s.observations}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (!isDone && !isAbsent && !isCancelled) ...[
                                    const SizedBox(height: 16),
                                    if (isVeryNarrow)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.success,
                                              minimumSize: const Size(0, 42),
                                            ),
                                            icon: const Icon(
                                              LucideIcons.check,
                                              size: 16,
                                            ),
                                            label: const Text('Bajarildi'),
                                            onPressed:
                                                () =>
                                                    _showCompleteSessionDialog(
                                                      context,
                                                      s,
                                                    ),
                                          ),
                                          const SizedBox(height: 10),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.error,
                                              backgroundColor:
                                                  AppColors.surface,
                                              side: BorderSide(
                                                color: AppColors.errorBorder,
                                                width: 1.0,
                                              ),
                                              minimumSize: const Size(0, 42),
                                            ),
                                            icon: const Icon(
                                              LucideIcons.userX,
                                              size: 16,
                                            ),
                                            label: const Text('Qatnashmadi'),
                                            onPressed: () {
                                              app.updateSessionStatus(
                                                s.id,
                                                'Qatnashmadi',
                                                notes: 'Mashg‘ulotga kelmadi.',
                                              );
                                            },
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.icon(
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.success,
                                                minimumSize: const Size(0, 42),
                                              ),
                                              icon: const Icon(
                                                LucideIcons.check,
                                                size: 16,
                                              ),
                                              label: const Text('Bajarildi'),
                                              onPressed:
                                                  () =>
                                                      _showCompleteSessionDialog(
                                                        context,
                                                        s,
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.error,
                                                backgroundColor:
                                                    AppColors.surface,
                                                side: BorderSide(
                                                  color: AppColors.errorBorder,
                                                  width: 1.0,
                                                ),
                                                minimumSize: const Size(0, 42),
                                              ),
                                              icon: const Icon(
                                                LucideIcons.userX,
                                                size: 16,
                                              ),
                                              label: const Text('Qatnashmadi'),
                                              onPressed: () {
                                                app.updateSessionStatus(
                                                  s.id,
                                                  'Qatnashmadi',
                                                  notes:
                                                      'Mashg‘ulotga kelmadi.',
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Mashg‘ulotlar')) : null,
      body: canPop ? AmbientMeshBackground(child: pageBody) : pageBody,
    );
  }
}
