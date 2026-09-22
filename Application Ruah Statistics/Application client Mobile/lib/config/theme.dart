import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color brand400 = Color(0xFF26C6DA);
  static const Color brand500 = Color(0xFF00BCD4);
  static const Color brand600 = Color(0xFF00ACC1);
  static const Color brand700 = Color(0xFF0097A7);
  static const Color brand800 = Color(0xFF00838F);

  static const Color charcoal900 = Color(0xFF0F0F1A);
  static const Color charcoal800 = Color(0xFF1A1A2E);
  static const Color charcoal700 = Color(0xFF272B45);
  static const Color charcoal600 = Color(0xFF3B3F5A);

  static const Color accent500 = Color(0xFFFFB300);

  static const Color lightBg = Color(0xFFF7F8FB);
  static const Color lightSurface = Colors.white;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A15), charcoal800, charcoal700, brand800],
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
        brightness == Brightness.dark ? Colors.white70 : Colors.black54;

    final TextTheme playfair = GoogleFonts.playfairDisplayTextTheme();
    final TextTheme inter = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: playfair.displayLarge?.copyWith(
        color: base,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: playfair.displayMedium?.copyWith(
        color: base,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: playfair.displaySmall?.copyWith(
        color: base,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: playfair.headlineLarge?.copyWith(
        color: base,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: playfair.headlineMedium?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: playfair.headlineSmall?.copyWith(
        color: base,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: playfair.titleLarge?.copyWith(
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
          side: const BorderSide(color: Color(0xFFE5E7EB)),
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
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEF2F5),
        selectedColor: AppColors.brand500,
        labelStyle: text.labelMedium!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
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
        : const Color(0xFFE5E7EB);
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
        color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
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
