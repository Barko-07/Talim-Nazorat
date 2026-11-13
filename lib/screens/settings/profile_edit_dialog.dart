import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/uz_phone.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

/// O'z profilini tahrirlash: ism, telefon va hudud. Email (login),
/// rol va maktabni faqat administrator o'zgartiradi — ular bu yerda yo'q.
Future<void> showProfileEditDialog(BuildContext context, UserModel user) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ProfileEditDialog(user: user),
  );
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.user});

  final UserModel user;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  late final TextEditingController _region;
  late final TextEditingController _district;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    final parts = u.fullName.trim().split(RegExp(r'\s+'));
    _last = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _first = TextEditingController(
      text: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );
    _phone = TextEditingController(text: UzPhone.initial(u.phone));
    _region = TextEditingController(text: u.region);
    _district = TextEditingController(text: u.district ?? '');
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _region, _district]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _changes() {
    final u = widget.user;
    final parts = u.fullName.trim().split(RegExp(r'\s+'));
    final oldLast = parts.isNotEmpty ? parts.first : '';
    final oldFirst = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final out = <String, dynamic>{};
    void put(String key, String value, String? old) {
      final v = value.trim();
      if (v != (old ?? '').trim()) out[key] = v;
    }

    put('first_name', _first.text, oldFirst);
    put('last_name', _last.text, oldLast);
    put('region', _region.text, u.region);
    put('district', _district.text, u.district);
    final phone = UzPhone.normalize(_phone.text);
    if (phone != null && phone != u.phone) out['phone'] = phone;
    return out;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final res = await context.read<AuthProvider>().updateOwnProfile(_changes());
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] as String? ?? 'Profil yangilandi'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _saving = false;
        _error = res['message'] as String?;
      });
    }
  }

  String? _name(String? v) {
    final t = (v ?? '').trim();
    if (t.length < 2) return 'Kamida 2 ta harf';
    if (RegExp(r'[<>]').hasMatch(t)) return 'Belgilar ruxsat etilmaydi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label, IconData icon, {String? hint}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
        );
    return AlertDialog(
      title: const Row(
        children: [
          Icon(LucideIcons.idCard, size: 22),
          SizedBox(width: 10),
          Expanded(child: Text('Shaxsiy ma’lumotlar')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _last,
                  decoration: deco('Familiya', LucideIcons.user),
                  validator: _name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _first,
                  decoration: deco('Ism', LucideIcons.userRound),
                  validator: _name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [UzPhone.formatter],
                  decoration: deco(
                    'Telefon',
                    LucideIcons.phone,
                    hint: UzPhone.hint,
                  ),
                  validator: (v) {
                    final t = v ?? '';
                    if (UzPhone.isEmpty(t)) return null;
                    return UzPhone.isValid(t) ? null : UzPhone.error;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _region,
                  decoration: deco('Viloyat', LucideIcons.map),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _district,
                  decoration: deco('Tuman / shahar', LucideIcons.mapPin),
                ),
                const SizedBox(height: 12),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 13, color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saqlanmoqda…' : 'Saqlash'),
        ),
      ],
    );
  }
}
