import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/monitoring_alert_model.dart';
import '../../providers/app_provider.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  bool _showOnlyUnresolved = true;

  void _showResolveDialog(BuildContext context, MonitoringAlertModel alert) {
    final notesCtrl = TextEditingController(
      text: 'Chora ko‘rildi: mutaxassislar konsiliumi chaqirildi va reja moslashtirildi.',
    );
    String selectedStatus = 'Hal qilindi';
    final app = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text(
              'Signalni ko‘rib chiqish va holatini yangilash',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'O‘quvchi: ${alert.studentName} (${alert.studentGrade})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '[${alert.ruleCode}] ${alert.ruleTitle}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Yangi holati *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Ko‘rib chiqilmoqda',
                      child: Text('Ko‘rib chiqilmoqda'),
                    ),
                    DropdownMenuItem(
                      value: 'Hal qilindi',
                      child: Text('Hal qilindi (Yopish)'),
                    ),
                    DropdownMenuItem(
                      value: 'Rad etildi',
                      child: Text('Rad etildi (Asossiz deb topildi)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Qabul qilingan chora va xulosalar *',
                    hintText: 'Ushbu muammo bo‘yicha qanday pedagogik qaror qabul qilindi...',
                    border: OutlineInputBorder(),
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
                onPressed: () async {
                  await app.resolveAlert(alert.id, notesCtrl.text.trim());
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Signal muvaffaqiyatli saqlandi.'),
                      ),
                    );
                  }
                },
                child: const Text('Saqlash'),
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
    final alerts = app.getAlerts(onlyUnresolved: _showOnlyUnresolved);
    final unresolvedCount = app.unresolvedAlerts.length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                    const Text(
                      'Avtomatlashtirilgan Monitoring Tizimi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rivojlanishdagi xavfli tendensiyalarni erta aniqlash va bartaraf etish',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    FilterChip(
                      label: Text(
                        'Faqat ochiqlar ($unresolvedCount)',
                        style: TextStyle(
                          fontSize: 12,
                          color: _showOnlyUnresolved
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      selected: _showOnlyUnresolved,
                      selectedColor: AppColors.primary,
                      onSelected: (v) =>
                          setState(() => _showOnlyUnresolved = v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 6 TA DOIMIY MONITORING QOIDALARI BLOKI
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '6 ta doimiy ishlovchi avtomatik nazorat qoidasi (DB ma’lumotlari asosida):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      'Qoida 1',
                      'O‘tkazib yuborilgan mashg‘ulotlar',
                      'Ketma-ket 2+ marta qoldirilgan yoki bekor qilingan darslar',
                    ),
                    _buildRuleItem(
                      'Qoida 2',
                      'Kechikkan davriy baholashlar',
                      'Davriy nazorat muddati 60 kundan oshib ketganda',
                    ),
                    _buildRuleItem(
                      'Qoida 3',
                      'Rivojlanish turg‘unligi (Stagnatsiya)',
                      'Oxirgi 3 ta qiyosiy baholashda siljish bo‘lmasa (0 ball o‘sish)',
                    ),
                    _buildRuleItem(
                      'Qoida 4',
                      'Ko‘rsatkichlarning pasayishi (Regressiya)',
                      'O‘xshash mezonlar bo‘yicha >15% ko‘rsatkich pasayishi',
                    ),
                    _buildRuleItem(
                      'Qoida 5',
                      'Muddati o‘tgan ITR maqsadlari',
                      'Belgilangan muddatda bajarilmagan individual ta’limiy maqsadlar',
                    ),
                    _buildRuleItem(
                      'Qoida 6',
                      'Dars kuzatuv xulosasi kiritilmaganligi',
                      'Bajarilgan mashg‘ulotda professional pedagogik kuzatuv qayd etilmagan',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SIGNALLAR RO'YXATI
            Text(
              'Aniqlangan monitoring signallari (${alerts.length} ta):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),

            if (alerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Hozirda monitoring signallari mavjud emas. Barcha ko‘rsatkichlar me’yorda.',
                  ),
                ),
              )
            else
              ...alerts.map((alt) => _buildAlertCard(context, alt)),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String code, String title, String condition) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Text(' — ', style: TextStyle(color: AppColors.textMuted)),
          Expanded(
            child: Text(
              condition,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, MonitoringAlertModel alt) {
    final isDanger = alt.severity == 'XAVF';
    final df = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDanger ? AppColors.error : AppColors.warning,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDanger
                            ? AppColors.errorBg
                            : AppColors.warningBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alt.severity,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDanger ? AppColors.error : AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '[${alt.ruleCode}] ${alt.ruleTitle}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  df.format(alt.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'O‘quvchi: ${alt.studentName} (${alt.studentGrade})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (alt.responsiblePersonName != null)
                  Text(
                    'Mas’ul: ${alt.responsiblePersonName!}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              alt.message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tavsiya: ${alt.suggestedAction}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: alt.isResolved
                        ? AppColors.successBg
                        : AppColors.infoBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Holati: ${alt.status}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: alt.isResolved
                          ? AppColors.success
                          : AppColors.info,
                    ),
                  ),
                ),
                if (!alt.isResolved)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text(
                      'Ko‘rib chiqish va yechim kiritish',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _showResolveDialog(context, alt),
                  ),
              ],
            ),
            if (alt.resolvedNotes != null && alt.resolvedNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Yechim bayonnomasi: ${alt.resolvedNotes!}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
