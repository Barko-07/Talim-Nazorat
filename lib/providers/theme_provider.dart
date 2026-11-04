import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Ilova mavzusi": tizimga moslashadi, doim yorug' yoki doim qorong'i.
enum AppThemeChoice { system, light, dark }

extension AppThemeChoiceLabel on AppThemeChoice {
  String get label {
    switch (this) {
      case AppThemeChoice.system:
        return 'Tizimli';
      case AppThemeChoice.light:
        return 'Yorug‘';
      case AppThemeChoice.dark:
        return 'Qorong‘i';
    }
  }

  String get description {
    switch (this) {
      case AppThemeChoice.system:
        return 'Telefon yoki kompyuter sozlamasiga moslashadi';
      case AppThemeChoice.light:
        return 'Doim yorug‘ fon';
      case AppThemeChoice.dark:
        return 'Doim qorong‘i fon — kechqurun ko‘zga yengil';
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'app_theme_choice';

  AppThemeChoice _choice = AppThemeChoice.system;
  AppThemeChoice get choice => _choice;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      final found = AppThemeChoice.values.where((c) => c.name == saved);
      if (found.isNotEmpty && found.first != _choice) {
        _choice = found.first;
        notifyListeners();
      }
    } catch (_) {
      // Saqlangan tanlov o'qilmasa — tizim mavzusi.
    }
  }

  Future<void> setChoice(AppThemeChoice choice) async {
    if (choice == _choice) return;
    _choice = choice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, choice.name);
  }

  /// Hozir qaysi palitra ishlatiladi (tizim tanlangan bo'lsa — qurilma sozlamasi).
  bool isDark(Brightness platformBrightness) {
    switch (_choice) {
      case AppThemeChoice.system:
        return platformBrightness == Brightness.dark;
      case AppThemeChoice.light:
        return false;
      case AppThemeChoice.dark:
        return true;
    }
  }
}
