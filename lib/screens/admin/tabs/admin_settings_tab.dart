import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  bool _hideSensitiveInfo = false;

  TextStyle _myGovFont({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color color = const Color(0xFF0A1A3F),
    double letterSpacing = -0.1,
    double? height,
  }) {
    return GoogleFonts.golosText(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  String _formatShortName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0].substring(0, 1).toUpperCase()}. ${parts[1]}';
    }
    return fullName.isNotEmpty ? fullName : 'Administrator';
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return 'Ko‘rsatilmagan';
    if (!_hideSensitiveInfo) return phone;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9) {
      final last2 = digits.substring(digits.length - 2);
      return '+998 (••) •••-••-$last2';
    }
    return '••• •• ••';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final fullName = user?.fullName ?? 'Administrator';
    final phone = user?.phone ?? '+998 90 123-45-67';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. MY.GOV.UZ USLUBIDAGI PROFIL HEADER
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080A1A3F),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF1F5F9),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        fullName.substring(0, 1).toUpperCase(),
                        style: _myGovFont(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A4D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatShortName(fullName),
                            style: _myGovFont(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _maskPhone(phone),
                            style: _myGovFont(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(
                          () => _hideSensitiveInfo = !_hideSensitiveInfo,
                        );
                      },
                      icon: Icon(
                        _hideSensitiveInfo
                            ? LucideIcons.eyeOff
                            : LucideIcons.eye,
                        size: 21,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showChangePasswordDialog(context),
                      icon: const Icon(
                        LucideIcons.settings,
                        size: 21,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. MY.GOV.UZ RO'YXAT ELEMENTLARI
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildMyGovRow(
                      icon: LucideIcons.idCard,
                      title: 'Shaxsiy ma’lumotlar',
                      subtitle: '${user?.fullName ?? ''} • ${user?.email ?? ''}',
                    ),
                    _buildMyGovRow(
                      icon: LucideIcons.shield,
                      title: 'Xavfsizlik va parol',
                      subtitle: 'Administrator kirish parolini yangilash',
                      badgeText: 'Himoyalangan',
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    _buildMyGovRow(
                      icon: LucideIcons.slidersHorizontal,
                      title: 'Monitoring mezonlari',
                      subtitle:
                          'Oraliq baholash (60 kun), regressiya va davomat qoidalari',
                    ),
                    _buildMyGovRow(
                      icon: LucideIcons.paintbrush,
                      title: 'Ilova mavzusi',
                      trailingValue: 'Tizimli',
                      showChevron: false,
                    ),
                    _buildMyGovRow(
                      icon: LucideIcons.languages,
                      title: 'Ilova tili',
                      trailingValue: 'O‘zbekcha',
                      showChevron: false,
                    ),
                    _buildMyGovRow(
                      icon: LucideIcons.circleAlert,
                      title: 'Ilova haqida',
                      subtitle: 'Individ v1.0.0 • O‘RQ-547 standarti',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyGovRow({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingValue,
    String? badgeText,
    bool showChevron = true,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFF1A2A4D),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _myGovFont(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: _myGovFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3DBE37), Color(0xFF0062CC)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: _myGovFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            if (trailingValue != null) ...[
              const SizedBox(width: 10),
              Text(
                trailingValue,
                style: _myGovFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Parolni yangilash',
          style: _myGovFont(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                style: _myGovFont(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Eski parol *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                style: _myGovFont(fontSize: 14),
                decoration: const InputDecoration(labelText: 'Yangi parol *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                style: _myGovFont(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Yangi parolni takrorlang *',
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
              if (newPassCtrl.text.trim() != confirmPassCtrl.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yangi parollar bir-biriga mos kelmadi.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final res = await auth.changePassword(
                oldPassCtrl.text.trim(),
                newPassCtrl.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] as String),
                    backgroundColor: res['success'] == true
                        ? const Color(0xFF12803A)
                        : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }
}
