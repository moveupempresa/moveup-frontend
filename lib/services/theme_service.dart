import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global, listenable source of truth for the app's theme mode. MainApp
/// rebuilds when this changes; any screen can update it via [ThemeService].
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

class ThemeService {
  static const _prefsKey = 'theme_mode';

  static Future<void> loadSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    themeModeNotifier.value =
        prefs.getString(_prefsKey) == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
