import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../services/admin_api.dart';
import '../../../services/api_client.dart';
import '../../../services/local_db_service.dart';

/// Server rejimidagi "Audit jurnali": ma'lumotlardagi har bir o'zgarish (kim,
/// qachon, nimani, eski va yangi qiymat) va xavfsizlik hodisalari.
class ServerHistoryTab extends StatefulWidget {
  const ServerHistoryTab({super.key, this.api});

  final AdminApi? api;

  @override
  State<ServerHistoryTab> createState() => _ServerHistoryTabState();
}

/// Maydon nomlari odam tilida. Ro'yxatda yo'q maydon o'z nomi bilan chiqadi.
const fieldLabels = {
  'team': 'Jamoa',
  'teamCoordinator': 'Koordinator',
  'firstName': 'Ism',
  'lastName': 'Familiya',
  'middleName': 'Otasining ismi',
  'birthDate': 'Tug‘ilgan sana',
  'full_name': 'F.I.Sh.',
  'first_name': 'Ism',
  'last_name': 'Familiya',
  'middle_name': 'Otasining ismi',
  'phone': 'Telefon',
  'specialization': 'Mutaxassislik',
  'qualification_category': 'Malaka toifasi',
  'experience_years': 'Ish staji',
  'region': 'Viloyat',
  'district': 'Tuman',
  'status': 'Holat',
  'notes': 'Izoh',
};

const kindLabels = {
  'student': 'O‘quvchi kartasi',
  'assessment': 'Baholash',
  'session': 'Mashg‘ulot',
  'iep': 'ITR rejasi',
  'referral': 'Yo‘naltirish',
  'observation': 'Psixolog kuzatuvi',
  'assessment_plan': 'Baholash rejasi',
  'subject_level': 'Fan bo‘yicha daraja',
  'measurement': 'O‘lchov',
  'subject_task': 'Fan topshirig‘i',
  'achievement': 'Yutuq',
  'conference': 'Konsilium',
  'sound_entry': 'Tovush mashqi',
  'notification': 'Bildirishnoma',
  'question': 'Savol',
  'curriculum': 'DTS standarti',
  'custom_metric': 'Ko‘rsatkich',
  'profile': 'Xodim profili',
};

class _ServerHistoryTabState extends State<ServerHistoryTab> {
  late final AdminApi _api = widget.api ?? AdminApi();
  final _time = DateFormat('dd.MM.yyyy HH:mm');

  int _view = 0; // 0 = o'zgarishlar, 1 = xavfsizlik
  String? _kind;
  String? _severity;

  List<DataChange> _changes = const [];
  List<SecurityEvent> _events = const [];
  bool _loading = true;
  bool _more = false;
  String? _error;

