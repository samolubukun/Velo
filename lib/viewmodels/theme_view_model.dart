import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeViewModel extends ChangeNotifier {
  static const String _key = 'velo_theme_override';

  // null = follow system, true = dark, false = light
  bool? _isDark;

  ThemeViewModel() {
    _load();
  }

  bool? get isDarkOverride => _isDark;

  ThemeMode get themeMode {
    if (_isDark == null) return ThemeMode.system;
    return _isDark! ? ThemeMode.dark : ThemeMode.light;
  }

  /// Returns true if the effective mode is dark, given the system brightness
  bool effectiveIsDark(Brightness systemBrightness) {
    if (_isDark != null) return _isDark!;
    return systemBrightness == Brightness.dark;
  }

  Future<void> setDark(bool value) async {
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  Future<void> toggleTheme() async {
    final newVal = !(_isDark ?? false);
    await setDark(newVal);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_key)) {
      _isDark = prefs.getBool(_key);
    }
    // else null = follow system
    notifyListeners();
  }
}
