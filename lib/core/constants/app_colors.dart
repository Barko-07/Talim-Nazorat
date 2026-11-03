import 'package:flutter/material.dart';

class AppColors {
  // Individ brend ranglari — logotipdan olingan (ko'k figura, yashil barg, to'q siyoh)
  static const Color brandBlueBright = Color(0xFF0078EC); // Logotip boshi (yorqin)
  static const Color brandBlueDeep = Color(0xFF003D88); // Logotip asosi (chuqur)
  static const Color brandNavy = Color(0xFF001945); // "Individ" so'z belgisi
  static const Color brandGreen = Color(0xFF3DBE37); // "i" harflari va barg
  static const Color brandGreenDeep = Color(0xFF13B64D);
  static const Color brandTeal = Color(0xFF029C8C); // Barg pastki uchi

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

  // Asosiy Brend Ranglari — oq matn bilan WCAG AA kontrastga ega Individ ko'ki
  static const Color primary = Color(0xFF0062CC);
  static const Color primaryDark = Color(0xFF003D88);
  static const Color primaryLight = Color(0xFFEAF3FD);
  static const Color primaryTint = Color(0xFFD3E6FB);

  // Fon va Yuzalar — brend ko'kiga uyg'un yorug' havorang
  static const Color background = Color(0xFFEEF4FB);
  static const Color backgroundDeep = Color(0xFFDDE8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // Minimalist Soft-Glass Qatlam Tokenlari
  static const Color glassFill = Color(0xEBFFFFFF); // 92% toza oq
  static const Color glassFillStrong = Color(0xF5FFFFFF); // 96% toza oq
  static const Color glassWellFill = Color(0xFFF3F7FD); // Sokin ichki blok foni (havorang tus)
  static const Color glassRecessedFill = Color(0xFFEAF1FB);
  static const Color glassSpecular = Color(0xFFFFFFFF);
  static const Color glassWhiteBorder = Color(0xFFFFFFFF); // 100% toza oq chegara
  static const Color glassInnerBorder = Color(0xF5FFFFFF);
  static const Color hairlineBorder = Color(0xF5FFFFFF);

  // Tipografiya — logotipdagi to'q siyoh tusidagi matn
  static const Color textPrimary = Color(0xFF0A1A3F);
  static const Color textSecondary = Color(0xFF2E3B57);
  static const Color textMuted = Color(0xFF5E6B85);
  static const Color textSubtle = Color(0xFF96A1B6);

  // Chegaralar (Hairline Borders)
  static const Color border = Color(0xFFE3EBF5);
  static const Color borderSlate = Color(0xFFD8E2EF);
  static const Color borderLight = Color(0xFFF0F4FA);

  // Holat ranglari — muvaffaqiyat brend yashilidan, ma'lumot brend firuzasidan
  static const Color success = Color(0xFF12803A);
  static const Color successBg = Color(0xFFEEF9EC);
  static const Color successBorder = Color(0xFFC3EBBE);

  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF00808A);
  static const Color infoBg = Color(0xFFE8F7F6);
  static const Color infoBorder = Color(0xFFB5E6E1);

  static const Color purple = Color(0xFF6D28D9);
  static const Color purpleBg = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFDDD6FE);

  // Davlat Xizmatlari / MyGov Ranglari (brend ko'kiga moslangan)
  static const Color myGovBlue = primary;
  static const Color myGovBlueDark = primaryDark;
  static const Color myGovBlueLight = primaryLight;

  // Minimalist mayin neytral soyalar (2-qatlamli yengil hajm)
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x090A1A3F),
      blurRadius: 18,
      spreadRadius: -2,
      offset: Offset(0, 5),
    ),
    BoxShadow(
      color: Color(0x040A1A3F),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  // Navbarlar uchun oqish shisha (fondan nafis ajralib turishi uchun)
  static const double navGlassOpacity = 0.78;
  static const Color navGlassBorder = Color(0xFFFFFFFF); // 100% toza oq qirra
  static const List<BoxShadow> navShadow = [
    BoxShadow(
      color: Color(0x0B0A1A3F),
      blurRadius: 20,
      spreadRadius: -3,
      offset: Offset(0, 5),
    ),
    BoxShadow(
      color: Color(0x040A1A3F),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  // Kartalar uchun minimal "glassy" qirra
  static const Color cardGlassBorder = Color(0xFFFFFFFF); // 100% toza oq qirra

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x0D0A1A3F),
      blurRadius: 24,
      spreadRadius: -3,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x1A0062CC),
      blurRadius: 14,
      spreadRadius: -3,
      offset: Offset(0, 4),
    ),
  ];
}