  static const _page = 100;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_view == 0) {
        final rows = await _api.changes(
          kind: _kind,
          beforeId: append && _changes.isNotEmpty ? _changes.last.id : null,
          limit: _page,
        );
        if (!mounted) return;
        setState(() {
          _changes = append ? [..._changes, ...rows] : rows;
          _more = rows.length == _page;
        });
      } else {
        final rows = await _api.securityEvents(
          severity: _severity,
          beforeId: append && _events.isNotEmpty ? _events.last.id : null,
          limit: _page,
        );
        if (!mounted) return;
        setState(() {
          _events = append ? [..._events, ...rows] : rows;
          _more = rows.length == _page;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _who(String? userId) {
    if (userId == null || userId.isEmpty) return 'Tizim';
    return LocalDbService().getUserById(userId)?.fullName ?? 'Foydalanuvchi';
  }

  @override
  Widget build(BuildContext context) {
    final items = _view == 0 ? _changes.length : _events.length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Audit jurnali',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _view == 0
                ? 'Kim, qachon va nimani qo‘shgan, o‘zgartirgan yoki o‘chirgan.'
                : 'Kirishlar, rad etilgan urinishlar va shubhali harakatlar.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('O‘zgarishlar'),
                    icon: Icon(LucideIcons.history, size: 16),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Xavfsizlik'),
                    icon: Icon(LucideIcons.shieldCheck, size: 16),
                  ),
                ],
                selected: {_view},
                onSelectionChanged: (v) {
                  setState(() => _view = v.first);
                  _load();
                },
              ),
              SizedBox(
                width: 220,
                child:
                    _view == 0
                        ? DropdownButtonFormField<String?>(
                          initialValue: _kind,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Turi',
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Hammasi'),
                            ),
                            for (final e in kindLabels.entries)
                              DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                          ],
                          onChanged: (v) {
                            setState(() => _kind = v);
                            _load();
                          },
                        )
                        : DropdownButtonFormField<String?>(
                          initialValue: _severity,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Darajasi',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Hammasi'),
                            ),
                            DropdownMenuItem(
                              value: 'alert',
                              child: Text('Xavfli'),
                            ),
                            DropdownMenuItem(
                              value: 'warning',
                              child: Text('Ogohlantirish'),
                            ),
                            DropdownMenuItem(
                              value: 'info',
                              child: Text('Oddiy'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _severity = v);
                            _load();
                          },
                        ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            _message(
              LucideIcons.cloudOff,
              'Jurnal yuklanmadi: $_error',
              action: 'Qayta urinish',
            )
          else if (_loading && items == 0)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items == 0)
            _message(LucideIcons.inbox, 'Hozircha yozuv yo‘q.')
          else ...[
            if (_view == 0)
              for (final c in _changes) _changeCard(c)
            else
              for (final e in _events) _eventRow(e),
            if (_more)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => _load(append: true),
                    child: const Text('Ko‘proq ko‘rsatish'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _message(IconData icon, String text, {String? action}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(action)),
          ],
        ],
      ),
    );
  }

  Widget _changeCard(DataChange c) {
    final (label, tone) = switch (c.action) {
      'create' => ('Qo‘shildi', StatusTone.success),
      'delete' => ('O‘chirildi', StatusTone.danger),
      _ => ('O‘zgartirildi', StatusTone.info),
    };
    final kind = kindLabels[c.kind] ?? c.kind;
    final title = c.studentName.isEmpty ? kind : '${c.studentName} · $kind';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(label, tone: tone),
                  Text(
                    '${c.userName.isEmpty ? _who(c.userId) : c.userName} · ${_time.format(c.at)}',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            children: [
              if (c.action == 'update' && c.before == null && c.after == null)
                // Shaxsiy ma'lumot (profil): qiymatlar tarixda saqlanmaydi.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'O‘zgargan: ${c.fields.map((f) => fieldLabels[f] ?? f).join(', ')}. '
                    'Shaxsiy ma’lumot bo‘lgani uchun qiymatlar tarixda saqlanmaydi.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else if (c.action == 'update')
                for (final f in c.fields) _diffRow(f, c.before?[f], c.after?[f])
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    c.action == 'create'
                        ? '${c.fields.length} ta maydon bilan qo‘shildi.'
                        : 'Yozuv o‘chirildi; oxirgi holati tarixda saqlanadi.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _show(Object? v) {
    if (v == null) return '—';
    final text =
        v is String
            ? v
            : v is List
            ? (v.isEmpty ? '—' : v.join(', '))
            : jsonEncode(v);
    if (text.trim().isEmpty) return '—';
    return text.length > 240 ? '${text.substring(0, 240)}…' : text;
  }

  Widget _diffRow(String field, Object? before, Object? after) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldLabels[field] ?? field,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _show(before),
                  style: TextStyle(
                    color: AppColors.error,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                TextSpan(
                  text: '  →  ',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                TextSpan(
                  text: _show(after),
                  style: TextStyle(color: AppColors.success),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _eventRow(SecurityEvent e) {
    final (label, tone) = switch (e.severity) {
      'alert' => ('Xavfli', StatusTone.danger),
      'warning' => ('Ogohlantirish', StatusTone.warning),
      _ => ('Oddiy', StatusTone.neutral),
    };
    final parts = [
      _who(e.userId),
      if (e.subject.isNotEmpty) e.subject,
      if (e.ip.isNotEmpty) e.ip,
      _time.format(e.at),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                e.action,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              StatusBadge(label, tone: tone),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            parts.join(' · '),
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          if (e.detail.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              e.detail,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
