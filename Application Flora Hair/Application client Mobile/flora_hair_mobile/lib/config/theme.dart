import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette Flora Hair (refonte 2026-10) — bordeaux, rose poudré et or sur
/// fond crème rosé, d'après la maquette validée.
///
/// Les noms historiques (`lime`, `cream`, `charcoal`…) sont conservés et
/// repointés : les écrans secondaires qui les utilisent encore suivent la
/// nouvelle identité sans être réécrits. `lime` désigne donc l'accent principal
/// (bordeaux).
class FloraColors {
  // ── Identité ────────────────────────────────────────────────────────
  static const Color burgundy = Color(0xFF6B1F3A);
  static const Color burgundyDark = Color(0xFF4F132A);
  static const Color blush = Color(0xFFF4C9CE);
  static const Color blushLight = Color(0xFFFBE8E6);
  static const Color gold = Color(0xFFD9A441);
  static const Color cocoa = Color(0xFF3E2723);
  static const Color success = Color(0xFF2E7D4F);
  static const Color successSoft = Color(0xFFDDF0E3);
  static const Color warning = Color(0xFF8A5E0C);
  static const Color warningSoft = Color(0xFFFBEFD5);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerSoft = Color(0xFFF9DEDC);

  // ── Accents (noms historiques) ──────────────────────────────────────
  static const Color lime = burgundy;
  static const Color limeLight = Color(0xFF8A3352);
  static const Color limeDark = burgundyDark;
  static const Color mint = gold;

  // ── Palette CLAIRE — utilisée par le thème par défaut ───────────────
  static const Color background = Color(0xFFFFF7F1);
  static const Color surfaceMuted = blushLight;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2B1A1D);
  static const Color textSecondary = Color(0xFF6F5A5E);
  static const Color textMuted = Color(0xFF8C7A7D);
  static const Color border = Color(0xFFF0E1DC);
  static const Color borderStrong = burgundy;

  // ── Palette SOMBRE ──────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1B1013);
  static const Color darkSurface = Color(0xFF28181D);
  static const Color darkSurfaceMuted = Color(0xFF3A2329);
  static const Color darkTextPrimary = Color(0xFFFBEFEA);
  static const Color darkTextSecondary = Color(0xFFCDB8B8);
  static const Color darkBorder = Color(0xFF4A2F36);
  static const Color darkAccent = blush;

  // ── Alias historiques — repointés sur le mode CLAIR ─────────────────
  static const Color cream = textPrimary;
  static const Color charcoal = surface;
  static const Color dark = background;
  static const Color darkLight = surfaceMuted;
  static const Color grayWarm = border;

  static const Color limeLightMode = lime;
  static const Color creamLightMode = textPrimary;
  static const Color darkLightMode = background;
  static const Color charcoalLightMode = surface;

  // Dégradés communs.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[limeLight, burgundy, burgundyDark],
  );
  static const LinearGradient softGoldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[burgundy, limeLight],
  );
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[blushLight, background],
  );
}

/// Ombre douce commune aux cartes, teintée bordeaux plutôt que noire.
const List<BoxShadow> floraCardShadow = <BoxShadow>[
  BoxShadow(color: Color(0x146B1F3A), blurRadius: 18, offset: Offset(0, 6)),
];

class FloraTheme {
  static const double borderRadius = 14.0;
  static const double cardRadius = 18.0;
  static const double pillRadius = 999.0;

  static TextTheme _textTheme({required Color body, required Color heading}) {
    return TextTheme(
      displayLarge: GoogleFonts.dmSans(
        fontSize: 32, fontWeight: FontWeight.w800, color: heading,
        height: 1.15, letterSpacing: -0.4,
      ),
      displayMedium: GoogleFonts.dmSans(
        fontSize: 26, fontWeight: FontWeight.w800, color: heading,
        height: 1.2, letterSpacing: -0.3,
      ),
      displaySmall: GoogleFonts.dmSans(
        fontSize: 22, fontWeight: FontWeight.w700, color: heading,
        height: 1.25, letterSpacing: -0.2,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 20, fontWeight: FontWeight.w700, color: heading,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 17, fontWeight: FontWeight.w600, color: heading,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15, fontWeight: FontWeight.w600, color: heading,
      ),
      bodyLarge: GoogleFonts.dmSans(fontSize: 15, color: body, height: 1.45),
      bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: body, height: 1.4),
      bodySmall: GoogleFonts.dmSans(fontSize: 12, color: body),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: heading,
      ),
    );
  }

  static ThemeData _themeFrom({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceMuted,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
    required Color primary,
    required Color onPrimary,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: FloraColors.mint,
        onSecondary: onPrimary,
        error: const Color(0xFFE85D75),
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceMuted,
        onSurfaceVariant: textSecondary,
        outline: border,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: FloraColors.cocoa,
        contentTextStyle: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      textTheme: _textTheme(body: textSecondary, heading: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.dmSans(color: textSecondary),
        labelStyle: GoogleFonts.dmSans(color: textPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary,
        secondarySelectedColor: primary,
        labelStyle: GoogleFonts.dmSans(
          color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: GoogleFonts.dmSans(
          color: brightness == Brightness.light ? Colors.white : background,
          fontSize: 13, fontWeight: FontWeight.w600,
        ),
        checkmarkColor: brightness == Brightness.light ? Colors.white : background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          side: BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      splashColor: Colors.transparent,
      highlightColor: surfaceMuted,
    );
  }

  static ThemeData get light => _themeFrom(
        brightness: Brightness.light,
        background: FloraColors.background,
        surface: FloraColors.surface,
        surfaceMuted: FloraColors.surfaceMuted,
        textPrimary: FloraColors.textPrimary,
        textSecondary: FloraColors.textSecondary,
        border: FloraColors.border,
        primary: FloraColors.lime,
        onPrimary: Colors.white,
      );

  static ThemeData get dark => _themeFrom(
        brightness: Brightness.dark,
        background: FloraColors.darkBackground,
        surface: FloraColors.darkSurface,
        surfaceMuted: FloraColors.darkSurfaceMuted,
        textPrimary: FloraColors.darkTextPrimary,
        textSecondary: FloraColors.darkTextSecondary,
        border: FloraColors.darkBorder,
        primary: FloraColors.darkAccent,
        onPrimary: FloraColors.darkBackground,
      );
}
