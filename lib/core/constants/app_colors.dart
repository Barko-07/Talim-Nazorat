import 'package:flutter/material.dart';

/// Bitta mavzuning (yorug' yoki qorong'i) barcha rang tokenlari.
///
/// Ekranlar ranglarni to'g'ridan-to'g'ri `Color(0x...)` bilan emas, faqat
/// [AppColors] orqali oladi — shunda bitta ilova ikkala mavzuda ham to'g'ri
/// ko'rinadi. Qorong'i mavzu: chuqur grafit fon, biroz ochroq kartalar va
/// logodagi ko'kning yorug' tusi (qorong'i fonda o'qiladigan) urg'u sifatida.
class AppPalette {
  final Brightness brightness;

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primaryTint;
  final Color onPrimary;

  final Color background;
  final Color backgroundDeep;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceRaised;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textSubtle;

  final Color border;
  final Color borderSlate;
  final Color borderLight;

  final Color success, successBg, successBorder;
  final Color warning, warningBg, warningBorder;
  final Color error, errorBg, errorBorder;
  final Color info, infoBg, infoBorder;
  final Color purple, purpleBg, purpleBorder;

  final Color shadow;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryTint,
    required this.onPrimary,
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textSubtle,
    required this.border,
    required this.borderSlate,
    required this.borderLight,
    required this.success,
    required this.successBg,
    required this.successBorder,
    required this.warning,
    required this.warningBg,
    required this.warningBorder,
    required this.error,
    required this.errorBg,
    required this.errorBorder,
    required this.info,
    required this.infoBg,
    required this.infoBorder,
    required this.purple,
    required this.purpleBg,
    required this.purpleBorder,
    required this.shadow,
  });

  bool get isDark => brightness == Brightness.dark;

  /// Yorug' mavzu — logodagi ko'k va to'q siyoh tusidagi matn.
  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF0062CC),
    primaryDark: Color(0xFF003D88),
    primaryLight: Color(0xFFEAF3FD),
    primaryTint: Color(0xFFD3E6FB),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFEEF4FB),
    backgroundDeep: Color(0xFFDDE8F6),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF4F7FC),
    surfaceRaised: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0A1A3F),
    textSecondary: Color(0xFF3A4762),
    textMuted: Color(0xFF5E6B85),
    textSubtle: Color(0xFF96A1B6),
    border: Color(0xFFE3EBF5),
    borderSlate: Color(0xFFD8E2EF),
    borderLight: Color(0xFFF0F4FA),
    success: Color(0xFF12803A),
    successBg: Color(0xFFEEF9EC),
    successBorder: Color(0xFFC3EBBE),
    warning: Color(0xFFB45309),
    warningBg: Color(0xFFFFFBEB),
    warningBorder: Color(0xFFFDE68A),
    error: Color(0xFFDC2626),
    errorBg: Color(0xFFFEF2F2),
    errorBorder: Color(0xFFFECACA),
    info: Color(0xFF00808A),
    infoBg: Color(0xFFE8F7F6),
    infoBorder: Color(0xFFB5E6E1),
    purple: Color(0xFF6D28D9),
    purpleBg: Color(0xFFF5F3FF),
    purpleBorder: Color(0xFFDDD6FE),
    shadow: Color(0xFF0A1A3F),
  );

  /// Qorong'i mavzu — grafit fon, yumshoq kartalar, och ko'k urg'u.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF7DB8FF),
    primaryDark: Color(0xFFB7D7FF),
    primaryLight: Color(0xFF1C2A3D),
    primaryTint: Color(0xFF243650),
    onPrimary: Color(0xFF071A33),
    background: Color(0xFF121314),
    backgroundDeep: Color(0xFF0B0C0D),
    surface: Color(0xFF1E1F21),
    surfaceMuted: Color(0xFF26282B),
    surfaceRaised: Color(0xFF2B2D31),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFC9CED6),
    textMuted: Color(0xFF9AA2AF),
    textSubtle: Color(0xFF6E7684),
    border: Color(0xFF303236),
    borderSlate: Color(0xFF3A3D42),
    borderLight: Color(0xFF26282B),
    success: Color(0xFF5BD47A),
    successBg: Color(0xFF16291D),
    successBorder: Color(0xFF24502F),
    warning: Color(0xFFF5B54A),
    warningBg: Color(0xFF2E2414),
    warningBorder: Color(0xFF5A4318),
    error: Color(0xFFFF7A7A),
    errorBg: Color(0xFF331B1C),
    errorBorder: Color(0xFF5E2A2C),
    info: Color(0xFF4FD1C5),
    infoBg: Color(0xFF13292A),
    infoBorder: Color(0xFF1F4A48),
    purple: Color(0xFFB79CFF),
    purpleBg: Color(0xFF241D38),
    purpleBorder: Color(0xFF3D3163),
    shadow: Color(0xFF000000),
  );
}

