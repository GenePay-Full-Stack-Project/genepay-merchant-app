import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme() {
    final base = ThemeData.light();

    return base.copyWith(
      primaryColor: const Color(0xFF1E1E8B),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700),
        displaySmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      // Ensure default font family is Poppins via GoogleFonts
      // Widgets that use explicit TextStyle without fontFamily will inherit this.
      // For widgets that set fontFamily explicitly (e.g. 'FigmaFont') we'll remove that override.
    );
  }
}
