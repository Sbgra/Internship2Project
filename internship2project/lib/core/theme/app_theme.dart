import 'package:flutter/material.dart';

/// Medium benzeri minimalist ve temiz aydınlık (light) tema.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFFFFFFFF); // Saf beyaz
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1A8917); // Medium yeşili (vurgu rengi)
  static const Color textPrimary = Color(0xFF292929); // Koyu gri / Siyah
  static const Color textSecondary = Color(0xFF757575); // Orta gri (özetler ve tarihler için)
  static const Color divider = Color(0xFFF2F2F2); // Çok açık, hafif bir çizgi rengi
  static const Color error = Color(0xFFC94A4A);

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surface,
        error: error,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: const BorderSide(color: Colors.transparent),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Medium oval butonları sever
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: textPrimary),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        hintStyle: TextStyle(color: textSecondary),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
