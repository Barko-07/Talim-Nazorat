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

    return Scaffold(
      backgroundColor: canPop ? AppColors.background : Colors.transparent,
      appBar: canPop ? AppBar(title: const Text('Sozlamalar')) : null,
      body: SingleChildScrollView(
        child: ResponsivePageContainer(
          maxWidth: 960,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdaptivePageHeader(
                icon: LucideIcons.settings,
                title: 'Tizim va profil sozlamalari',
                subtitle:
                    'Foydalanuvchi profili, kasbiy javobgarlik doirasi va xavfsizlik konfiguratsiyasi',
                action: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.errorBorder),
                    backgroundColor: AppColors.errorBg,
                  ),
                  icon: const Icon(LucideIcons.logOut, size: 15),
                  label: const Text('Tizimdan chiqish'),
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
              const SizedBox(height: 20),

              // 1. Joriy Foydalanuvchi Profili (Frosted Hero Card)
              GlassSurface(
                borderRadius: 20,
                blur: 18,
                opacity: 0.86,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppColors.primaryGlow,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user?.fullName ?? 'U').substring(0, 1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Colors.white,
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
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
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
                              StatusPill(
                                label: 'Faol hisob',
                                color: AppColors.success,
                                backgroundColor: AppColors.successBg,
                                icon: LucideIcons.shieldCheck,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${user?.email ?? ''} • ${user?.phone ?? '+998 90 000-00-00'}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Biriktirilgan kasbiy profil va shaxsiy javobgarlik
              SurfaceCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (user?.role.color ?? AppColors.primary)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            user?.role.icon ?? Icons.verified_user_rounded,
                            color: user?.role.color ?? AppColors.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    user?.role.label ?? 'Mutaxassis',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.5,
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
                              const SizedBox(height: 4),
                              Text(
                                user?.role.professionTitle ?? '',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color:
                                      user?.role.color ?? AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.hairlineBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Mutaxassislik huquqi va doirasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.role.domainDescription ?? '',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            LucideIcons.shield,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shaxsiy javobgarlik talabiga binoan, profil ichidan mutaxassislik sohasini o‘zgartirib bo‘lmaydi. Boshqa kasbiy profil bilan kirish uchun joriy tizimdan chiqish lozim.',
                            style: TextStyle(
                              fontSize: 11.5,
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
              const SizedBox(height: 16),

              // 3. Ta'lim muassasasi (Dinamik haqiqiy hudud ma'lumotlari bilan)
              SurfaceCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.school,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Ta’lim muassasasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSettingRow(
                      'Muassasa nomi',
                      user?.institutionName ??
                          '9-sonli inklyuziv ta’lim tayanch maktabi',
                    ),
                    _buildSettingRow('Hudud', '$region, $district'),
                    _buildSettingRow(
                      'Bo‘lim',
                      'Alohida ta’lim ehtiyojlari bo‘lgan bolalar korreksion sektori',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Ma'lumotlar bazasi va xavfsizlik
              SurfaceCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.database,
                            color: AppColors.info,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Ma’lumotlar bazasi va xavfsizlik',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.hairlineBorder),
                  ),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 170,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
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
