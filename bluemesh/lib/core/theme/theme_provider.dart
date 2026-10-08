import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'app_theme_mode';
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePrefKey) ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, _themeMode == ThemeMode.dark);
  }

  // --- Dark Theme (Deep Sleek Slate / Cyber Aesthetic) ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0F19),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF38BDF8), // Cyan blue
      secondary: Color(0xFF10B981), // Emerald green
      tertiary: Color(0xFFF59E0B), // Amber
      error: Color(0xFFEF4444),
      surface: Color(0xFF131C2E),
      onPrimary: Colors.black,
      onSurface: Colors.white,
    ),
    cardColor: const Color(0xFF131C2E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B0F19),
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.white12,
      thickness: 1,
    ),
  );

  // --- Light Theme (Clean Material 3 Academic Slate) ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF059669),
      tertiary: Color(0xFFD97706),
      error: Color(0xFFDC2626),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Color(0xFF0F172A),
    ),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
    ),
  );
}
