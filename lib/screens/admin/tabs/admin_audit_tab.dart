import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/app_provider.dart';

class AdminAuditTab extends StatefulWidget {
  const AdminAuditTab({super.key});

  @override
  State<AdminAuditTab> createState() => _AdminAuditTabState();
}

class _AdminAuditTabState extends State<AdminAuditTab> {
  String _search = '';
  String? _filterAction;
  String? _filterEntity;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final allLogs = app.auditLogs;
    final df = DateFormat('dd.MM.yyyy HH:mm:ss');

    final filtered = allLogs.where((l) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final matchUser = l.userFullName.toLowerCase().contains(q);
        final matchDet = l.details.toLowerCase().contains(q);
        final matchEnt = l.entity.toLowerCase().contains(q);
        if (!matchUser && !matchDet && !matchEnt) return false;
      }
      if (_filterAction != null && l.action != _filterAction) return false;
      if (_filterEntity != null && l.entity != _filterEntity) return false;
      return true;
    }).toList();

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
                        'Tizim Davlat Audit Jurnali',
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
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${filtered.length} ta yozuv',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Barcha ma’muriy o‘zgarishlar, tizimga kirishlar, ma’lumotlarni tahrirlash va xavfsizlik hodisalari to‘liq qaydnomasi',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final csv = app.exportAuditLogsCsv();
                  _showExportPreview(context, csv);
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Audit Jurnalini CSV Yuklab Olish'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. FILTRLAR
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
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
                        hintText: 'Foydalanuvchi, amal yoki tafsilot bo‘yicha qidiruv...',
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
                      value: _filterAction,
                      decoration: InputDecoration(
                        labelText: 'Amal turi',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Barcha amallar'),
                        ),
                        DropdownMenuItem(
                          value: 'LOGIN',
                          child: Text('LOGIN (Tizimga kirish)'),
                        ),
                        DropdownMenuItem(
                          value: 'REGISTER',
                          child: Text('REGISTER (Ro‘yxatdan o‘tish)'),
                        ),
                        DropdownMenuItem(
                          value: 'CREATE',
                          child: Text('CREATE (Yaratish)'),
                        ),
                        DropdownMenuItem(
                          value: 'UPDATE',
                          child: Text('UPDATE (Tahrirlash)'),
                        ),
                        DropdownMenuItem(
                          value: 'ARCHIVE',
                          child: Text('ARCHIVE (Arxivlash)'),
                        ),
                        DropdownMenuItem(
                          value: 'DELETE',
                          child: Text('DELETE (O‘chirish)'),
                        ),
                        DropdownMenuItem(
                          value: 'PERMISSION_CHANGE',
                          child: Text('PERMISSION_CHANGE (Huquq)'),
                        ),
                        DropdownMenuItem(
                          value: 'RESOLVE',
                          child: Text('RESOLVE (Hal etish)'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterAction = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String?>(
                      value: _filterEntity,
                      decoration: InputDecoration(
                        labelText: 'Ob’ekt',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Barcha ob’ektlar'),
                        ),
                        DropdownMenuItem(value: 'User', child: Text('User')),
                        DropdownMenuItem(
                          value: 'Student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(
                          value: 'Assessment',
                          child: Text('Assessment'),
                        ),
                        DropdownMenuItem(
                          value: 'Session',
                          child: Text('Session'),
                        ),
                        DropdownMenuItem(value: 'IEP', child: Text('IEP')),
                        DropdownMenuItem(value: 'Alert', child: Text('Alert')),
                        DropdownMenuItem(
                          value: 'Referral',
                          child: Text('Referral'),
                        ),
                        DropdownMenuItem(value: 'Auth', child: Text('Auth')),
                      ],
                      onChanged: (v) => setState(() => _filterEntity = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. AUDIT JADVALI
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('Mos keluvchi audit yozuvlari topilmadi'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final l = filtered[i];
                      final isLogin = l.action == 'LOGIN';
                      final isCreate = l.action == 'CREATE' || l.action == 'REGISTER';
                      final isChange = l.action == 'PERMISSION_CHANGE' || l.action == 'ARCHIVE' || l.action == 'DELETE';

                      final badgeColor = isLogin
                          ? AppColors.info
                          : isCreate
                              ? AppColors.success
                              : isChange
                                  ? AppColors.error
                                  : AppColors.purple;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: badgeColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                l.action,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        l.userFullName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMuted,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          l.userRole,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    l.details,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                l.entity,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              df.format(l.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontFamily: 'monospace',
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

  void _showExportPreview(BuildContext context, String csv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Audit Jurnali CSV Eksporti'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Audit jurnali RFC 4180 formati hamda UTF-8 BOM bilan tayyorlandi. Dastlabki qatorlar ko‘rinishi:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  csv.split('\n').take(6).join('\n'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Yopish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Audit jurnali CSV fayli yuklab olindi.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Yuklab olish'),
          ),
        ],
      ),
    );
  }
}
