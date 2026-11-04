import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/monitoring_alert_model.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/auth_provider.dart';

class AdminMonitoringTab extends StatefulWidget {
  const AdminMonitoringTab({super.key});

  @override
  State<AdminMonitoringTab> createState() => _AdminMonitoringTabState();
}

class _AdminMonitoringTabState extends State<AdminMonitoringTab> {
  String? _filterSeverity;
  bool? _filterResolved = false; // Odatiy holda faqat ochiqlarini ko'rsatish

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final allAlerts = app.alerts;
    final df = DateFormat('dd.MM.yyyy HH:mm');

    final filtered = allAlerts.where((a) {
      if (_filterSeverity != null && a.severity != _filterSeverity) {
        return false;
      }
      if (_filterResolved != null && a.isResolved != _filterResolved) {
        return false;
      }
      return true;
    }).toList();

    final highCount = allAlerts.where((a) => a.severity == 'XAVF' && !a.isResolved).length;
    final mediumCount = allAlerts.where((a) => a.severity == 'DIQQAT' && !a.isResolved).length;
    final lowCount = allAlerts.where((a) => a.severity == 'MA’LUMOT' && !a.isResolved).length;
    final resolvedCount = allAlerts.where((a) => a.isResolved).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Avtomatlashtirilgan Monitoring Tizimi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: highCount > 0
                              ? AppColors.errorBg
                              : AppColors.successBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: highCount > 0
                                ? AppColors.error.withValues(alpha: 0.3)
                                : AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          highCount > 0
                              ? '$highCount ta yuqori xavf'
                              : 'Tizim xatarsiz',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: highCount > 0
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '6 ta rasmiy pedagogik-metodik qoida bo‘yicha jarayonlar, qoldirilgan darslar va orqada qolish signallari',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. MONITORING STATISTIKASI
          Row(
            children: [
              Expanded(
                child: _buildSeverityBox(
                  title: 'YUQORI XAVF (CRITICAL)',
                  count: highCount,
                  color: AppColors.error,
                  bgColor: AppColors.errorBg,
                  active: _filterSeverity == 'XAVF',
                  onTap: () {
                    setState(() {
                      _filterSeverity =
                          _filterSeverity == 'XAVF' ? null : 'XAVF';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSeverityBox(
                  title: 'DIQQAT TALAB (MEDIUM)',
                  count: mediumCount,
                  color: AppColors.warning,
                  bgColor: AppColors.warningBg,
                  active: _filterSeverity == 'DIQQAT',
                  onTap: () {
                    setState(() {
                      _filterSeverity =
                          _filterSeverity == 'DIQQAT' ? null : 'DIQQAT';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSeverityBox(
                  title: 'MA’LUMOT UCHUN (LOW)',
                  count: lowCount,
                  color: AppColors.info,
                  bgColor: AppColors.infoBg,
                  active: _filterSeverity == 'MA’LUMOT',
                  onTap: () {
                    setState(() {
                      _filterSeverity =
                          _filterSeverity == 'MA’LUMOT' ? null : 'MA’LUMOT';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSeverityBox(
                  title: 'BARTARAF ETILGAN',
                  count: resolvedCount,
                  color: AppColors.success,
                  bgColor: AppColors.successBg,
                  active: _filterResolved == true,
                  onTap: () {
                    setState(() {
                      _filterResolved =
                          _filterResolved == true ? null : true;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. SIGNALLAR RO'YXATI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: filtered.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 48,
                            color: AppColors.success,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tanlangan mezon bo‘yicha faol monitoring signallari mavjud emas',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final a = filtered[i];
                      final isHigh = a.severity == 'XAVF';
                      final isMed = a.severity == 'DIQQAT';
                      final color = isHigh
                          ? AppColors.error
                          : isMed
                              ? AppColors.warning
                              : AppColors.info;

                      return Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isHigh
                                    ? Icons.error_outline_rounded
                                    : Icons.warning_amber_rounded,
                                color: color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          a.severity,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        a.ruleTitle,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    a.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Tavsiya etilgan ma’muriy chora: ${a.suggestedAction}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '🧒 O‘quvchi: ${a.studentName} (${a.studentGrade}) • Aniqlangan vaqt: ${df.format(a.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  if (a.isResolved) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '✅ Hal qilindi: ${a.resolvedNotes ?? ''} (${a.resolvedAt != null ? df.format(a.resolvedAt!) : ''})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (!a.isResolved)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: AppColors.onPrimary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () {
                                  _showResolveAlertModal(context, a, currentUser);
                                },
                                child: const Text(
                                  'Chora ko‘rish / Hal etish',
                                  style: TextStyle(fontSize: 12),
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
  }

  Widget _buildSeverityBox({
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResolveAlertModal(
    BuildContext context,
    MonitoringAlertModel alert,
    dynamic currentUser,
  ) {
    final app = context.read<AppProvider>();
    final notesCtrl = TextEditingController(
      text: 'Pedagogik-korreksion konsilium o‘tkazildi va chora ko‘rildi.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monitoring signalini bartaraf etish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signal: ${alert.ruleTitle}\nO‘quvchi: ${alert.studentName}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ko‘rilgan ma’muriy chora va xulosa *',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () async {
              if (notesCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await app.resolveAlert(
                  alert.id,
                  notesCtrl.text.trim(),
                  byUser: currentUser,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Monitoring signali muvaffaqiyatli hal qilindi deb belgilandi.',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Tasdiqlash'),
          ),
        ],
      ),
    );
  }
}
