import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Administrator panelining ko'rinishi: yumaloq oq kartalar, yengil soya,
/// och fondagi maydonlar va yumaloq tugmalar. Faqat admin sahifalariga
/// qo'llanadi (AdminPortalScreen tanasini o'raydi) — mutaxassis
/// sahifalari o'zgarmaydi. Funksiya emas, faqat ko'rinish.
ThemeData adminTheme(ThemeData base) {
  final radius12 = BorderRadius.circular(12);
  final radius18 = BorderRadius.circular(18);
  final dark = AppColors.isDark;

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: base.cardTheme.copyWith(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: dark ? 0 : 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius18,
        side: BorderSide(color: AppColors.borderLight),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: AppColors.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius12,
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius12,
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius12,
        borderSide: BorderSide(color: AppColors.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: base.listTileTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: radius12),
      iconColor: AppColors.textSecondary,
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      subtitleTextStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: AppColors.primaryLight,
      side: BorderSide(color: AppColors.borderLight),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.primary,
      labelStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
    ),
    expansionTileTheme: base.expansionTileTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: radius12),
      collapsedShape: RoundedRectangleBorder(borderRadius: radius12),
    ),
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    dividerTheme: base.dividerTheme.copyWith(color: AppColors.borderLight),
    dataTableTheme: base.dataTableTheme.copyWith(
      headingRowColor: WidgetStatePropertyAll(AppColors.surfaceMuted),
      headingTextStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius12),
    ),
  );
}
