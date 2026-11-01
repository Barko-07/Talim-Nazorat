import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final canPop = Navigator.canPop(context);
    final region = user?.region ?? 'Namangan viloyati';
    final district = user?.district ?? 'Chortoq tumani';
    final roleColor = user?.role.color ?? AppColors.primary;
    final roleIcon = user != null
        ? premiumRoleIcon(user.role)
        : LucideIcons.shieldCheck;

    final scrollBody = SingleChildScrollView(
      child: ResponsivePageContainer(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptivePageHeader(
              title: 'Tizim sozlamalari',
              subtitle:
                  'Foydalanuvchi profili va xavfsizlik konfiguratsiyasi',
              action: HeaderActionButton(
                variant: HeaderActionVariant.danger,
                icon: LucideIcons.logOut,
                label: 'Tizimdan chiqish',
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 18),

            // 1. Joriy Foydalanuvchi Profili (Minimalist Soft-Glass Hero Card)
            GlassSurface(
              borderRadius: 22,
              blur: 16,
              opacity: 0.96,
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.primaryTint,
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Mutaxassis',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17.5,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.1,
                            wordSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusPill(
                              label: user?.role.label ?? 'Mutaxassis',
                              color: AppColors.primary,
                              backgroundColor: AppColors.primaryLight,
                              showDot: true,
                            ),
                            const StatusPill(
                              label: 'Faol hisob',
                              color: AppColors.success,
                              backgroundColor: AppColors.successBg,
                              icon: LucideIcons.shieldCheck,
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 14,
                          runSpacing: 5,
                          children: [
                            if (user?.email != null && user!.email.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.mail,
                                    size: 13.5,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      user.email,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.phone,
                                  size: 13.5,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  user?.phone ?? '+998 90 000-00-00',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Biriktirilgan kasbiy profil va shaxsiy javobgarlik
            SurfaceCard(
              borderRadius: 22,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          roleIcon,
                          color: roleColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  user?.role.label ?? 'Mutaxassis',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const StatusPill(
                                  label: 'Soha qulflangan',
                                  color: AppColors.success,
                                  backgroundColor: AppColors.successBg,
                                  icon: LucideIcons.lock,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              user?.role.professionTitle ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: roleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlassWell(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mutaxassislik huquqi va doirasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          user?.role.domainDescription ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          LucideIcons.shield,
                          size: 15,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Shaxsiy javobgarlik talabiga binoan, profil ichidan mutaxassislik sohasini o‘zgartirib bo‘lmaydi. Boshqa kasbiy profil bilan kirish uchun joriy tizimdan chiqish lozim.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Ta'lim muassasasi (Dinamik haqiqiy hudud ma'lumotlari bilan)
            SurfaceCard(
              borderRadius: 22,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.school,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Ta’lim muassasasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlassWell(
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        _buildSettingRow(
                          'Muassasa nomi',
                          user?.institutionName ??
                              '9-sonli inklyuziv ta’lim tayanch maktabi',
                        ),
                        _buildSettingRow('Hudud', '$region, $district'),
                        _buildSettingRow(
                          'Bo‘lim',
                          'Alohida ta’lim ehtiyojlari bo‘lgan bolalar korreksion sektori',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. Ma'lumotlar bazasi va xavfsizlik
            SurfaceCard(
              borderRadius: 22,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.database,
                        color: AppColors.info,
                        size: 22,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Ma’lumotlar bazasi va xavfsizlik',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlassWell(
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        _buildSettingRow(
                          'Baza arxitekturasi',
                          'Mahalliy mustaqil ma’lumotlar bazasi (Offline-first Local DB)',
                        ),
                        _buildSettingRow(
                          'Tashqi bog‘liqlik',
                          'O‘chirilgan (Zero External Cloud Dependency)',
                        ),
                        _buildSettingRow(
                          'Xotirada saqlash',
                          'SharedPreferences doimiy xotirasi + tezkor indeksatsiya',
                        ),
                        _buildSettingRow(
                          'Xavfsizlik standarti',
                          'O‘zR O‘RQ-547 «Shaxsga doir ma’lumotlar to‘g‘risida»gi qonuniga muvofiq',
                        ),
                        _buildSettingRow(
                          'Audit jurnali',
                          'Barcha amallar vaqt tamg‘asi bilan o‘zgarmas tarzda qayd etiladi',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Sozlamalar')) : null,
      body: canPop ? AmbientMeshBackground(child: scrollBody) : scrollBody,
    );
  }

  Widget _buildSettingRow(
    String label,
    String value, {
    bool isLast = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(
                      color: AppColors.hairlineBorder,
                      width: 1.0,
                    ),
                  ),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 175,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
