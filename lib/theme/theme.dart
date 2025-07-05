import 'package:flutter/material.dart';

class RetroSteamTheme {
  static const Color copper = Color(0xFFB87333);
  static const Color brass = Color(0xFF8B5A2B);
  static const Color gold = Color(0xFFD9A441);
  static const Color darkBackground = Color(0xFF1C1C1C);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color crtBlue = Color(0xFF00BFFF);

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.black,
    fontFamily: 'PressStart2P', // ✅ Add this font (see below)
    primaryColor: copper,
    appBarTheme: AppBarTheme(
      backgroundColor: copper,
      foregroundColor: Colors.white,
      elevation: 10,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 14,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brass,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: gold,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: brass,
      selectedColor: gold,
      labelStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 10),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(fontFamily: 'PressStart2P', fontSize: 12),
    ),
  );
}
