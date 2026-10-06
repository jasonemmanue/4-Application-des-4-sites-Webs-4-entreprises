import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// # Système de thème CHIC RESIDENCE
///
/// ## Pourquoi des tokens plutôt que des couleurs nommées
///
/// La version précédente posait `AppColors.lightText` directement dans les
/// widgets. En mode sombre le texte restait donc **noir sur fond noir** :
/// invisible. Les tokens ci-dessous portent un *rôle* (« texte principal »,
/// « bordure »), pas une valeur — et chaque thème fournit sa propre valeur.
///
/// Règle : **aucun widget ne référence `AppColors.light*` ou `AppColors.dark*`
/// directement.** Il passe par `context.tokens.<rôle>`.
///
/// ```dart
/// // ❌ Ne bascule pas en mode sombre
/// Text('Bonjour', style: TextStyle(color: AppColors.lightText))
///
/// // ✅ Suit le thème
/// Text('Bonjour', style: TextStyle(color: context.tokens.textPrimary))
/// ```
///
/// Les seules exceptions légitimes sont les couleurs qui ne dépendent pas du
/// thème : le texte posé **sur une photo** (toujours blanc, token
/// `textOnPhoto`) et les couleurs d'état (succès / erreur).
class AppColors {
  AppColors._();

  // ── Marque ───────────────────────────────────────────────────────────
  // Rouge Chic Residence. Identique dans les deux thèmes : c'est la marque,
  // elle ne se dilue pas. Seule la variante *claire* sert en mode sombre,
  // pour garder un contraste suffisant sur fond noir.
  static const primary500 = Color(0xFFEF4444);
  static const primary600 = Color(0xFFDC2626);
  static const primary700 = Color(0xFFB91C1C);
  static const primary800 = Color(0xFF991B1B);

  static const accent500 = Color(0xFFF97316);
  static const accent600 = Color(0xFFEA580C);

  // Sable — placeholders d'images uniquement.
  static const sand100 = Color(0xFFFAF3E8);
  static const sand200 = Color(0xFFF5E6D0);
  static const sand500 = Color(0xFFD4A05A);
  static const sand600 = Color(0xFFB6844A);

  // ── États (indépendants du thème) ────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ── Valeurs brutes, réservées à la construction des thèmes ──────────
  // Elles ne doivent pas être lues par les widgets : passer par les tokens.
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceAlt = Color(0xFFF2F2F2);
  // Contour volontairement dense : #EBEBEB puis #DDDDDD disparaissaient sur
  // fond blanc et les pilules semblaient flotter sans encerclement.
  static const _lightBorder = Color(0xFFCFCFCF);
  static const _lightText = Color(0xFF222222);
  static const _lightMuted = Color(0xFF6A6A6A);

  static const _darkSurface = Color(0xFF0F0F10);
  static const _darkSurfaceAlt = Color(0xFF1C1C1E);
  static const _darkSurfaceAlt2 = Color(0xFF323235);
  // Même raison côté sombre : un contour trop proche du fond ne se voit pas.
  static const _darkBorder = Color(0xFF4A4A4E);
  static const _darkText = Color(0xFFF7F7F7);
  static const _darkMuted = Color(0xFFAEAEB2);

  // ── Compatibilité descendante ────────────────────────────────────────
  // Conservés le temps de migrer tous les appels. Ils pointent sur les
  // valeurs du mode clair — donc **faux en mode sombre**. Ne pas en ajouter.
  @Deprecated('Utiliser context.tokens.surface')
  static const lightSurface = _lightSurface;
  @Deprecated('Utiliser context.tokens.surface')
  static const lightBg = _lightSurface;
  @Deprecated('Utiliser context.tokens.border')
  static const lightBorder = _lightBorder;
  @Deprecated('Utiliser context.tokens.textPrimary')
  static const lightText = _lightText;
  @Deprecated('Utiliser context.tokens.textSecondary')
  static const lightMuted = _lightMuted;
  @Deprecated('Utiliser context.tokens.surface')
  static const darkSurface = _darkSurface;
  @Deprecated('Utiliser context.tokens.surfaceElevated')
  static const darkCard = _darkSurfaceAlt;
  @Deprecated('Utiliser context.tokens.border')
  static const darkBorder = _darkBorder;
  @Deprecated('Utiliser context.tokens.textPrimary')
  static const darkText = _darkText;
  @Deprecated('Utiliser context.tokens.textSecondary')
  static const darkMuted = _darkMuted;
}

