import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/app_colors.dart';

/// Har bir sahifaning o'z rasmi: sahifa sarlavhasi kartasida (o'ng tomonda,
/// yashil to'lqin ustida) va bo'sh holatda (kattaroq, markazda).
/// Rasm ilovaning o'z ikonkalaridan yig'iladi: oq "kartochka" ichida asosiy
/// belgi va burchagida kichik rangli nishon.
enum PageArtKind {
  children,
  sessions,
  plan,
  assessment,
  monitoring,
  reports,
  referral,
  team,
}

class _ArtSpec {
  final IconData main;
  final IconData? badgeIcon;
  final String? badgeText;
  final Color badgeColor;
  const _ArtSpec(
    this.main, {
    this.badgeIcon,
    this.badgeText,
    required this.badgeColor,
  });
}

const _green = Color(0xFF22A35A);
const _excel = Color(0xFF1D7044);

_ArtSpec _spec(PageArtKind k) => switch (k) {
  PageArtKind.children => const _ArtSpec(
    LucideIcons.usersRound,
    badgeIcon: LucideIcons.smile,
    badgeColor: _green,
  ),
  PageArtKind.sessions => const _ArtSpec(
    LucideIcons.calendarDays,
    badgeIcon: LucideIcons.check,
    badgeColor: _green,
  ),
  PageArtKind.plan => const _ArtSpec(
    LucideIcons.clipboardList,
    badgeIcon: LucideIcons.check,
    badgeColor: _green,
  ),
  PageArtKind.assessment => const _ArtSpec(
    LucideIcons.clipboardCheck,
    badgeText: 'A+',
    badgeColor: _green,
  ),
  PageArtKind.monitoring => const _ArtSpec(
    LucideIcons.chartColumnIncreasing,
    badgeIcon: LucideIcons.trendingUp,
    badgeColor: _green,
  ),
  PageArtKind.reports => const _ArtSpec(
    LucideIcons.fileSpreadsheet,
    badgeText: 'X',
    badgeColor: _excel,
  ),
  PageArtKind.referral => const _ArtSpec(
    LucideIcons.stethoscope,
    badgeIcon: LucideIcons.messageCircle,
    badgeColor: _green,
  ),
  PageArtKind.team => const _ArtSpec(
    LucideIcons.heartHandshake,
    badgeIcon: LucideIcons.check,
    badgeColor: _green,
  ),
};

/// Kartochka + nishon. [size] — kartochka tomoni.
class PageArtFigure extends StatelessWidget {
  final PageArtKind kind;
  final double size;
  const PageArtFigure(this.kind, {super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final s = _spec(kind);
    final dark = AppColors.isDark;
    final badge = size * 0.46;
    return SizedBox(
      width: size + badge * 0.45,
      height: size + badge * 0.35,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.06,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        dark
                            ? [AppColors.surfaceRaised, AppColors.surfaceMuted]
                            : const [Colors.white, Color(0xFFEAF2FD)],
                  ),
                  borderRadius: BorderRadius.circular(size * 0.26),
                  border: Border.all(color: AppColors.primaryTint),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: dark ? 0.25 : 0.16,
                      ),
                      blurRadius: size * 0.35,
                      offset: Offset(0, size * 0.12),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(s.main, size: size * 0.5, color: AppColors.primary),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(
                color: s.badgeColor,
                shape:
                    s.badgeText == 'X' ? BoxShape.rectangle : BoxShape.circle,
                borderRadius:
                    s.badgeText == 'X'
                        ? BorderRadius.circular(badge * 0.24)
                        : null,
                border: Border.all(
                  color: dark ? AppColors.surface : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: s.badgeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child:
                  s.badgeText != null
                      ? Text(
                        s.badgeText!,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: badge * 0.42,
                          height: 1,
                        ),
                      )
                      : Icon(
                        s.badgeIcon,
                        size: badge * 0.55,
                        color: Colors.white,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sarlavha kartasining o'ng pastki burchagidagi yashil to'lqin.
class _HillPainter extends CustomPainter {
  final bool dark;
  const _HillPainter(this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final back =
        Path()
          ..moveTo(w * 0.05, h)
          ..cubicTo(w * 0.35, h * 0.55, w * 0.6, h * 0.5, w, h * 0.18)
          ..lineTo(w, h)
          ..close();
    final front =
        Path()
          ..moveTo(w * 0.32, h)
          ..cubicTo(w * 0.55, h * 0.72, w * 0.78, h * 0.62, w, h * 0.5)
          ..lineTo(w, h)
          ..close();
    final a = dark ? 0.22 : 0.20;
    final b = dark ? 0.32 : 0.30;
    canvas.drawPath(
      back,
      Paint()
        ..shader = LinearGradient(
          colors: [_green.withValues(alpha: 0.0), _green.withValues(alpha: a)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          colors: [_green.withValues(alpha: 0.05), _green.withValues(alpha: b)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_HillPainter old) => old.dark != dark;
}

/// Sarlavha kartasi orqasidagi yashil to'lqin (o'ng pastki burchak).
class PageHeaderHill extends StatelessWidget {
  const PageHeaderHill({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: 240,
      height: 92,
      child: CustomPaint(painter: _HillPainter(AppColors.isDark)),
    ),
  );
}

/// Sarlavha kartasining fon qatlami: to'lqin va rasm (o'ng tomonda).
/// Matn ustida turmaydi — sarlavha chap tomonda qoladi.
class PageHeaderArt extends StatelessWidget {
  final PageArtKind kind;
  final double figureSize;
  const PageHeaderArt(this.kind, {super.key, this.figureSize = 58});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            width: 220,
            height: 96,
            child: CustomPaint(painter: _HillPainter(AppColors.isDark)),
          ),
          Positioned(
            right: 22,
            top: 14,
            child: PageArtFigure(kind, size: figureSize),
          ),
        ],
      ),
    );
  }
}

/// Bo'sh holat: rasm, sarlavha, qisqa matn va (bo'lsa) ikkinchi darajali tugma.
class ArtEmptyState extends StatelessWidget {
  final PageArtKind kind;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  const ArtEmptyState({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon = LucideIcons.plus,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(56),
              ),
              alignment: Alignment.center,
              child: PageArtFigure(kind, size: 64),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: Icon(actionIcon, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  side: BorderSide(color: AppColors.primaryTint),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
