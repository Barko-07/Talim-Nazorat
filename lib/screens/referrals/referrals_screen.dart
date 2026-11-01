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
                    isExpanded: true,
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
    final width = MediaQuery.sizeOf(context).width;
    final mediaPadding = MediaQuery.paddingOf(context);

    final pageBody = ResponsivePageContainer(
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdaptivePageHeader(
            title: 'Yo‘naltirishlar',
            subtitle:
                'Konsilium va PMPK yo‘llanmalari • ${referrals.length} ta',
            action: HeaderActionButton(
              icon: LucideIcons.plus,
              label: 'Yangi yo‘naltirish',
              onPressed: () => _showAddReferralDialog(context),
            ),
          ),
          const SizedBox(height: 12),

          ModernPillFilterBar(
            items: _statuses,
            selectedItem: _statusFilter,
            counts: counts,
            onSelected: (val) => setState(() => _statusFilter = val),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: referrals.isEmpty
                ? Center(
                    child: SurfaceCard(
                      borderRadius: 22,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 36,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.arrowLeftRight,
                            size: 34,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Ushbu holatda yo‘naltirishlar mavjud emas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Boshqa holat filtrini tanlang yoki yangi yo‘naltirish yarating.',
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
                    itemCount: referrals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ref = referrals[index];
                      final isUrgent = ref.priority == 'Shoshilinch';
                      final isCompleted = ref.status == 'Yakunlandi';

                      return SurfaceCard(
                        borderRadius: 22,
                        padding: const EdgeInsets.all(20),
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
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
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
                                  Text(
                                    df.format(ref.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    LucideIcons.arrowUpRight,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    ref.toSpecialistType,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.5,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.25,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            GlassWell(
                              borderRadius: 12,
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'O‘quvchi: ${ref.studentName}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Sababi: ${ref.reason}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                  if (ref.supportingObservations != null &&
                                      ref.supportingObservations!
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Kuzatuvlar: ${ref.supportingObservations}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.userCheck,
                                  size: 14.5,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Yuborgan: ${ref.fromSpecialistName} (${ref.fromSpecialistRole ?? 'Mutaxassis'})',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (ref.outcomeNotes != null &&
                                ref.outcomeNotes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              GlassWell(
                                borderRadius: 12,
                                padding: const EdgeInsets.all(13),
                                tintColor: AppColors.successBg,
                                borderColor: AppColors.successBorder,
                                child: Text(
                                  'Yakuniy xulosa: ${ref.outcomeNotes}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
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
                                            minimumSize: const Size(0, 38),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
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
                                            style: TextStyle(fontSize: 12.5),
                                          ),
                                        ),
                                      ],
                                      if (ref.status == 'Qabul qilindi') ...[
                                        FilledButton.tonal(
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size(0, 38),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
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
                                            style: TextStyle(fontSize: 12.5),
                                          ),
                                        ),
                                      ],
                                      if (ref.status == 'Jarayonda') ...[
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            minimumSize: const Size(0, 38),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () =>
                                              _showCompleteReferralDialog(
                                            context,
                                            ref,
                                          ),
                                          child: const Text(
                                            'Yakunlash',
                                            style: TextStyle(fontSize: 12.5),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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
      appBar: canPop ? AppBar(title: const Text('Yo‘naltirishlar')) : null,
      body: canPop ? AmbientMeshBackground(child: pageBody) : pageBody,
    );
  }
}
