import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/referral_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  String _statusFilter = 'Barchasi';

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
          title: const Text(
            'Yangi Yo‘naltirish Yaratish',
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
                DropdownButtonFormField<String>(
                  value: toService,
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
                  value: priority,
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
                    hintText: 'Nima uchun ushbu mutaxassis ko‘rigi talab qilinmoqda...',
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
        title: Text(
          '${referral.studentName} — Xulosa va Natija',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yo‘naltirish: ${referral.toSpecialistType}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Sabab: ${referral.reason}',
              style: const TextStyle(
                fontSize: 12,
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

    final referrals = _statusFilter == 'Barchasi'
        ? allReferrals
        : allReferrals.where((r) => r.status == _statusFilter).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yo‘naltirishlar va Konsilium',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mutaxassislararo hamkorlik, shifokor va PMPK komissiyasiga yo‘naltirishlar (${referrals.length} ta)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yangi yo‘naltirish'),
                  onPressed: () => _showAddReferralDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Holat filtri
            Row(
              children:
                  [
                    'Barchasi',
                    'Yuborildi',
                    'Qabul qilindi',
                    'Jarayonda',
                    'Yakunlandi',
                  ].map((st) {
                    final isSel = _statusFilter == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(
                          st,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSel
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        onSelected: (val) => setState(() => _statusFilter = st),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: referrals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.alt_route_rounded,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Ushbu holatda yo‘naltirishlar mavjud emas',
                            style: TextStyle(fontWeight: FontWeight.w600),
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

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isUrgent
                                                ? AppColors.errorBg
                                                : AppColors.infoBg,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            ref.priority,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isUrgent
                                                  ? AppColors.error
                                                  : AppColors.info,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ref.toSpecialistType,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      df.format(ref.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'O‘quvchi: ${ref.studentName}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sababi: ${ref.reason}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (ref.supportingObservations != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kuzatuvlar: ${ref.supportingObservations}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'Yuborgan: ${ref.fromSpecialistName} (${ref.fromSpecialistRole ?? 'Mutaxassis'})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                if (ref.outcomeNotes != null &&
                                    ref.outcomeNotes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Yakuniy xulosa: ${ref.outcomeNotes}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? AppColors.successBg
                                            : AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Holat: ${ref.status}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isCompleted
                                              ? AppColors.success
                                              : AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        if (ref.status == 'Yuborildi' ||
                                            ref.status ==
                                                'Ko‘rib chiqilmoqda') ...[
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
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
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                        if (ref.status == 'Qabul qilindi') ...[
                                          FilledButton.tonal(
                                            style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
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
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                        if (ref.status == 'Jarayonda') ...[
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.success,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                            ),
                                            onPressed: () =>
                                                _showCompleteReferralDialog(
                                                  context,
                                                  ref,
                                                ),
                                            child: const Text(
                                              'Yakunlash',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
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
