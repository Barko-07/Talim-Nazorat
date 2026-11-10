import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_api.dart';
import '../../../services/api_client.dart';
import '../../../core/utils/uz_phone.dart';

/// Server rejimidagi "Foydalanuvchilar": barcha hisoblar (ro'yxatdan
/// o'tganlar tasdiq kutmaydi - kerak bo'lsa bloklanadi). Har bir amalni server tekshiradi
/// (o'zini bloklash, oxirgi administratorni pasaytirish va h.k. taqiqlangan).
class ServerUsersTab extends StatefulWidget {
  const ServerUsersTab({super.key, this.api});

  final AdminApi? api;

  @override
  State<ServerUsersTab> createState() => _ServerUsersTabState();
}

class _ServerUsersTabState extends State<ServerUsersTab> {
  late final AdminApi _api = widget.api ?? AdminApi();
  List<AdminUser> _users = const [];
  List<Institution> _institutions = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final results = await Future.wait([_api.users(), _api.institutions()]);
      if (!mounted) return;
      setState(() {
        _users = results[0] as List<AdminUser>;
        _institutions = results[1] as List<Institution>;
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

  /// Amalni bajaradi, natijani xabar qiladi va ro'yxatni yangilaydi.
  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (!mounted) return;
      _toast(done);
      await _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message, error: true);
    }
  }

  void _toast(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
  }

  String _institutionName(String? id) {
    if (id == null) return 'Muassasa biriktirilmagan';
    for (final i in _institutions) {
      if (i.id == id) return i.name;
    }
    return 'Muassasa topilmadi';
  }

  // ------------------------------------------------------------------ actions

  Future<void> _move(AdminUser u) async {
    final institution = await _pickInstitution(
      title: 'Boshqa muassasaga o‘tkazish',
      message: '${u.fullName} hozir: ${_institutionName(u.institutionId)}.',
      confirmLabel: 'O‘tkazish',
      exclude: u.institutionId,
    );
    if (institution == null) return;
    await _run(
      () => _api.update(u.id, institutionId: institution.id),
      '${u.fullName} — ${institution.name}. U tizimga qayta kiradi.',
    );
  }

  Future<void> _changeRole(AdminUser u) async {
    final role = await showDialog<UserRole>(
      context: context,
      builder:
          (ctx) => SimpleDialog(
            title: Text('${u.fullName} — rol'),
            children: [
              for (final r in UserRole.values)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, r),
                  child: Row(
                    children: [
                      Icon(
                        r == u.role
                            ? LucideIcons.circleCheck
                            : LucideIcons.circle,
                        size: 18,
                        color:
                            r == u.role
                                ? AppColors.primary
                                : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(r.label)),
                    ],
                  ),
                ),
            ],
          ),
    );
    if (role == null || role == u.role) return;
    await _run(
      () => _api.update(u.id, role: role),
      'Rol o‘zgartirildi: ${role.label}. U tizimga qayta kiradi.',
    );
  }

  Future<void> _toggleActive(AdminUser u) async {
    if (u.isActive) {
      final ok = await _confirm(
        title: 'Hisobni bloklash',
        message:
            '${u.fullName} tizimdan darhol chiqariladi va kira olmaydi. '
            'Keyin istalgan payt blokdan chiqarish mumkin.',
        confirmLabel: 'Bloklash',
        danger: true,
      );
      if (!ok) return;
    }
    await _run(
      () => _api.update(u.id, isActive: !u.isActive),
      u.isActive ? '${u.fullName} bloklandi' : '${u.fullName} faollashtirildi',
    );
  }

  // ------------------------------------------------------------------ dialogs

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Bekor qilish'),
              ),
              FilledButton(
                style:
                    danger
                        ? FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.onPrimary,
                        )
                        : null,
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );
    return ok == true;
  }

  /// Muassasa tanlash; ro'yxatda bo'lmasa — shu yerning o'zida qo'shish mumkin.
  Future<Institution?> _pickInstitution({
    required String title,
    required String message,
    required String confirmLabel,
    String? exclude,
  }) async {
    final options = _institutions.where((i) => i.id != exclude).toList();
    String? selected = options.isEmpty ? null : options.first.id;
    final newName = TextEditingController();
    bool creating = options.isEmpty;
    final result = await showDialog<Institution>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => AlertDialog(
                  title: Text(title),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(message),
                        const SizedBox(height: 16),
                        if (!creating)
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: selected,
                            decoration: const InputDecoration(
                              labelText: 'Muassasa',
                            ),
                            items: [
                              for (final i in options)
                                DropdownMenuItem(
                                  value: i.id,
                                  child: Text(
                                    i.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) => setLocal(() => selected = v),
                          )
                        else
                          TextField(
                            controller: newName,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Yangi muassasa nomi',
                              hintText: '14-sonli umumiy o‘rta ta’lim maktabi',
                            ),
                          ),
                        if (options.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed:
                                  () => setLocal(() => creating = !creating),
                              icon: Icon(
                                creating ? LucideIcons.list : LucideIcons.plus,
                                size: 16,
                              ),
                              label: Text(
                                creating
                                    ? 'Ro‘yxatdan tanlash'
                                    : 'Ro‘yxatda yo‘q — yangisini qo‘shish',
                              ),
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
                        if (creating) {
                          final name = newName.text.trim();
                          if (name.length < 3) return;
                          try {
                            final inst = await _api.createInstitution(name);
                            if (ctx.mounted) Navigator.pop(ctx, inst);
                          } on ApiException catch (e) {
                            _toast(e.message, error: true);
                          }
                        } else if (selected != null) {
                          Navigator.pop(
                            ctx,
                            options.firstWhere((i) => i.id == selected),
                          );
                        }
                      },
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
          ),
    );
    newName.dispose();
    return result;
  }

  Future<void> _createUser() async {
    final created = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => _CreateUserDialog(api: _api, institutions: _institutions),
    );
    if (created == true) {
      _toast(
        'Hisob yaratildi. Vaqtinchalik parol foydalanuvchi emailiga yuborildi.',
      );
      await _load();
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    // Ro'yxatdan o'tganlar admin tasdig'ini kutmaydi - hammasi bitta ro'yxatda.
    final q = _query.trim().toLowerCase();
    final accounts =
        _users
            .where(
              (u) =>
                  q.isEmpty ||
                  u.fullName.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q),
            )
            .toList();

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
                    'Foydalanuvchilar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loading
                        ? 'Yuklanmoqda…'
                        : '${_users.length} ta hisob',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _loading ? null : _createUser,
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text('Yangi foydalanuvchi'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null)
            _Notice(
              text: 'Ro‘yxat yuklanmadi: $_error',
              action: 'Qayta urinish',
              onAction: _load,
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _SectionTitle('Hisoblar'),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Ism yoki email bo‘yicha qidirish',
                prefixIcon: Icon(LucideIcons.search, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            if (accounts.isEmpty)
              _Notice(
                text:
                    q.isEmpty
                        ? 'Hali hisob yo‘q.'
                        : '“$_query” bo‘yicha hech kim topilmadi.',
              )
            else
              for (final u in accounts)
                _UserRow(
                  user: u,
                  institution: _institutionName(u.institutionId),
                  isMe: u.id == me?.id,
                  onSelected: (action) {
                    switch (action) {
                      case 'role':
                        _changeRole(u);
                      case 'move':
                        _move(u);
                      case 'active':
                        _toggleActive(u);
                      case 'unlock':
                        _run(() => _api.unlock(u.id), 'Blok olib tashlandi');
                      case 'sessions':
                        _run(
                          () => _api.revokeSessions(u.id),
                          'Barcha qurilmalardagi seanslar yopildi',
                        );
                    }
                  },
                ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: TextStyle(color: AppColors.textSecondary)),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}


class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.institution,
    required this.isMe,
    required this.onSelected,
  });

  final AdminUser user;
  final String institution;
  final bool isMe;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              user.fullName.isEmpty ? '?' : user.fullName[0],
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isMe)
                      const StatusBadge('Siz', tone: StatusTone.primary),
                    StatusBadge.active(
                      user.isActive,
                      inactiveLabel: 'Bloklangan',
                    ),
                    if (user.locked)
                      const StatusBadge(
                        'Vaqtincha qulflangan',
                        tone: StatusTone.danger,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.role.label} · $institution',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Amallar',
            icon: Icon(
              LucideIcons.ellipsisVertical,
              color: AppColors.textSecondary,
            ),
            onSelected: onSelected,
            itemBuilder:
                (_) => [
                  if (!isMe)
                    const PopupMenuItem(
                      value: 'role',
                      child: Text('Rolni o‘zgartirish'),
                    ),
                  const PopupMenuItem(
                    value: 'move',
                    child: Text('Boshqa muassasaga o‘tkazish'),
                  ),
                  if (user.locked)
                    const PopupMenuItem(
                      value: 'unlock',
                      child: Text('Blokdan chiqarish (urinishlar)'),
                    ),
                  const PopupMenuItem(
                    value: 'sessions',
                    child: Text('Barcha seanslarni yopish'),
                  ),
                  if (!isMe)
                    PopupMenuItem(
                      value: 'active',
                      child: Text(
                        user.isActive ? 'Bloklash' : 'Faollashtirish',
                        style: TextStyle(
                          color: user.isActive ? AppColors.error : null,
                        ),
                      ),
                    ),
                ],
          ),
        ],
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog({required this.api, required this.institutions});

  final AdminApi api;
  final List<Institution> institutions;

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController(text: UzPhone.prefix);
  UserRole _role = UserRole.teacher;
  String? _institution;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.createUser(
        email: _email.text.trim().toLowerCase(),
        fullName: _name.text.trim(),
        role: _role,
        institutionId: _institution,
        phone: UzPhone.normalize(_phone.text),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yangi foydalanuvchi'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vaqtinchalik parol foydalanuvchining emailiga yuboriladi. '
                'Birinchi kirishda u parolni almashtiradi.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Familiya Ism'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'ism@maktab.uz',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [UzPhone.formatter],
                decoration: InputDecoration(
                  labelText: 'Telefon (ixtiyoriy)',
                  hintText: UzPhone.hint,
                  errorText:
                      UzPhone.isEmpty(_phone.text) || UzPhone.isValid(_phone.text)
                          ? null
                          : UzPhone.error,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                isExpanded: true,
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: [
                  for (final r in UserRole.values)
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _institution,
                decoration: const InputDecoration(labelText: 'Muassasa'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Biriktirilmagan'),
                  ),
                  for (final i in widget.institutions)
                    DropdownMenuItem(
                      value: i.id,
                      child: Text(i.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() => _institution = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Yaratilmoqda…' : 'Yaratish'),
        ),
      ],
    );
  }
}