/// Tokens sémantiques — un jeu par thème, accessibles via `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.brightness,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnPhoto,
    required this.border,
    required this.borderStrong,
    required this.chipBg,
    required this.chipBgSelected,
    required this.navBg,
    required this.pillBg,
    required this.pillText,
    required this.ctaBg,
    required this.ctaFg,
    required this.brand,
    required this.imagePlaceholder,
    required this.shadow,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  /// Permet aux widgets de tester `isDark` sans relire `Theme.of`.
  final Brightness brightness;
  bool get isDark => brightness == Brightness.dark;

  /// Fond des écrans.
  final Color surface;

  /// Fond des surfaces posées au-dessus (cards, barres, feuilles).
  final Color surfaceElevated;

  /// Fond légèrement enfoncé (champ de recherche inline, chip active).
  final Color surfaceSunken;

  /// Texte principal — noir en clair, presque blanc en sombre.
  final Color textPrimary;

  /// Texte atténué (sous-titres, prix, légendes).
  final Color textSecondary;

  /// Texte et icônes posés **sur une photo** — blanc dans les deux thèmes.
  final Color textOnPhoto;

  /// Bordure standard. Volontairement dense (#DDDDDD / #3A3A3C) : une
  /// bordure trop pâle disparaît et les chips perdent leur « encerclement ».
  final Color border;

  /// Bordure accentuée — chip sélectionnée, champ focus.
  final Color borderStrong;

  final Color chipBg;
  final Color chipBgSelected;

  /// Fond de la barre de navigation basse.
  final Color navBg;

  /// Badge flottant (« Prix TTC inclus », « Coup de cœur »).
  final Color pillBg;
  final Color pillText;

  /// Bouton d'action principal — noir sur blanc en clair, **inversé** en
  /// sombre (blanc sur noir), comme le fait Airbnb.
  final Color ctaBg;
  final Color ctaFg;

  /// Rouge de marque, ajusté pour rester lisible sur chaque fond.
  final Color brand;

  final Color imagePlaceholder;
  final Color shadow;
  final Color skeletonBase;
  final Color skeletonHighlight;

  static const light = AppTokens(
    brightness: Brightness.light,
    surface: AppColors._lightSurface,
    surfaceElevated: AppColors._lightSurface,
    surfaceSunken: AppColors._lightSurfaceAlt,
    textPrimary: AppColors._lightText,
    textSecondary: AppColors._lightMuted,
    textOnPhoto: Colors.white,
    border: AppColors._lightBorder,
    borderStrong: AppColors._lightText,
    chipBg: AppColors._lightSurface,
    chipBgSelected: AppColors._lightSurfaceAlt,
    navBg: AppColors._lightSurface,
    pillBg: AppColors._lightSurface,
    pillText: AppColors._lightText,
    ctaBg: AppColors._lightText,
    ctaFg: Colors.white,
    brand: AppColors.primary600,
    imagePlaceholder: AppColors.sand100,
    // Ombre plus marquée qu'un simple 0x1F : c'est elle qui détache les
    // pilules du fond blanc et complète l'encerclement.
    shadow: Color(0x2E000000),
    skeletonBase: Color(0xFFE8E8E8),
    skeletonHighlight: Color(0xFFF5F5F5),
  );

  static const dark = AppTokens(
    brightness: Brightness.dark,
    surface: AppColors._darkSurface,
    surfaceElevated: AppColors._darkSurfaceAlt,
    surfaceSunken: AppColors._darkSurfaceAlt2,
    textPrimary: AppColors._darkText,
    textSecondary: AppColors._darkMuted,
    textOnPhoto: Colors.white,
    border: AppColors._darkBorder,
    borderStrong: AppColors._darkText,
    chipBg: AppColors._darkSurfaceAlt,
    chipBgSelected: AppColors._darkSurfaceAlt2,
    navBg: Color(0xFF161618),
    pillBg: AppColors._darkSurfaceAlt,
    pillText: AppColors._darkText,
    // CTA inversé : blanc sur fond sombre.
    ctaBg: AppColors._darkText,
    ctaFg: AppColors._darkSurface,
    // primary500 plutôt que 600 : le rouge foncé manque de contraste sur noir.
    brand: AppColors.primary500,
    imagePlaceholder: Color(0xFF232325),
    shadow: Color(0x66000000),
    skeletonBase: Color(0xFF1F1F21),
    skeletonHighlight: Color(0xFF2A2A2D),
  );

  @override
  AppTokens copyWith({
    Brightness? brightness,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceSunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? textOnPhoto,
    Color? border,
    Color? borderStrong,
    Color? chipBg,
    Color? chipBgSelected,
    Color? navBg,
    Color? pillBg,
    Color? pillText,
    Color? ctaBg,
    Color? ctaFg,
    Color? brand,
    Color? imagePlaceholder,
    Color? shadow,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppTokens(
      brightness: brightness ?? this.brightness,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textOnPhoto: textOnPhoto ?? this.textOnPhoto,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      chipBg: chipBg ?? this.chipBg,
      chipBgSelected: chipBgSelected ?? this.chipBgSelected,
      navBg: navBg ?? this.navBg,
      pillBg: pillBg ?? this.pillBg,
      pillText: pillText ?? this.pillText,
      ctaBg: ctaBg ?? this.ctaBg,
      ctaFg: ctaFg ?? this.ctaFg,
      brand: brand ?? this.brand,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      shadow: shadow ?? this.shadow,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textOnPhoto: c(textOnPhoto, other.textOnPhoto),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      chipBg: c(chipBg, other.chipBg),
      chipBgSelected: c(chipBgSelected, other.chipBgSelected),
      navBg: c(navBg, other.navBg),
      pillBg: c(pillBg, other.pillBg),
      pillText: c(pillText, other.pillText),
      ctaBg: c(ctaBg, other.ctaBg),
      ctaFg: c(ctaFg, other.ctaFg),
      brand: c(brand, other.brand),
      imagePlaceholder: c(imagePlaceholder, other.imagePlaceholder),
      shadow: c(shadow, other.shadow),
      skeletonBase: c(skeletonBase, other.skeletonBase),
      skeletonHighlight: c(skeletonHighlight, other.skeletonHighlight),
    );
  }
}

