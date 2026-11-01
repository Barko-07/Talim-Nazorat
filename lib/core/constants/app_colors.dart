import 'package:flutter/material.dart';

class AppColors {
  // Asosiy Brend Ranglari — Sokin va jiddiy korporativ ko'k (Minimalist SaaS)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primaryTint = Color(0xFFDBEAFE);

  // Fon va Yuzalar — Clean Slate & Pearl (Oppoq kartalar chiroyli ajralib turishi uchun)
  static const Color background = Color(0xFFEBEFF4);
  static const Color backgroundDeep = Color(0xFFE5EAF1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // Minimalist Soft-Glass Qatlam Tokenlari
  static const Color glassFill = Color(0xEBFFFFFF); // 92% toza oq
  static const Color glassFillStrong = Color(0xF5FFFFFF); // 96% toza oq
  static const Color glassWellFill = Color(0xFFF7F8FA); // Sokin ichki blok foni
  static const Color glassRecessedFill = Color(0xFFF1F3F7);
  static const Color glassSpecular = Color(0xFFFFFFFF);
  static const Color glassWhiteBorder = Color(0xFFF3F6FA); // Nozik 1px oq rangga juda yaqin chegara
  static const Color glassInnerBorder = Color(0xFFF5F8FC); // Ichki nozik chegara
  static const Color hairlineBorder = Color(0xFFF5F8FC);

  // Tipografiya (Aniq va yuqori o'qiluvchanlik)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Chegaralar (Hairline Borders - yanada oqroq va mayin)
  static const Color border = Color(0xFFEEF3F8);
  static const Color borderSlate = Color(0xFFE5EBF2);
  static const Color borderLight = Color(0xFFF8FAFC);

  // Holat ranglari (Sokin va tartibli semantika)
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF0284C7);
  static const Color infoBg = Color(0xFFF0F9FF);
  static const Color infoBorder = Color(0xFFBAE6FD);

  static const Color purple = Color(0xFF6D28D9);
  static const Color purpleBg = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFDDD6FE);

  // Davlat Xizmatlari / MyGov Ranglari
  static const Color myGovBlue = Color(0xFF2563EB);
  static const Color myGovBlueDark = Color(0xFF1D4ED8);
  static const Color myGovBlueLight = Color(0xFFEFF6FF);

  // Minimalist mayin neytral soyalar (ortiqcha rangli glow'siz)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x090F172A),
      blurRadius: 18,
      spreadRadius: -3,
      offset: Offset(0, 5),
    ),
  ];

  // Navbarlar uchun oqish shisha (fondan ajralib turishi uchun)
  static const double navGlassOpacity = 0.74;
  static const Color navGlassBorder = Color(0xE6FFFFFF); // 90% oq qirra
  static const List<BoxShadow> navShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 18,
      spreadRadius: -4,
      offset: Offset(0, 4),
    ),
  ];

  // Kartalar uchun minimal "glassy" qirra
  static const Color cardGlassBorder = Color(0xF2FFFFFF); // 95% oq qirra

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x0D0F172A),
      blurRadius: 24,
      spreadRadius: -3,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x162563EB),
      blurRadius: 14,
      spreadRadius: -3,
      offset: Offset(0, 4),
    ),
  ];
}
