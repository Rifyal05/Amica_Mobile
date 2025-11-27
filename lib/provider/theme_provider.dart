import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'themeMode';

  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider(this._themeMode);

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    } else {
      return _themeMode == ThemeMode.dark;
    }
  }

  Future<void> toggleTheme() async {
    final newThemeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newThemeMode);
  }

  Future<void> setThemeMode(ThemeMode newThemeMode) async {
    if (_themeMode == newThemeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, newThemeMode.index);
  }
}
