import 'package:flutter/material.dart';

class AppColors {
  // Asosiy Brend & Apple-grade Royal Sapphire Ranglari
  static const Color primary = Color(0xFF0057FF); // Luminous Apple Sapphire Blue
  static const Color primaryDark = Color(0xFF003BB3); // Deep Sapphire
  static const Color primaryLight = Color(0xFFEBF2FF); // Soft Ice Blue
  static const Color primaryTint = Color(0xFFDCE8FF); // Cool Tint

  // Fon va Yuzalar — Apple Spatial Mist (oq shisha qutilar "kesib olingandek" ajralib turishi uchun)
  static const Color background = Color(0xFFE7EEF8); // Cool Silver-Ice Mist
  static const Color backgroundDeep = Color(0xFFDDE7F5); // Deeper Ambient Mist
  static const Color surface = Color(0xB8FFFFFF); // Translucent Frosted White
  static const Color card = Color(0xB8FFFFFF);

  // Apple "Cut-Out Frosted Glass" Qatlam Tokenlari
  static const Color glassFill = Color(0xB0FFFFFF); // 69% sutdek shaffof oq
  static const Color glassFillStrong = Color(0xC7FFFFFF); // 78% kesib olingan shisha
  static const Color glassWellFill = Color(0x78FFFFFF); // 47% ichki o'yilgan shisha
  static const Color glassRecessedFill = Color(0x66DCE6F5); // Ichki chuqurcha foni
  static const Color glassSpecular = Color(0xF5FFFFFF); // 96% yorqin oq shisha qirrasi
  static const Color glassWhiteBorder = Color(0xF2FFFFFF); // 95% sof oq border
  static const Color glassInnerBorder = Color(0xCCFFFFFF); // 80% ichki oq border
  static const Color hairlineBorder = Color(0x140F172A); // Ichki nozik ajratkich

  // Tipografiya (Yuqori kontrast, tiniq Apple SF/Jakarta uslubi)
  static const Color textPrimary = Color(0xFF0B1324); // Deep Ink
  static const Color textSecondary = Color(0xFF334155); // Slate 700
  static const Color textMuted = Color(0xFF5B6B82); // Cool Muted Slate
  static const Color textSubtle = Color(0xFF8998AD); // Placeholder Slate

  // Chegaralar (Borders)
  static const Color border = Color(0xE6FFFFFF); // Glassy White Border
  static const Color borderSlate = Color(0xFFD5E0EE); // Soft Mist Divider
  static const Color borderLight = Color(0xCCF4F7FC);

  // Holat ranglari (Semantics)
  static const Color success = Color(0xFF059669); // Emerald 600
  static const Color successBg = Color(0xB3ECFDF5);
  static const Color successBorder = Color(0xCCA7F3D0);

  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningBg = Color(0xB3FFFBEB);
  static const Color warningBorder = Color(0xCCFDE68A);

  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorBg = Color(0xB3FEF2F2);
  static const Color errorBorder = Color(0xCCFECACA);

  static const Color info = Color(0xFF0284C7); // Sky 600
  static const Color infoBg = Color(0xB3F0F9FF);
  static const Color infoBorder = Color(0xCCBAE6FD);

  static const Color purple = Color(0xFF7C3AED); // Violet 600
  static const Color purpleBg = Color(0xB3F5F3FF);
  static const Color purpleBorder = Color(0xCCDDD6FE);

  // Davlat Xizmatlari / MyGov Ranglari
  static const Color myGovBlue = Color(0xFF0057FF);
  static const Color myGovBlueDark = Color(0xFF003BB3);
  static const Color myGovBlueLight = Color(0xFFEBF2FF);

  // Kesib olingan shisha (Cut-out Glass) uchun mayin hajmli soyalar
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0D0F172A),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x060057FF),
      blurRadius: 12,
      spreadRadius: -2,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 34,
      spreadRadius: -4,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x0D0057FF),
      blurRadius: 16,
      spreadRadius: -2,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x380057FF),
      blurRadius: 22,
      spreadRadius: -4,
      offset: Offset(0, 10),
    ),
  ];
}
