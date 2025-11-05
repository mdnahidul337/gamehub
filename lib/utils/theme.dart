import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color mainBlue = Color(0xFF007BFF);
  static const Color darkBlue = Color(0xFF0056b3);
  static const Color lightBlue = Color(0xFF3399FF);
  static const Color cyan = Color(0xFF17A2B8);
  static const Color green = Color(0xFF28A745);

  // Neutral Colors
  static const Color darkText = Color(0xFF343A40);
  static const Color grayText = Color(0xFF6C757D);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color background = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [mainBlue, lightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [cyan, green],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [mainBlue, darkBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Text Styles
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.bold, color: darkText),
    displayMedium: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.bold, color: darkText),
    displaySmall: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
    headlineMedium: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
    bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, color: darkText),
    bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, color: grayText),
    labelLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500, color: white),
    titleSmall: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, color: grayText),
  );

  // ThemeData
  static final ThemeData lightTheme = ThemeData(
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
      backgroundColor: white,
      elevation: 1,
      iconTheme: const IconThemeData(color: darkText),
      titleTextStyle: textTheme.headlineMedium,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: white,
        backgroundColor: mainBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        textStyle: textTheme.labelLarge,
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: mainBlue),
      ),
      labelStyle: textTheme.bodyMedium,
      filled: true,
      fillColor: lightGray,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: lightGray.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: mainBlue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: mainBlue,
      secondary: cyan,
      error: error,
      background: Color(0xFF121212),
      onPrimary: white,
      onSecondary: white,
    ),
    textTheme: textTheme.apply(
      bodyColor: white,
      displayColor: white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1F1F1F),
      elevation: 1,
      iconTheme: const IconThemeData(color: white),
      titleTextStyle: textTheme.headlineMedium?.copyWith(color: white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: white,
        backgroundColor: mainBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        textStyle: textTheme.labelLarge,
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: grayText),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: grayText),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: mainBlue),
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(color: white),
      filled: true,
      fillColor: const Color(0xFF1F1F1F),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: const Color(0xFF000000).withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF1F1F1F),
    ),
  );
}
