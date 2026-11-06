import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

/// O'z profilini tahrirlash: ism, telefon va kasbiy ma'lumotlar. Email (login),
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
  late final TextEditingController _specialization;
  late final TextEditingController _experience;
  late final TextEditingController _region;
  late final TextEditingController _district;
  late String? _category;
  bool _saving = false;
  String? _error;

  static const _categories = ['Mutaxassis', '2-toifa', '1-toifa', 'Oliy toifa'];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    final parts = u.fullName.trim().split(RegExp(r'\s+'));
    _last = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _first = TextEditingController(
      text: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );
    _phone = TextEditingController(text: u.phone ?? '');
    _specialization = TextEditingController(text: u.specialization ?? '');
    _experience = TextEditingController(text: '${u.experienceYears}');
    _region = TextEditingController(text: u.region);
    _district = TextEditingController(text: u.district ?? '');
    _category =
        _categories.contains(u.qualificationCategory)
            ? u.qualificationCategory
            : null;
  }

  @override
  void dispose() {
    for (final c in [
      _first,
      _last,
      _phone,
      _specialization,
      _experience,
      _region,
      _district,
    ]) {
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
    put('specialization', _specialization.text, u.specialization);
    put('region', _region.text, u.region);
    put('district', _district.text, u.district);
    final phone = _phone.text.trim();
    if (phone != (u.phone ?? '') && phone.isNotEmpty) out['phone'] = phone;
    final years = int.tryParse(_experience.text.trim());
    if (years != null && years != u.experienceYears) {
      out['experience_years'] = years;
    }
    if (_category != null && _category != u.qualificationCategory) {
      out['qualification_category'] = _category;
    }
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
    InputDecoration deco(String label, {String? hint}) =>
        InputDecoration(labelText: label, hintText: hint);
    return AlertDialog(
      title: const Text('Profilni tahrirlash'),
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
                  decoration: deco('Familiya'),
                  validator: _name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _first,
                  decoration: deco('Ism'),
                  validator: _name,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: deco('Telefon', hint: '+998 90 123-45-67'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    return RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(t)
                        ? null
                        : 'Telefon raqam noto‘g‘ri';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specialization,
                  decoration: deco('Mutaxassislik'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: deco('Malaka toifasi'),
                  items: [
                    for (final c in _categories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _experience,
                  keyboardType: TextInputType.number,
                  decoration: deco('Ish staji (yil)'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 0 || n > 60
                        ? '0 dan 60 gacha son'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _region, decoration: deco('Viloyat')),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _district,
                  decoration: deco('Tuman / shahar'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Email, rol va maktabni administrator o‘zgartiradi.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
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
