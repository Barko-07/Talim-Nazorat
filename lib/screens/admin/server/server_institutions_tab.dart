import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/admin_api.dart';
import '../../../services/api_client.dart';

/// Server rejimidagi "Muassasalar": maktablar ro'yxati va har biridagi
/// tasdiqlangan hisoblar soni, yangi muassasa qo'shish.
class ServerInstitutionsTab extends StatefulWidget {
  const ServerInstitutionsTab({super.key, this.api});

  final AdminApi? api;

  @override
  State<ServerInstitutionsTab> createState() => _ServerInstitutionsTabState();
}

class _ServerInstitutionsTabState extends State<ServerInstitutionsTab> {
  late final AdminApi _api = widget.api ?? AdminApi();
  List<Institution> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.institutions();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final region = TextEditingController(text: 'Namangan viloyati');
    final created = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Yangi muassasa'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nomi',
                      hintText: '14-sonli umumiy o‘rta ta’lim maktabi',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: region,
                    decoration: const InputDecoration(labelText: 'Hudud'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Bekor qilish'),
              ),
              FilledButton(
                onPressed: () async {
                  if (name.text.trim().length < 3) return;
                  try {
                    await _api.createInstitution(
                      name.text.trim(),
                      region: region.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } on ApiException catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(e.message),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Qo‘shish'),
              ),
            ],
          ),
    );
    name.dispose();
    region.dispose();
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muassasalar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loading ? 'Yuklanmoqda…' : '${_items.length} ta muassasa',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _add,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Yangi muassasa'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text(
                  'Ro‘yxat yuklanmadi: $_error',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: _load,
                  child: const Text('Qayta urinish'),
                ),
              ],
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            Text(
              'Hali muassasa qo‘shilmagan. Ro‘yxatdan o‘tganlarni tasdiqlash uchun avval maktab qo‘shing.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _items.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: AppColors.borderLight),
                    ListTile(
                      leading: Icon(
                        LucideIcons.school,
                        color: AppColors.textSecondary,
                      ),
                      title: Text(
                        _items[i].name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        _items[i].region.isEmpty ? '—' : _items[i].region,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      trailing: Text(
                        '${_items[i].users} ta hisob',
                        style: TextStyle(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