/// Hauteur de la barre de navigation basse, hors encoche système.
/// Définie ici plutôt que dans `MainShell` pour que les écrans puissent
/// réserver le dégagement correspondant sans dépendre de lui.
const double kBottomNavHeight = 64;

/// Raccourci : `context.tokens.textPrimary`.
///
/// Retombe sur le jeu clair si l'extension n'est pas enregistrée — ce qui
/// n'arrive qu'en test avec un `ThemeData` nu.
extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;

  /// Dégagement à réserver en bas d'une liste défilante pour que son dernier
  /// élément ne finisse pas sous la barre de navigation.
  ///
  /// Le `Scaffold` de `MainShell` place bien son `body` au-dessus de la
  /// `bottomNavigationBar`, mais les écrans d'onglet ont leur **propre**
  /// `Scaffold` : leur `MediaQuery` ignore la barre du parent, et le dernier
  /// élément d'une `ListView` se retrouve masqué. D'où ce dégagement
  /// explicite.
  ///
  /// [extra] sert aux écrans qui superposent un élément flottant — la Home et
  /// son bandeau « Prix TTC inclus », par exemple.
  double bottomInset([double extra = 0]) =>
      kBottomNavHeight + MediaQuery.viewPaddingOf(this).bottom + 16 + extra;
}

class AppGradients {
  AppGradients._();

