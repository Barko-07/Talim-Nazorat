import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/referral_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../students/student_detail_screen.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  String _statusFilter = 'Barchasi';

  static const List<String> _statuses = [
    'Barchasi',
    'Yuborildi',
    'Qabul qilindi',
    'Jarayonda',
    'Yakunlandi',
  ];

  void _showAddReferralDialog(BuildContext context) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final students = app.students;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yo‘naltirish uchun o‘quvchilar mavjud emas.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    String selectedStdId = students.first.id;
    String toService = 'Amaliyotchi psixolog';
    String priority = 'Rejali';
    final reasonCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Yangi yo‘naltirish yaratish'),
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
                    items: students
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
                    onChanged: (v) => setDlgState(() => selectedStdId = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: toService,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Qaysi mutaxassis / xizmatga *',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Amaliyotchi psixolog',
                        child: Text('Amaliyotchi psixolog'),
                      ),
                      DropdownMenuItem(
                        value: 'Logoped-defektolog',
                        child: Text('Logoped-defektolog'),
                      ),
                      DropdownMenuItem(
                        value: 'Maxsus pedagog (Defektolog)',
                        child: Text('Maxsus pedagog (Defektolog)'),
                      ),
                      DropdownMenuItem(
                        value: 'Tibbiy PMPK komissiyasi',
                        child: Text(
                          'Tibbiy-psixologik-pedagogik komissiya (PMPK)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Shifokor-pediatr',
                        child: Text('Shifokor-pediatr / Poliklinika'),
                      ),
                    ],
                    onChanged: (v) => setDlgState(() => toService = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Muhimlik darajasi',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Rejali',
                        child: Text('Rejali (Reja asosida ko‘rik)'),
                      ),
                      DropdownMenuItem(
                        value: 'Shoshilinch',
                        child: Text('Shoshilinch (Zudlik bilan)'),
                      ),
                      DropdownMenuItem(
                        value: 'Konsultatsiya',
                        child: Text('Konsultatsiya (Qisqa tavsiya)'),
                      ),
                    ],
                    onChanged: (v) => setDlgState(() => priority = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Yo‘naltirish sababi va zarurati *',
                      hintText:
                          'Nima uchun ushbu mutaxassis ko‘rigi talab qilinmoqda...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: obsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Sinfdagi kuzatuvlar va dalillar',
                      hintText:
                          'Qanday belgilar yoki qiyinchiliklar qayd etildi...',
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
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Iltimos, yo‘naltirish sababini yozing!'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final student = students.firstWhere(
                  (s) => s.id == selectedStdId,
                );
                final newRef = ReferralModel(
                  id: 'ref_${const Uuid().v4().substring(0, 8)}',
                  studentId: student.id,
                  studentName: student.fullName,
                  fromSpecialistId: user?.id ?? 'user_spec',
                  fromSpecialistName: user?.fullName ?? 'Mutaxassis',
                  fromSpecialistRole: user?.role.label ?? 'Mutaxassis',
                  toSpecialistType: toService,
                  reason: reasonCtrl.text.trim(),
                  supportingObservations: obsCtrl.text.trim().isNotEmpty
                      ? obsCtrl.text.trim()
                      : null,
                  priority: priority,
                  status: 'Yuborildi',
                  createdAt: DateTime.now(),
                );

                await app.addReferral(newRef, byUser: user);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Yo‘naltirish muvaffaqiyatli jo‘natildi!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Yuborish'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteReferralDialog(
    BuildContext context,
    ReferralModel referral,
  ) {
    final app = context.read<AppProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final outcomeCtrl = TextEditingController();
    final followUpCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${referral.studentName} — Xulosa va natija'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yo‘naltirish: ${referral.toSpecialistType}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sabab: ${referral.reason}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: outcomeCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'O‘tkazilgan ko‘rik va mutaxassis xulosasi *',
                    hintText: 'Tekshiruv natijasida nimalar aniqlandi...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: followUpCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tavsiya etilgan keyingi chora-tadbirlar',
                    hintText: 'Masalan: ITR ga 2 ta nutqiy maqsad qo‘shish...',
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              if (outcomeCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Iltimos, tekshiruv xulosasini kiriting!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              await app.updateReferralStatus(
                referral.id,
                'Yakunlandi',
                outcomeNotes: outcomeCtrl.text.trim(),
                followUpAction: followUpCtrl.text.trim().isNotEmpty
                    ? followUpCtrl.text.trim()
                    : null,
                byUser: user,
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yo‘naltirish muvaffaqiyatli yakunlandi!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Yakunlash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allReferrals = app.referrals;
    final df = DateFormat('dd.MM.yyyy');
    final canPop = Navigator.canPop(context);

    final referrals = _statusFilter == 'Barchasi'
        ? allReferrals
        : allReferrals.where((r) => r.status == _statusFilter).toList();

    final counts = <String, int>{
      'Barchasi': allReferrals.length,
      for (final st in _statuses.skip(1))
        st: allReferrals.where((r) => r.status == st).length,
    };

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Yo‘naltirishlar')) : null,
      body: ResponsivePageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              icon: LucideIcons.arrowLeftRight,
              title: 'Yo‘naltirishlar va konsilium',
              subtitle:
                  'Mutaxassislararo hamkorlik va PMPK komissiyasiga yo‘naltirishlar (${referrals.length} ta)',
              action: FilledButton.icon(
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Yangi yo‘naltirish'),
                onPressed: () => _showAddReferralDialog(context),
              ),
            ),
            const SizedBox(height: 16),

            // Skroll bo'ladigan filtr qatori (iPhone'da 0% overflow!)
            ModernPillFilterBar(
              items: _statuses,
              selectedItem: _statusFilter,
              counts: counts,
              onSelected: (val) => setState(() => _statusFilter = val),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: referrals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.hairlineBorder),
                            ),
                            child: const Icon(
                              LucideIcons.arrowLeftRight,
                              size: 26,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Ushbu holatda yo‘naltirishlar mavjud emas',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: referrals.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ref = referrals[index];
                        final isUrgent = ref.priority == 'Shoshilinch';
                        final isCompleted = ref.status == 'Yakunlandi';

                        return SurfaceCard(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentDetailScreen(
                                  studentId: ref.studentId,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StatusPill(
                                    label: ref.priority,
                                    color: isUrgent
                                        ? AppColors.error
                                        : AppColors.info,
                                    backgroundColor: isUrgent
                                        ? AppColors.errorBg
                                        : AppColors.infoBg,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ref.toSpecialistType,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    df.format(ref.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'O‘quvchi: ${ref.studentName}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sababi: ${ref.reason}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              if (ref.supportingObservations != null &&
                                  ref.supportingObservations!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Kuzatuvlar: ${ref.supportingObservations}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                'Yuborgan: ${ref.fromSpecialistName} (${ref.fromSpecialistRole ?? 'Mutaxassis'})',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (ref.outcomeNotes != null &&
                                  ref.outcomeNotes!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.successBorder,
                                    ),
                                  ),
                                  child: Text(
                                    'Yakuniy xulosa: ${ref.outcomeNotes}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  StatusPill(
                                    label: 'Holat: ${ref.status}',
                                    color: isCompleted
                                        ? AppColors.success
                                        : AppColors.primary,
                                    backgroundColor: isCompleted
                                        ? AppColors.successBg
                                        : AppColors.primaryLight,
                                    showDot: true,
                                  ),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (ref.status == 'Yuborildi' ||
                                          ref.status ==
                                              'Ko‘rib chiqilmoqda') ...[
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 34),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                          ),
                                          onPressed: () {
                                            app.updateReferralStatus(
                                              ref.id,
                                              'Qabul qilindi',
                                            );
                                          },
                                          child: const Text(
                                            'Qabul qilish',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                      if (ref.status == 'Qabul qilindi') ...[
                                        FilledButton.tonal(
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size(0, 34),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                          ),
                                          onPressed: () {
                                            app.updateReferralStatus(
                                              ref.id,
                                              'Jarayonda',
                                            );
                                          },
                                          child: const Text(
                                            'Jarayonga o‘tkazish',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                      if (ref.status == 'Jarayonda') ...[
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            minimumSize: const Size(0, 34),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                          ),
                                          onPressed: () =>
                                              _showCompleteReferralDialog(
                                            context,
                                            ref,
                                          ),
                                          child: const Text(
                                            'Yakunlash',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ],
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
