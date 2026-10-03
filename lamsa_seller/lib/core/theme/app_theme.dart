import 'package:flutter/material.dart';

// ==========================================
// 1. ألوان الوضع الفاتح
// ==========================================
class AppColors {
  static const primary = Color(0xFFE63946);
  static const dark = Color(0xFF1D1D1F);
  static const background = Color(0xFFFAFAFA);
  static const accent = Color(0xFFF4A261);
  static const grey = Color(0xFF8E8E93);
  static const lightGrey = Color(0xFFF0F0F0);
  static const success = Color(0xFF2A9D8F);
  static const white = Color(0xFFFFFFFF);
}

// ==========================================
// 2. ألوان الوضع الداكن
// ==========================================
class AppDarkColors {
  static const primary = Color(0xFFE63946);
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const text = Color(0xFFF5F5F5);
  static const grey = Color(0xFFA0A0A0);
  static const lightGrey = Color(0xFF2A2A2A);
}

// ==========================================
// 3. إعدادات الثيم
// ==========================================
class AppTheme {
  
  // --- الثيم الفاتح ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'IBMPlexSansArabic', // ✅ الخط الجديد
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        background: AppColors.background,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'IBMPlexSansArabic'),
        bodyMedium: TextStyle(fontFamily: 'IBMPlexSansArabic'),
        titleLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
        labelLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.dark),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700, // ✅ يتوافق مع ملف Bold
          color: AppColors.dark,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'IBMPlexSansArabic',
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.grey, fontFamily: 'IBMPlexSansArabic'),
      ),
    );
  }

  // --- الثيم الداكن ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'IBMPlexSansArabic', // ✅ الخط الجديد
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppDarkColors.background,
      primaryColor: AppDarkColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppDarkColors.primary,
        brightness: Brightness.dark,
        primary: AppDarkColors.primary,
        surface: AppDarkColors.surface,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppDarkColors.text),
        bodyMedium: TextStyle(fontFamily: 'IBMPlexSansArabic', color: AppDarkColors.text),
        titleLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700, color: AppDarkColors.text),
        titleMedium: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600, color: AppDarkColors.text),
        labelLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700, color: AppDarkColors.text),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDarkColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppDarkColors.text),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppDarkColors.text,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
      cardTheme: CardThemeData(
        color: AppDarkColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDarkColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'IBMPlexSansArabic',
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDarkColors.lightGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppDarkColors.grey, fontFamily: 'IBMPlexSansArabic'),
      ),
    );
  }
}

// ==========================================
// 4. الثوابت
// ==========================================
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppRadius {
  static const double small = 10.0;
  static const double medium = 16.0;
  static const double large = 24.0;
}