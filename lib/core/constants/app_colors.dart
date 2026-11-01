import 'package:flutter/material.dart';

class AppColors {
  // Asosiy Brend Ranglari — Sokin va jiddiy korporativ ko'k (Minimalist SaaS)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primaryTint = Color(0xFFDBEAFE);

  // Fon va Yuzalar — Cool Slate & Pearl Mesh (Oppoq kartalar va shisha navbarlar silliq ajralishi uchun)
  static const Color background = Color(0xFFDFE5ED); // Neytral muvozanatli kulrang
  static const Color backgroundDeep = Color(0xFFD0D7E2); // Chuqurroq anchor kulrang
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // Minimalist Soft-Glass Qatlam Tokenlari
  static const Color glassFill = Color(0xEBFFFFFF); // 92% toza oq
  static const Color glassFillStrong = Color(0xF5FFFFFF); // 96% toza oq
  static const Color glassWellFill = Color(0xFFF3F6FA); // Sokin ichki blok foni
  static const Color glassRecessedFill = Color(0xFFEBF0F6);
  static const Color glassSpecular = Color(0xFFFFFFFF);
  static const Color glassWhiteBorder = Color(0xF5FFFFFF); // 96% oq chegara
  static const Color glassInnerBorder = Color(0xF0FFFFFF);
  static const Color hairlineBorder = Color(0xF0FFFFFF);

  // Tipografiya (Aniq va yuqori o'qiluvchanlik)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  // Chegaralar (Hairline Borders)
  static const Color border = Color(0xFFDCE2EA);
  static const Color borderSlate = Color(0xFFD0D7E2);
  static const Color borderLight = Color(0xFFE8EDF3);

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

  // Minimalist mayin neytral soyalar (2-qatlamli silliq hajm)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0C0F172A),
      blurRadius: 18,
      spreadRadius: -2,
      offset: Offset(0, 5),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  // Navbarlar uchun oqish shisha (fondan ajralib turishi uchun)
  static const double navGlassOpacity = 0.76;
  static const Color navGlassBorder = Color(0xF2FFFFFF); // 95% toza oq qirra
  static const List<BoxShadow> navShadow = [
    BoxShadow(
      color: Color(0x0E0F172A),
      blurRadius: 20,
      spreadRadius: -3,
      offset: Offset(0, 5),
    ),
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  // Kartalar uchun minimal "glassy" qirra
  static const Color cardGlassBorder = Color(0xF5FFFFFF); // 96% toza oq qirra

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
