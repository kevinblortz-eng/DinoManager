import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Palette de couleurs principale ───
  static const Color bgPrimary = Color(0xFF0D1117);
  static const Color bgSecondary = Color(0xFF161B22);
  static const Color bgCard = Color(0xFF1C2333);
  static const Color bgCardHover = Color(0xFF21273B);

  // Accents chauds
  static const Color accentPrimary = Color(0xFFFF6B00);
  static const Color accentSecondary = Color(0xFFD4A853);
  static const Color accentGreen = Color(0xFF5A8A4A);
  static const Color accentCream = Color(0xFFE8DCC8);
  static const Color accentBrown = Color(0xFF8B6540);

  // Texte
  static const Color textPrimary = Color(0xFFE8DCC8);
  static const Color textSecondary = Color(0xFF9BA8BC);
  static const Color textMuted = Color(0xFF6B7A8D);

  // Bordures et séparateurs
  static const Color borderColor = Color(0xFF2D3748);
  static const Color borderAccent = Color(0xFF4A3728);

  // Statuts
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFD700);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF4FC3F7);

  // ─── Aliases de compatibilité ───
  static const Color backgroundColor = bgPrimary;
  static const Color surfaceColor = bgSecondary;
  static const Color cardColor = bgCard;
  static const Color accentColor = accentPrimary;
  static const Color primaryColor = accentPrimary;

  // ─── Gradients ───
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1207), Color(0xFF0D1117), Color(0xFF0D1117)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C2333), Color(0xFF161B22)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF6B00), Color(0xFFD4A853)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF3D6B2E), Color(0xFF5A8A4A)],
  );

  // ─── Thème Material principal ───
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: bgSecondary,
        onPrimary: Colors.white,
        onSecondary: bgPrimary,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.exoTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.cinzelDecorative(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.cinzelDecorative(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.exo2(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        titleMedium: GoogleFonts.exo2(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.exo2(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.exo2(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.exo2(
          color: textSecondary,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.exo2(
          color: textMuted,
          fontSize: 12,
        ),
        labelLarge: GoogleFonts.exo2(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgSecondary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cinzelDecorative(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSecondary,
        selectedItemColor: accentPrimary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 4,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSecondary,
        labelStyle: GoogleFonts.exo2(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.exo2(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.exo2(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPrimary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgSecondary,
        selectedColor: const Color(0x4DFF6B00), // accentPrimary avec alpha 0.30
        secondarySelectedColor: accentPrimary,
        labelStyle: GoogleFonts.exo2(color: textPrimary, fontSize: 12),
        secondaryLabelStyle: GoogleFonts.exo2(color: Colors.white, fontSize: 12),
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle: GoogleFonts.exo2(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme => theme;
}