/// Ilovadagi barcha ranglar. Mavzuga bog'liq tokenlar joriy [AppPalette] dan
/// olinadi (mavzu almashganda butun ilova qayta chiziladi — main.dart).
/// Logoning o'z ranglari (brand*) ikkala mavzuda ham bir xil qoladi.
class AppColors {
  static AppPalette _p = AppPalette.light;

  static AppPalette get palette => _p;
  static bool get isDark => _p.isDark;

  /// Faqat ildiz oynasi chaqiradi (mavzu tanlanganda yoki tizim mavzusi o'zgarganda).
  static void usePalette(AppPalette palette) => _p = palette;

  // Individ brend ranglari — logotipdan olingan (ko'k figura, yashil barg, to'q siyoh)
  static const Color brandBlueBright = Color(0xFF0078EC);
  static const Color brandBlueDeep = Color(0xFF003D88);
  static const Color brandNavy = Color(0xFF001945);
  static const Color brandGreen = Color(0xFF3DBE37);
  static const Color brandGreenDeep = Color(0xFF13B64D);
  static const Color brandTeal = Color(0xFF029C8C);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlueBright, brandBlueDeep],
  );

  static const LinearGradient growthGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF70D03B), brandGreenDeep, brandTeal],
  );

  // Asosiy rang
  static Color get primary => _p.primary;
  static Color get primaryDark => _p.primaryDark;
  static Color get primaryLight => _p.primaryLight;
  static Color get primaryTint => _p.primaryTint;
  static Color get onPrimary => _p.onPrimary;

  // Fon va yuzalar
  static Color get background => _p.background;
  static Color get backgroundDeep => _p.backgroundDeep;
  static Color get surface => _p.surface;
  static Color get surfaceMuted => _p.surfaceMuted;
  static Color get surfaceRaised => _p.surfaceRaised;
  static Color get card => _p.surface;

  // Yuza qatlamlari (avvalgi "shisha" tokenlari — endi mavzuga mos)
  static Color get glassFill => _p.surface.withValues(alpha: 0.92);
  static Color get glassFillStrong => _p.surface.withValues(alpha: 0.96);
  static Color get glassWellFill => _p.surfaceMuted;
  static Color get glassRecessedFill => _p.isDark ? _p.backgroundDeep : const Color(0xFFEAF1FB);
  static Color get glassSpecular => _p.surface;
  static Color get glassWhiteBorder => _p.isDark ? _p.border : const Color(0xFFFFFFFF);
  static Color get glassInnerBorder => _p.isDark ? _p.border : const Color(0xF5FFFFFF);
  static Color get hairlineBorder => _p.isDark ? _p.border : const Color(0xF5FFFFFF);
  static Color get cardGlassBorder => _p.isDark ? _p.border : const Color(0xFFFFFFFF);
  static Color get navGlassBorder => _p.isDark ? _p.border : const Color(0xFFFFFFFF);
  static double get navGlassOpacity => _p.isDark ? 0.94 : 0.78;

  // Matn
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;
  static Color get textSubtle => _p.textSubtle;

  // Chegaralar
  static Color get border => _p.border;
  static Color get borderSlate => _p.borderSlate;
  static Color get borderLight => _p.borderLight;

  // Holat ranglari
  static Color get success => _p.success;
  static Color get successBg => _p.successBg;
  static Color get successBorder => _p.successBorder;
  static Color get warning => _p.warning;
  static Color get warningBg => _p.warningBg;
  static Color get warningBorder => _p.warningBorder;
  static Color get error => _p.error;
  static Color get errorBg => _p.errorBg;
  static Color get errorBorder => _p.errorBorder;
  static Color get info => _p.info;
  static Color get infoBg => _p.infoBg;
  static Color get infoBorder => _p.infoBorder;
  static Color get purple => _p.purple;
  static Color get purpleBg => _p.purpleBg;
  static Color get purpleBorder => _p.purpleBorder;

  static Color get myGovBlue => _p.primary;
  static Color get myGovBlueDark => _p.primaryDark;
  static Color get myGovBlueLight => _p.primaryLight;

  // Soyalar — qorong'i mavzuda deyarli ko'rinmaydi, kartalar fon bilan ajraladi
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: _p.shadow.withValues(alpha: _p.isDark ? 0.20 : 0.035),
      blurRadius: 18,
      spreadRadius: -2,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get navShadow => [
    BoxShadow(
      color: _p.shadow.withValues(alpha: _p.isDark ? 0.35 : 0.045),
      blurRadius: 20,
      spreadRadius: -3,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: _p.shadow.withValues(alpha: _p.isDark ? 0.30 : 0.05),
      blurRadius: 24,
      spreadRadius: -3,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: _p.primary.withValues(alpha: _p.isDark ? 0.18 : 0.10),
      blurRadius: 14,
      spreadRadius: -3,
      offset: const Offset(0, 4),
    ),
  ];
}
