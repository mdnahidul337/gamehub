import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color mainBlue = Color(0xFF2563eb);
  static const Color darkBlue = Color(0xFF1d4ed8);
  static const Color lightBlue = Color(0xFF3b82f6);
  static const Color cyan = Color(0xFF06b6d4);
  static const Color green = Color(0xFF10b981);

  // Neutral Colors
  static const Color darkText = Color(0xFF1f2937);
  static const Color grayText = Color(0xFF6b7280);
  static const Color lightGray = Color(0xFFe5e7eb);
  static const Color background = Color(0xFFf8fafc);
  static const Color white = Color(0xFFffffff);

  // Status Colors
  static const Color success = Color(0xFF22c55e);
  static const Color warning = Color(0xFFf59e0b);
  static const Color error = Color(0xFFef4444);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [mainBlue, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [cyan, green],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Text Styles
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: darkText),
    displayMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: darkText),
    displaySmall: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
    headlineMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
    bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: darkText),
    bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: grayText),
    labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: white),
    titleSmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: grayText),
  );

  // ThemeData
  static final ThemeData themeData = ThemeData(
    primaryColor: mainBlue,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: mainBlue,
      secondary: cyan,
      error: error,
      background: background,
      onPrimary: white,
      onSecondary: white,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      iconTheme: const IconThemeData(color: darkText),
      titleTextStyle: textTheme.headlineMedium,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: textTheme.labelLarge,
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return lightGray;
            }
            return mainBlue;
          },
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: mainBlue),
      ),
      labelStyle: textTheme.bodyMedium,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: lightGray.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
