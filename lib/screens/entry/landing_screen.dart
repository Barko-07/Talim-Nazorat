import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_brand.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../auth/login_screen.dart';

/// individ.uz saytining bosh sahifasi (kompyuterda ham, telefon brauzerida ham).
/// Tizimga kirmagan mehmonga loyiha haqida qisqacha aytadi va Kirish /
/// Ro'yxatdan o'tish tugmalarini beradi.
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
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _TopBar(wide: wide)),
          SliverToBoxAdapter(child: _Hero(wide: wide)),
          SliverToBoxAdapter(child: _Features(wide: wide)),
          const SliverToBoxAdapter(child: _Audience()),
          const SliverToBoxAdapter(child: _CallToAction()),
          const SliverToBoxAdapter(child: _Footer()),
        ],
      ),
    );
  }
}

/// Sahifa mazmuni markazda, katta ekranda 1120px dan kengaymaydi.
class _Section extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  const _Section({
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 56),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
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
    return _Section(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const BrandMark(height: 34),
          const SizedBox(width: 10),
          const BrandWordmark(fontSize: 22),
          const Spacer(),
          TextButton(
            onPressed: () => LandingScreen.openAuth(context, signUp: false),
            child: const Text(
              'Kirish',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
          if (wide) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => LandingScreen.openAuth(context, signUp: true),
              child: const Text('Ro‘yxatdan o‘tish'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool wide;
  const _Hero({required this.wide});

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Inklyuziv ta’lim uchun yagona platforma',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Har bir bolaning rivojlanishi — bir joyda',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            fontSize: wide ? 48 : 32,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Psixolog, logoped, defektolog va o‘qituvchilar alohida ta’lim ehtiyojli '
          'bolalarni birgalikda baholaydi, kuzatadi va individual ta’lim rejasini tuzadi.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            height: 1.55,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () => LandingScreen.openAuth(context, signUp: true),
                icon: const Icon(LucideIcons.userPlus, size: 18),
                label: const Text(
                  'Ro‘yxatdan o‘tish',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => LandingScreen.openAuth(context, signUp: false),
                icon: const Icon(LucideIcons.logIn, size: 18),
                label: const Text(
                  'Kirish',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final art = Container(
      height: wide ? 380 : 240,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: BrandMark(height: wide ? 150 : 96),
        ),
      ),
    );

    return _Section(
      padding: EdgeInsets.only(top: wide ? 48 : 24, bottom: 56),
      child:
          wide
              ? Row(
                children: [
                  Expanded(flex: 6, child: text),
                  const SizedBox(width: 48),
                  Expanded(flex: 5, child: art),
                ],
              )
              : Column(children: [text, const SizedBox(height: 36), art]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03, end: 0);
  }
}

class _Features extends StatelessWidget {
  final bool wide;
  const _Features({required this.wide});

  static const _items = [
    (
      LucideIcons.chartLine,
      'Rivojlanish xaritasi',
      'Har bir bolaning rivojlanish darajasi va dinamikasi grafiklarda ko‘rinadi.',
    ),
    (
      LucideIcons.clipboardCheck,
      'Baholash va kuzatuv',
      'Yoshi va ehtiyojiga mos savollar bilan dalilga asoslangan baholash.',
    ),
    (
      LucideIcons.fileText,
      'Individual ta’lim rejasi',
      'Maqsadlar, mashg‘ulotlar va natijalar bitta rejada, butun jamoa uchun.',
    ),
    (
      LucideIcons.shieldCheck,
      'Ma’lumotlar xavfsizligi',
      'Maxfiy ma’lumotlar shifrlangan va O‘zbekistondagi serverda saqlanadi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      color: AppColors.surfaceMuted,
      child: Column(
        children: [
          Text(
            'Nimalar qila olasiz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, c) {
              final columns = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
              const gap = 16.0;
              final width = (c.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (icon, title, body) in _items)
                    SizedBox(
                      width: width,
                      child: _FeatureCard(icon: icon, title: title, body: body),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Audience extends StatelessWidget {
  const _Audience();

  static const _roles = [
    (LucideIcons.brain, 'Psixologlar'),
    (LucideIcons.mic, 'Logopedlar'),
    (LucideIcons.puzzle, 'Defektologlar'),
    (LucideIcons.bookOpen, 'O‘qituvchilar'),
    (LucideIcons.school, 'Maktab rahbariyati'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        children: [
          Text(
            'Kimlar uchun',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Har bir mutaxassis o‘z sohasiga mos ish joyini oladi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (icon, label) in _roles)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CallToAction extends StatelessWidget {
  const _CallToAction();

  @override
  Widget build(BuildContext context) {
    return _Section(
      padding: const EdgeInsets.only(bottom: 56),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              'Jamoangiz bilan boshlang',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ro‘yxatdan o‘ting — maktabingiz administratori hisobingizni tasdiqlaydi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.5, height: 1.5, color: Colors.white),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () => LandingScreen.openAuth(context, signUp: true),
                child: const Text(
                  'Ro‘yxatdan o‘tish',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return _Section(
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: AppColors.surfaceMuted,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Text(
            '© 2026 ${AppBrand.name} — ${AppBrand.tagline}',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          Text(
            'individ.uz',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
