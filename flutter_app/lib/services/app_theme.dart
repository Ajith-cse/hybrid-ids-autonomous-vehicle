import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg         = Color(0xFF0A0E1A);
  static const Color surface    = Color(0xFF131929);
  static const Color card       = Color(0xFF1C2438);
  static const Color accent     = Color(0xFF00E5FF);
  static const Color accentSoft = Color(0xFF1DE9B6);
  static const Color danger     = Color(0xFFFF3D57);
  static const Color dangerSoft = Color(0xFFFF6B6B);
  static const Color safe       = Color(0xFF00E676);
  static const Color textPri    = Color(0xFFECEFF1);
  static const Color textSec    = Color(0xFF90A4AE);
  static const Color border     = Color(0xFF2A3550);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentSoft,
          error: danger,
          surface: surface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: textPri,
          displayColor: textPri,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: textPri,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          iconTheme: const IconThemeData(color: accent),
        ),
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 0.8),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: accent,
          unselectedItemColor: textSec,
          elevation: 0,
        ),
      );
}
