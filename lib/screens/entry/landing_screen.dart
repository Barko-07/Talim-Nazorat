import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_brand.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/page_art.dart';
import '../../services/privacy_link.dart';
import '../auth/login_screen.dart';

/// individ.uz bosh sahifasi (kompyuter va telefon brauzeri). Qisqa: nima
/// ekanini aytadi va Ro'yxatdan o'tish / Kirish tugmalarini beradi.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static void openAuth(BuildContext context, {required bool signUp}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(initialIsSignUp: signUp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar(wide: wide)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Expanded(child: Center(child: EntryHero(wide: wide))),
                  const _Footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool wide;
  const _TopBar({required this.wide});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              const BrandMark(height: 34),
              const SizedBox(width: 10),
              const BrandWordmark(fontSize: 20),
              const Spacer(),
              if (wide)
                TextButton(
                  onPressed:
                      () => LandingScreen.openAuth(context, signUp: false),
                  child: const Text(
                    'Kirish',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kirishdan oldingi asosiy blok: sarlavha, qisqa matn, 4 ta imkoniyat,
/// rasm va ikki tugma. Saytda ham, telefon ilovasida ham shu ishlatiladi.
class EntryHero extends StatelessWidget {
  final bool wide;
  const EntryHero({super.key, this.wide = false});

  static const _features = [
    (LucideIcons.usersRound, 'Bola profili'),
    (LucideIcons.clipboardCheck, 'ITR rejasi'),
    (LucideIcons.chartColumnIncreasing, 'Monitoring'),
    (LucideIcons.fileSpreadsheet, 'Hisobotlar'),
  ];

  @override
  Widget build(BuildContext context) {
    final align = wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = wide ? TextAlign.start : TextAlign.center;

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF22A35A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Inklyuziv ta’lim uchun yagona platforma',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color:
              AppColors.isDark
                  ? const Color(0xFF5BD47A)
                  : const Color(0xFF15803D),
        ),
      ),
    );

    final features = Row(
      mainAxisAlignment:
          wide ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
      children: [
        for (final (icon, label) in _features)
          Padding(
            padding: EdgeInsets.only(right: wide ? 28 : 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryTint),
                  ),
                  child: Icon(icon, size: 22, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    final buttons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: () => LandingScreen.openAuth(context, signUp: true),
            icon: const Icon(LucideIcons.userPlus, size: 19),
            label: const Text(
              'Ro‘yxatdan o‘tish',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => LandingScreen.openAuth(context, signUp: false),
            icon: const Icon(LucideIcons.logIn, size: 19),
            label: const Text(
              'Kirish',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );

    final text = Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        pill,
        const SizedBox(height: 18),
        Text(
          'Har bir bolaning rivojlanishi — bir joyda',
          textAlign: textAlign,
          style: TextStyle(
            fontSize: wide ? 46 : 30,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: wide ? -1 : -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Psixolog, logoped, defektolog va o‘qituvchilar bolani birgalikda '
            'baholaydi, kuzatadi va individual reja tuzadi.',
            textAlign: textAlign,
            style: TextStyle(
              fontSize: wide ? 17 : 15.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 26),
        features,
        if (wide) ...[
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: buttons,
          ),
        ],
      ],
    );

    final art = _HeroArt(wide: wide);

    final content =
        wide
            ? Row(
              children: [
                Expanded(flex: 6, child: text),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: art),
              ],
            )
            : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                text,
                const SizedBox(height: 26),
                art,
                const SizedBox(height: 26),
                buttons,
              ],
            );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 1120 : 460),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, wide ? 40 : 20, 20, 24),
        child: content,
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

/// Rasm: yumshoq ko'k fon, yashil to'lqin va uchta asosiy bo'lim belgisi.
class _HeroArt extends StatelessWidget {
  final bool wide;
  const _HeroArt({required this.wide});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final h = wide ? 320.0 : 200.0;
        final big = h * 0.36;
        return Container(
          height: h,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const Positioned(right: 0, bottom: 0, child: PageHeaderHill()),
              Positioned(
                left: 0,
                bottom: 0,
                child: Transform.flip(flipX: true, child: const PageHeaderHill()),
              ),
              Align(
                alignment: const Alignment(0, -0.1),
                child: PageArtFigure(PageArtKind.children, size: big),
              ),
              Align(
                alignment: const Alignment(-0.78, 0.35),
                child: PageArtFigure(PageArtKind.plan, size: big * 0.62),
              ),
              Align(
                alignment: const Alignment(0.8, 0.3),
                child: PageArtFigure(PageArtKind.monitoring, size: big * 0.62),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 13, color: AppColors.textMuted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 6,
        children: [
          Text('© 2026 ${AppBrand.name}', style: muted),
          InkWell(
            onTap: openPrivacyPolicy,
            child: Text(
              'Maxfiylik siyosati',
              style: muted.copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
