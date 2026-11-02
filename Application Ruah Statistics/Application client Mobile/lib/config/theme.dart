import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color brand400 = Color(0xFF12908C);
  static const Color brand500 = Color(0xFF0E8784);
  static const Color brand600 = Color(0xFF0B7A77);
  static const Color brand700 = Color(0xFF096B69);
  static const Color brand800 = Color(0xFF07595A);
  static const Color brandTint = Color(0xFFDDF0EE);

  static const Color navy = Color(0xFF0C2B4B);

  // Les noms « charcoal » restent : tous les écrans les emploient. Ce sont
  // désormais les bleus nuit de la charte.
  static const Color charcoal900 = Color(0xFF0B2340);
  static const Color charcoal800 = Color(0xFF12304F);
  static const Color charcoal700 = Color(0xFF1D3E60);
  static const Color charcoal600 = Color(0xFF2C4F72);

  static const Color accent500 = Color(0xFFF39C1F);

  static const Color lightBg = Color(0xFFFBF6EC);
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0xFFEDE6D8);
  static const Color lightMuted = Color(0xFF52606D);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [charcoal900, charcoal800, charcoal700, brand800],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand800, brand500, brand400],
  );
}

class AppRadius {
  static const double card = 16;
  static const double small = 12;
  static const double large = 24;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTheme {
  static TextTheme _textTheme(Brightness brightness) {
    final Color base =
        brightness == Brightness.dark ? Colors.white : AppColors.charcoal900;
    final Color muted =
        brightness == Brightness.dark ? Colors.white70 : AppColors.lightMuted;

    final TextTheme headings = GoogleFonts.plusJakartaSansTextTheme();
    final TextTheme inter = GoogleFonts.plusJakartaSansTextTheme();

    return TextTheme(
      displayLarge: headings.displayLarge?.copyWith(
        color: base,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: headings.displayMedium?.copyWith(
        color: base,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: headings.displaySmall?.copyWith(
        color: base,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: headings.headlineLarge?.copyWith(
        color: base,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: headings.headlineMedium?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: headings.headlineSmall?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: headings.titleLarge?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
      ),
      titleMedium:
          inter.titleMedium?.copyWith(color: base, fontWeight: FontWeight.w600),
      titleSmall:
          inter.titleSmall?.copyWith(color: base, fontWeight: FontWeight.w600),
      bodyLarge: inter.bodyLarge?.copyWith(color: base),
      bodyMedium: inter.bodyMedium?.copyWith(color: base),
      bodySmall: inter.bodySmall?.copyWith(color: muted),
      labelLarge:
          inter.labelLarge?.copyWith(color: base, fontWeight: FontWeight.w600),
      labelMedium: inter.labelMedium?.copyWith(color: muted),
      labelSmall: inter.labelSmall?.copyWith(color: muted),
    );
  }

  static ThemeData dark() {
    final TextTheme text = _textTheme(Brightness.dark);
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.charcoal900,
      canvasColor: AppColors.charcoal900,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brand500,
        secondary: AppColors.brand400,
        tertiary: AppColors.accent500,
        surface: AppColors.charcoal800,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.charcoal900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.charcoal800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.charcoal700),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _inputTheme(Brightness.dark),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(Brightness.dark),
      textButtonTheme: _textButtonTheme(Brightness.dark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.charcoal800,
        selectedItemColor: AppColors.brand400,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.charcoal700,
        selectedColor: AppColors.brand600,
        labelStyle: text.labelMedium!.copyWith(color: Colors.white),
        secondaryLabelStyle: text.labelMedium!.copyWith(color: Colors.white),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.charcoal700,
        space: 1,
        thickness: 1,
      ),
    );
  }

  static ThemeData light() {
    final TextTheme text = _textTheme(Brightness.light);
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBg,
      canvasColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand600,
        secondary: AppColors.brand500,
        tertiary: AppColors.accent500,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.charcoal900,
      ),
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.charcoal900),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _inputTheme(Brightness.light),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(Brightness.light),
      textButtonTheme: _textButtonTheme(Brightness.light),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.brand600,
        unselectedItemColor: AppColors.lightMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.brand600,
        labelStyle: text.labelMedium!,
        secondaryLabelStyle:
            text.labelMedium!.copyWith(color: Colors.white),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        space: 1,
        thickness: 1,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(Brightness brightness) {
    final Color fill = brightness == Brightness.dark
        ? AppColors.charcoal800
        : Colors.white;
    final Color border = brightness == Brightness.dark
        ? AppColors.charcoal700
        : AppColors.lightBorder;
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: const BorderSide(color: AppColors.brand500, width: 1.5),
      ),
      labelStyle: TextStyle(
        color: brightness == Brightness.dark ? Colors.white70 : AppColors.lightMuted,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand500,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 48),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(Brightness brightness) {
    final Color color = brightness == Brightness.dark
        ? Colors.white
        : AppColors.charcoal900;
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        minimumSize: const Size(0, 48),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(Brightness brightness) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brightness == Brightness.dark
            ? AppColors.brand400
            : AppColors.brand700,
      ),
    );
  }
}
