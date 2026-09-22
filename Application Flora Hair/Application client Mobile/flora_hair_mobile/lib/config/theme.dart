import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette Flora Hair — deux thèmes cohérents, dérivés du logo :
///
/// - **Clair** (défaut) : crème `#FBF8F0` en fond, chocolat `#1A1510` en
///   texte, or `#C5A55A` en accent. Aspect « lounge doré » du salon.
/// - **Sombre** : chocolat très sombre `#12100C` en fond, crème `#F5F0E1`
///   en texte, or clair `#D4BA78` en accent — le contraste inverse pour
///   une lecture confortable de nuit sans changer l'identité.
///
/// Règle : les widgets ne lisent PLUS `FloraColors` en dur. Ils passent
/// par `Theme.of(context)` (colorScheme + textTheme). C'est ce qui
/// garantit que basculer le mode se propage sans revisiter chaque écran.
///
/// Les constantes historiques (`charcoal`, `cream`, `dark`, `grayWarm`…)
/// sont conservées mais **repointées sur les valeurs du thème CLAIR** :
/// tout écran qui les utilisait encore reste lisible dans le mode par
/// défaut, sans casser la compilation. À long terme, ces constantes
/// sont à retirer au profit de `Theme.of(context)`.
class FloraColors {
  // ── Accents Flora Hair (or, partagés entre les deux modes) ──────────
  static const Color lime = Color(0xFFC5A55A);
  static const Color limeLight = Color(0xFFD4BA78);
  static const Color limeDark = Color(0xFFA88B3D);
  static const Color mint = Color(0xFFD4A853);

  // ── Palette CLAIRE — utilisée par le thème par défaut ───────────────
  /// Fond des scaffolds : crème pâle du logo.
  static const Color background = Color(0xFFFBF8F0);
  /// Surface légèrement teintée (chips, pill de recherche, avatars).
  static const Color surfaceMuted = Color(0xFFF0EBD8);
  /// Cartes surélevées : blanc pur, tranche sur le crème.
  static const Color surface = Color(0xFFFFFFFF);
  /// Texte principal : chocolat sombre chaud.
  static const Color textPrimary = Color(0xFF1A1510);
  /// Texte secondaire (prix, meta, sous-titres).
  static const Color textSecondary = Color(0xFF6B5A3D);
  /// Texte grisé (placeholders).
  static const Color textMuted = Color(0xFFA88B3D);
  /// Trait fin, séparateurs.
  static const Color border = Color(0xFFE7DFCB);
  /// Bordure marquée (chip actif).
  static const Color borderStrong = Color(0xFF1A1510);

  // ── Palette SOMBRE — utilisée par le thème dark ─────────────────────
  static const Color darkBackground = Color(0xFF12100C);
  static const Color darkSurface = Color(0xFF1E1B16);
  static const Color darkSurfaceMuted = Color(0xFF2A2318);
  static const Color darkTextPrimary = Color(0xFFF5F0E1);
  static const Color darkTextSecondary = Color(0xFFB8AC8C);
  static const Color darkBorder = Color(0xFF3A3328);
  static const Color darkAccent = Color(0xFFD4BA78); // or clair, +contraste

  // ── Alias historiques — repointés sur le mode CLAIR ─────────────────
  //
  // Ces noms viennent d'un ancien design 100 % sombre. Ils restent
  // utilisés par une vingtaine d'écrans qui n'ont pas encore migré vers
  // `Theme.of(context)`. En les repointant sur les valeurs claires, les
  // écrans historiques cessent d'afficher un fond chocolat sur fond
  // crème (le bug rapporté sur la page « Services »).
  static const Color cream = textPrimary;       // ex-texte clair → chocolat
  static const Color charcoal = surface;         // ex-fond carte → blanc
  static const Color dark = background;          // ex-fond principal → crème
  static const Color darkLight = surfaceMuted;   // ex-surface elevée → crème+
  static const Color grayWarm = border;          // ex-bordure sombre → or clair

  // Compat rétro déjà utilisée ailleurs.
  static const Color limeLightMode = lime;
  static const Color creamLightMode = textPrimary;
  static const Color darkLightMode = background;
  static const Color charcoalLightMode = surface;

  // Dégradés or, communs.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[limeLight, lime, limeDark],
  );
  static const LinearGradient softGoldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[lime, mint],
  );
}

class FloraTheme {
  static const double borderRadius = 12.0;
  static const double cardRadius = 14.0;
  static const double pillRadius = 999.0;

  static TextTheme _textTheme({required Color body, required Color heading}) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32, fontWeight: FontWeight.w800, color: heading,
        height: 1.15, letterSpacing: -0.4,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 26, fontWeight: FontWeight.w800, color: heading,
        height: 1.2, letterSpacing: -0.3,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 22, fontWeight: FontWeight.w700, color: heading,
        height: 1.25, letterSpacing: -0.2,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w700, color: heading,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17, fontWeight: FontWeight.w600, color: heading,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600, color: heading,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: body, height: 1.45),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: body, height: 1.4),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: body),
      labelLarge: GoogleFonts.inter(
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
      textTheme: _textTheme(body: textSecondary, heading: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
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
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: textSecondary),
        labelStyle: GoogleFonts.inter(color: textPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide(color: textPrimary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: brightness == Brightness.light ? Colors.white : background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
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
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: textPrimary,
        secondarySelectedColor: textPrimary,
        labelStyle: GoogleFonts.inter(
          color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
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
