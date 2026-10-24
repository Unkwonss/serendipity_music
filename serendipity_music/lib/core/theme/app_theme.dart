import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// APP THEME — Serendipity Odyssey Design System
// Cyber-dark, cosmic audio atmosphere with neon photonic glows
// ============================================================

class AppTheme {
  AppTheme._();

  // --- VOID SURFACES ---
  static const Color bgDeep = Color(0xFF0A0A0F);        // Base Canvas Void
  static const Color surface = Color(0xFF131318);       // Core surface
  static const Color surfaceLowest = Color(0xFF0E0E13);
  static const Color surfaceLow = Color(0xFF1B1B20);    // Card substrate low
  static const Color surfaceContainer = Color(0xFF1F1F25);
  static const Color surfaceHigh = Color(0xFF2A292F);   // Elevated panel
  static const Color surfaceHighest = Color(0xFF35343A);// Highest container
  static const Color surfaceBright = Color(0xFF39383E);

  // Backward-compatible aliases
  static const Color bgDark = surfaceLow;
  static const Color bgCard = surfaceContainer;
  static const Color bgElevated = surfaceHigh;

  // --- BRAND & NEON ACCENTS ---
  static const Color primary = Color(0xFFFF6B2C);       // Radiant Electric Orange
  static const Color primaryLight = Color(0xFFFFB59A);  // Primary Fixed Dim
  static const Color primaryDark = Color(0xFF802900);
  static const Color secondary = Color(0xFFEDC157);     // Celestial Gold
  static const Color secondaryFixed = Color(0xFFFFDF9B);
  static const Color tertiary = Color(0xFF00DBE9);      // Neon Cyan / Telemetry
  static const Color tertiaryContainer = Color(0xFF00AAB5);
  static const Color accent = secondary;

  // --- TEXT COLORS ---
  static const Color textPrimary = Color(0xFFE4E1E9);   // Luminous high contrast
  static const Color textSecondary = Color(0xFF9E9EB2); // Muted lilac slate
  static const Color textHint = Color(0xFF6B6B80);      // Ghost / Inactive
  static const Color textOutline = Color(0xFFA98A7F);
  static const Color outlineVariant = Color(0xFF52443D);

  // --- DIVIDER / BORDER ---
  static const Color divider = Color(0xFF2A292F);
  static const Color glassBorder = Color(0x1FFFFFFF);   // rgba(255, 255, 255, 0.08)
  static const Color glassBorderBright = Color(0x33FFFFFF);

  // --- STATUS ---
  static const Color success = Color(0xFF4CAF82);
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color warning = Color(0xFFFFAA00);

  // --- GLASSMORPHISM DECORATIONS ---
  static BoxDecoration glassCardDecoration({
    double radius = 20,
    Color? color,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? surfaceLow.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: glassBorder, width: 1),
      boxShadow: shadows ?? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // Neon Glow for Play / Active triggers
  static List<BoxShadow> primaryGlow({double blur = 24, double spread = 0}) {
    return [
      BoxShadow(
        color: primary.withValues(alpha: 0.45),
        blurRadius: blur,
        spreadRadius: spread,
      ),
      BoxShadow(
        color: primary.withValues(alpha: 0.15),
        blurRadius: blur * 2,
        spreadRadius: spread,
      ),
    ];
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surfaceLow,
        error: error,
        onPrimary: Color(0xFF5B1B00),
        onSecondary: Color(0xFF3F2E00),
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 32,
            letterSpacing: -0.02,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.01,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
          labelSmall: TextStyle(
            color: textHint,
            fontSize: 11,
            letterSpacing: 0.04,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDeep.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.01,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.5), width: 1),
        ),
        hintStyle: const TextStyle(color: textHint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
