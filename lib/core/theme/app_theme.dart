import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  /// Joriy palitradan (yorug' yoki qorong'i, AppColors.usePalette) qurilgan mavzu.
  /// Shrift va matn o'lchamlari Sozlamalar sahifasi uslubida: sarlavhalar 600,
  /// oddiy matn 500, o'qilishi oson o'lchamlar.
  static ThemeData get current {
    final baseFont = GoogleFonts.golosText().fontFamily;
    final dark = AppColors.isDark;
    final base = dark ? ThemeData.dark() : ThemeData.light();

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: baseFont,
      // google_fonts 9 o'z TextTheme turini (material_ui) qaytaradi, shuning uchun
      // shriftni Flutter'ning standart matn mavzusiga qo'llaymiz.
      textTheme: _textTheme(base.textTheme).apply(
        fontFamily: baseFont,
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
        },
      ),
      colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textMuted,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
        error: AppColors.error,
        onError: AppColors.onPrimary,
      ),
      canvasColor: AppColors.surface,
      iconTheme: IconThemeData(color: AppColors.textSecondary),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.primary),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: AppColors.textMuted, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.glassFillStrong,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.1,
          wordSpacing: 0.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: AppColors.glassWhiteBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceRaised,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border, width: 1.0),
        ),
        titleTextStyle: TextStyle(
          fontFamily: baseFont,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.1,
          wordSpacing: 0.35,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          side: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.surfaceRaised : AppColors.textPrimary,
        contentTextStyle: TextStyle(
          fontFamily: baseFont,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: dark ? AppColors.textPrimary : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        hoverColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.errorBorder,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1.3),
        ),
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.borderSlate,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: baseFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.0,
            wordSpacing: 0.25,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.borderSlate,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: baseFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.0,
            wordSpacing: 0.25,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: AppColors.borderSlate, width: 1.0),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontFamily: baseFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.0,
            wordSpacing: 0.25,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border, width: 1.0),
        ),
        side: BorderSide(color: AppColors.border, width: 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.hairlineBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Sozlamalar sahifasidagi o'lchamlar: sarlavha 20/600, karta sarlavhasi
  /// 15.5/600, oddiy matn 14/500, izoh 13/500.
  static TextTheme _textTheme(TextTheme t) => t.copyWith(
    headlineSmall: t.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleLarge: t.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2),
    titleMedium: t.titleMedium?.copyWith(fontSize: 15.5, fontWeight: FontWeight.w600),
    titleSmall: t.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: t.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
    bodyMedium: t.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    bodySmall: t.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
    labelLarge: t.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: t.labelMedium?.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
    labelSmall: t.labelSmall?.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
  );
}
