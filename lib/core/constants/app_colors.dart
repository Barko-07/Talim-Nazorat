import 'package:flutter/material.dart';

class AppColors {
  // Asosiy Davlat / MyGov Standart Ranglari (Royal Blue & Deep Slate)
  static const Color primary = Color(0xFF0052CC); // MyGov Royal Blue
  static const Color primaryDark = Color(0xFF073A82); // MyGov Deep Navy
  static const Color primaryLight = Color(0xFFEFF6FF); // Soft Blue 50
  static const Color primaryTint = Color(0xFFE0EDFE); // Soft Blue 100

  // Fon va Yuzalar (Modern Minimal Porcelain & Frosted Glass)
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // Shishasimon (Glassmorphism) Qatlam Tokenlari
  static const Color glassFill = Color(0xCCFFFFFF); // 80% shaffof oq
  static const Color glassFillStrong = Color(0xEBFFFFFF); // 92% shaffof oq
  static const Color glassSpecular = Color(0xB3FFFFFF); // 70% yorug'lik qirrasi
  static const Color hairlineBorder = Color(0x140F172A); // 8% tabiiy chegara

  // Tipografiya (WCAG AA kontrastga moslangan)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF334155); // Slate 700
  static const Color textMuted = Color(0xFF64748B); // Slate 500 (Aniq o'qiladi)
  static const Color textSubtle = Color(0xFF94A3B8); // Slate 400 (Placeholder)

  // Chegaralar (Borders)
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100

  // Holat ranglari (Semantics)
  static const Color success = Color(0xFF059669); // Emerald 600
  static const Color successBg = Color(0xFFECFDF5); // Emerald 50
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningBg = Color(0xFFFFFBEB); // Amber 50
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFDC2626); // Red 600
  static const Color errorBg = Color(0xFFFEF2F2); // Red 50
  static const Color errorBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF0284C7); // Sky 600
  static const Color infoBg = Color(0xFFF0F9FF); // Sky 50
  static const Color infoBorder = Color(0xFFBAE6FD);

  static const Color purple = Color(0xFF7C3AED); // Violet 600
  static const Color purpleBg = Color(0xFFF5F3FF); // Violet 50
  static const Color purpleBorder = Color(0xFFDDD6FE);

  // Davlat Xizmatlari / MyGov Ranglari
  static const Color myGovBlue = Color(0xFF0052CC);
  static const Color myGovBlueDark = Color(0xFF073A82);
  static const Color myGovBlueLight = Color(0xFFEFF6FF);

  // Ko'p qatlamli mayin soyalar (Big-Tech Ambient + Key Shadows)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 18,
      spreadRadius: -3,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 28,
      spreadRadius: -4,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x330052CC),
      blurRadius: 18,
      spreadRadius: -3,
      offset: Offset(0, 8),
    ),
  ];
}