  static const primary = LinearGradient(
    colors: [
      AppColors.primary800,
      AppColors.primary600,
      AppColors.primary500,
      AppColors.accent500,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accent = LinearGradient(
    colors: [AppColors.primary500, AppColors.accent600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gold = LinearGradient(
    colors: [AppColors.sand500, Color(0xFFE2B97E), AppColors.sand200],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppTokens.light);
  static ThemeData dark() => _build(AppTokens.dark);

  /// Construit un `ThemeData` **entièrement dérivé des tokens**. Les deux
  /// modes partagent donc la même structure : ajouter un token suffit à le
  /// rendre disponible des deux côtés, sans dupliquer la configuration.
  static ThemeData _build(AppTokens t) {
    final base = ThemeData(useMaterial3: true, brightness: t.brightness);
    final textTheme = _textTheme(base.textTheme, t);

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[t],
      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: t.brand,
        onPrimary: Colors.white,
        secondary: AppColors.accent500,
        onSecondary: Colors.white,
        tertiary: AppColors.sand500,
        onTertiary: Colors.white,
        surface: t.surfaceElevated,
        onSurface: t.textPrimary,
        surfaceContainerHighest: t.surfaceSunken,
        onSurfaceVariant: t.textSecondary,
        outline: t.border,
        outlineVariant: t.border,
        error: AppColors.error,
        onError: Colors.white,
        shadow: t.shadow,
      ),
      scaffoldBackgroundColor: t.surface,
      canvasColor: t.surface,
      cardColor: t.surfaceElevated,
      dividerColor: t.border,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: t.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: t.surface,
        foregroundColor: t.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: t.textPrimary),
        titleTextStyle: textTheme.titleLarge,
      ),
      // Aligné sur `AppCard` : même rayon, même épaisseur de bordure. Les
      // `Card` Material et les cadres maison doivent être indiscernables.
      cardTheme: CardThemeData(
        color: t.surfaceElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: t.border, width: 1.2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: t.textPrimary,
        iconColor: t.textPrimary,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: t.textSecondary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: t.surfaceElevated,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.isDark ? t.surfaceSunken : t.textPrimary,
        contentTextStyle: TextStyle(
          color: t.isDark ? t.textPrimary : t.surface,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: _inputTheme(t),
      elevatedButtonTheme: _elevatedBtn(t),
      filledButtonTheme: _filledBtn(t),
      outlinedButtonTheme: _outlinedBtn(t),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: t.textPrimary),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? t.chipBgSelected : t.chipBg),
          foregroundColor: WidgetStateProperty.all(t.textPrimary),
          side: WidgetStateProperty.all(BorderSide(color: t.border)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.chipBg,
        selectedColor: t.chipBgSelected,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: t.textPrimary,
        ),
        side: BorderSide(color: t.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: t.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.brand),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppTokens t) {
    // Une seule famille — Inter — la hiérarchie vient de la graisse, comme
    // chez Airbnb. Chaque style porte explicitement `t.textPrimary` : sans
    // ça, Material retombe sur le noir du thème clair.
    final sans = GoogleFonts.interTextTheme(base);
    final c = t.textPrimary;
    return base.copyWith(
      displayLarge: sans.displayLarge
          ?.copyWith(color: c, fontWeight: FontWeight.w800, letterSpacing: -1.5),
      displayMedium: sans.displayMedium
          ?.copyWith(color: c, fontWeight: FontWeight.w800, letterSpacing: -1),
      displaySmall: sans.displaySmall
          ?.copyWith(color: c, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineLarge: sans.headlineLarge
          ?.copyWith(color: c, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium:
          sans.headlineMedium?.copyWith(color: c, fontWeight: FontWeight.w800),
      headlineSmall:
          sans.headlineSmall?.copyWith(color: c, fontWeight: FontWeight.w700),
      titleLarge: sans.titleLarge?.copyWith(color: c, fontWeight: FontWeight.w700),
      titleMedium:
          sans.titleMedium?.copyWith(color: c, fontWeight: FontWeight.w600),
      titleSmall: sans.titleSmall?.copyWith(color: c, fontWeight: FontWeight.w600),
      bodyLarge: sans.bodyLarge?.copyWith(color: c),
      bodyMedium: sans.bodyMedium?.copyWith(color: c),
      bodySmall: sans.bodySmall?.copyWith(color: t.textSecondary),
      labelLarge: sans.labelLarge?.copyWith(color: c, fontWeight: FontWeight.w600),
      labelMedium:
          sans.labelMedium?.copyWith(color: c, fontWeight: FontWeight.w500),
      labelSmall: sans.labelSmall?.copyWith(color: t.textSecondary),
    );
  }

  static InputDecorationTheme _inputTheme(AppTokens t) {
    return InputDecorationTheme(
      filled: true,
      fillColor: t.surfaceElevated,
      hintStyle: TextStyle(color: t.textSecondary),
      labelStyle: TextStyle(color: t.textSecondary),
      floatingLabelStyle: TextStyle(color: t.textPrimary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.borderStrong, width: 1.5),
      ),
    );
  }

  /// CTA principal — noir sur blanc en clair, blanc sur noir en sombre.
  static ElevatedButtonThemeData _elevatedBtn(AppTokens t) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.ctaBg,
          foregroundColor: t.ctaFg,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      );

  static FilledButtonThemeData _filledBtn(AppTokens t) => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  static OutlinedButtonThemeData _outlinedBtn(AppTokens t) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          side: BorderSide(color: t.border),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}
