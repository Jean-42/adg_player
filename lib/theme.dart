import 'package:flutter/material.dart';

class AppColors {
  static const bg0   = Color(0xFF0a0a0f);
  static const bg1   = Color(0xFF12121a);
  static const bg2   = Color(0xFF1a1a26);
  static const bg3   = Color(0xFF22223a);
  static const bg4   = Color(0xFF2c2c46);

  static const accent  = Color(0xFF6c63ff);
  static const accent2 = Color(0xFFa78bfa);

  static const text1 = Color(0xFFf0f0ff);
  static const text2 = Color(0xFFa0a0c0);
  static const text3 = Color(0xFF606080);

  static const border  = Color(0x14ffffff);
  static const border2 = Color(0x22ffffff);

  static const red    = Color(0xFFf87171);
  static const blue   = Color(0xFF60a5fa);
  static const green  = Color(0xFF34d399);
  static const yellow = Color(0xFFfbbf24);
  static const pink   = Color(0xFFf472b6);

  // Platform colours
  static const youtube     = Color(0xFFff0000);
  static const vimeo       = Color(0xFF1ab7ea);
  static const dailymotion = Color(0xFF0066dc);
  static const facebook    = Color(0xFF1877f2);
  static const instagram   = Color(0xFFc32aa3);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg0,
      colorScheme: const ColorScheme.dark(
        surface:   AppColors.bg1,
        primary:   AppColors.accent,
        secondary: AppColors.accent2,
        error:     AppColors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg1,
        foregroundColor: AppColors.text1,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg1,
        selectedItemColor: AppColors.accent2,
        unselectedItemColor: AppColors.text3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg2,
        hintStyle: const TextStyle(color: AppColors.text3, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge:   TextStyle(color: AppColors.text1, fontSize: 14),
        bodyMedium:  TextStyle(color: AppColors.text2, fontSize: 13),
        bodySmall:   TextStyle(color: AppColors.text3, fontSize: 11),
        labelLarge:  TextStyle(color: AppColors.text1, fontSize: 12, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.text1, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      dividerColor: AppColors.border,
    );
