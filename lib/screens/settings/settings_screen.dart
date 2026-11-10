import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/theme_picker.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/logout_dialog.dart';
import '../auth/verification_screens.dart';
import 'profile_edit_dialog.dart';
import '../../core/widgets/status_badge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hideSensitiveInfo = false;

  TextStyle _myGovFont({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = -0.1,
    double? height,
  }) {
    return GoogleFonts.golosText(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  String _formatShortName(String fullName) {
    final parts =
        fullName
            .trim()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .toList();
    if (parts.length >= 2) {
      final firstInitial = parts[0].substring(0, 1).toUpperCase();
      return '$firstInitial. ${parts[1]}';
    }
    return fullName.isNotEmpty ? fullName : 'Mutaxassis';
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
    final canPop = Navigator.canPop(context);
    final region = user?.region ?? 'Namangan viloyati';
    final district = user?.district ?? 'Chortoq tumani';
    final fullName = user?.fullName ?? 'Mutaxassis';
    final phone = user?.phone ?? '+998 90 123-45-67';
    final schoolName = user?.institutionName ?? '';

    final scrollBody = SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. MY.GOV.UZ USLUBIDAGI YUQORI PROFIL KARTasi
            SurfaceCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      fullName.substring(0, 1).toUpperCase(),
                      style: _myGovFont(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _maskPhone(phone),
                          style: _myGovFont(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip:
                        _hideSensitiveInfo
                            ? 'Ma’lumotlarni ko‘rsatish'
                            : 'Ma’lumotlarni yashirish',
                    onPressed: () {
                      setState(() => _hideSensitiveInfo = !_hideSensitiveInfo);
                    },
                    icon: Icon(
                      _hideSensitiveInfo ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Xavfsizlik sozlamalari',
                    onPressed: () => _showChangePasswordSheet(context),
                    icon: Icon(
                      LucideIcons.settings,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. MY.GOV.UZ USLUBIDAGI PROFIL VA SOZLAMALAR RO'YXATI
            SurfaceCard(
              borderRadius: 24,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (AppConfig.serverMode && user != null)
                    _buildMyGovMenuItem(
                      icon: LucideIcons.userPen,
                      title: 'Profilni tahrirlash',
                      subtitle: 'Ism, telefon va kasbiy ma’lumotlar',
                      onTap: () => showProfileEditDialog(context, user),
                    ),
                  _buildMyGovMenuItem(
                    icon: LucideIcons.idCard,
                    title: 'Shaxsiy ma’lumotlar',
                    subtitle: 'F.I.Sh, aloqa va identifikatsiya ma’lumotlari',
                    onTap: () => _showPersonalDetailsSheet(context, user),
                  ),
                  _buildMyGovMenuItem(
                    icon: LucideIcons.briefcase,
                    title: 'Mehnat faoliyati',
                    subtitle: user?.role.label ?? 'Mutaxassis',
                    badgeText: 'Faol',
                    onTap: () => _showProfessionSheet(context, user),
                  ),
                  _buildMyGovMenuItem(
                    icon: LucideIcons.house,
                    title: 'Ta’lim muassasasi',
                    subtitle: schoolName,
                    onTap:
                        () => _showInstitutionSheet(
                          context,
                          schoolName,
                          region,
                          district,
                        ),
                  ),
                  _buildMyGovMenuItem(
                    icon: LucideIcons.shield,
                    title: 'Xavfsizlik',
                    subtitle: 'Parolni yangilash va kirish himoyasi',
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                  _buildMyGovMenuItem(
                    icon: LucideIcons.paintbrush,
                    title: 'Ilova mavzusi',
                    trailingValue: context.watch<ThemeProvider>().choice.label,
                    onTap: () => showThemePicker(context),
                  ),
                  _buildMyGovMenuItem(
                    icon: LucideIcons.circleAlert,
                    title: 'Ilova haqida',
                    subtitle: 'Tizim ma’lumotlari va huquqiy me’yorlar',
                    onTap: () => _showAboutAppSheet(context),
                  ),
                  _buildMyGovMenuItem(
                    icon: LucideIcons.contact,
                    title: 'Bog‘lanish',
                    subtitle: 'Texnik yordam va hududiy koordinator',
                    onTap: () => _showContactSheet(context, region, district),
                  ),
                  _buildMyGovMenuItem(
                    icon: LucideIcons.logOut,
                    title: 'Profildan chiqish',
                    isLast: true,
                    showChevron: false,
                    onTap: () => confirmLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. PAстки RASMIY FOOTER
            Center(
              child: Column(
                children: [
                  Text(
                    'Raqamli ta’lim monitoringi tizimi',
                    style: _myGovFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Individ • v1.0.0',
                    style: _myGovFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar:
          canPop
              ? AppBar(
                title: Text(
                  'Sozlamalar',
                  style: _myGovFont(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              )
              : null,
      body: canPop ? AmbientMeshBackground(child: scrollBody) : scrollBody,
    );
  }

  Widget _buildMyGovMenuItem({
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
      borderRadius: BorderRadius.vertical(
        top: Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : Border(
                    bottom: BorderSide(
                      color: AppColors.surfaceMuted,
                      width: 1.0,
                    ),
                  ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
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
                      color: AppColors.textPrimary,
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _myGovFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 10),
              StatusBadge(badgeText, tone: StatusTone.success),
            ],
            if (trailingValue != null) ...[
              const SizedBox(width: 10),
              Text(
                trailingValue,
                style: _myGovFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPersonalDetailsSheet(BuildContext context, UserModel? user) {
    _showMyGovModal(
      context: context,
      title: 'Shaxsiy ma’lumotlar',
      rows: [
        ('F.I.Sh', user?.fullName ?? 'Ko‘rsatilmagan'),
        ('Telefon raqam', user?.phone ?? 'Ko‘rsatilmagan'),
        ('Elektron pochta', user?.email ?? 'Ko‘rsatilmagan'),
        ('Foydalanuvchi ID', user?.id ?? '—'),
      ],
    );
  }

  void _showProfessionSheet(BuildContext context, UserModel? user) {
    _showMyGovModal(
      context: context,
      title: 'Mehnat faoliyati',
      rows: [
        ('Mutaxassislik', user?.role.label ?? 'Mutaxassis'),
        ('Lavozim', user?.role.professionTitle ?? '—'),
        ('Malaka toifasi', user?.qualificationCategory ?? 'Mutaxassis'),
        ('Vakolat doirasi', user?.role.domainDescription ?? '—'),
      ],
    );
  }

  void _showInstitutionSheet(
    BuildContext context,
    String school,
    String region,
    String district,
  ) {
    _showMyGovModal(
      context: context,
      title: 'Ta’lim muassasasi',
      rows: [
        ('Muassasa nomi', school),
        ('Viloyat', region),
        ('Tuman / shahar', district),
        ('Yo‘nalish', 'Inklyuziv va korreksion ta’lim sektori'),
      ],
    );
  }

  void _showAboutAppSheet(BuildContext context) {
    _showMyGovModal(
      context: context,
      title: 'Ilova haqida',
      rows: const [
        ('Platforma nomi', 'Individ'),
        ('Talqin', '1.0.0'),
        (
          'Ma’lumotlar saqlanadi',
          AppConfig.serverMode
              ? 'Individ serveri (O‘zbekiston), shifrlangan'
              : 'Shu qurilma (sinov rejimi)',
        ),
        ('Huquqiy me’yor', 'O‘RQ-547 ("Shaxsga doir ma’lumotlar to‘g‘risida")'),
      ],
    );
  }

  void _showContactSheet(BuildContext context, String region, String district) {
    _showMyGovModal(
      context: context,
      title: 'Bog‘lanish',
      rows: [
        ('Hududiy boshqarma', '$region MMTB'),
        ('Mas’ul tuman', district),
        ('Ishonch telefoni', '+998 (69) 227-00-00'),
        ('Elektron manzil', 'info@talim-nazorat.uz'),
      ],
    );
  }

  void _showMyGovModal({
    required BuildContext context,
    required String title,
    required List<(String, String)> rows,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSlate,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: _myGovFont(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(LucideIcons.x, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...rows.map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.surfaceMuted),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 145,
                          child: Text(
                            item.$1,
                            style: _myGovFont(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: _myGovFont(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    if (AppConfig.serverMode) {
      showServerPasswordChange(context);
      return;
    }
    final auth = context.read<AuthProvider>();
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
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
                    decoration: const InputDecoration(
                      labelText: 'Joriy parol *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    style: _myGovFont(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Yangi parol *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    style: _myGovFont(fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Yangi parolni tasdiqlang *',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Bekor qilish',
                  style: _myGovFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () async {
                  final res = await auth.changePassword(
                    oldPassCtrl.text.trim(),
                    newPassCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res['message'] as String),
                        backgroundColor:
                            res['success'] == true
                                ? AppColors.success
                                : AppColors.error,
                      ),
                    );
                  }
                },
                child: Text(
                  'Saqlash',
                  style: _myGovFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
