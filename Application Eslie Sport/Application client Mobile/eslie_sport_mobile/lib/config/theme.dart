/// Design system ESLIE SPORT — fond creme, vert profond, orange energie.
///
/// Vert pour l'identite (titres, icones actives, navigation), orange reserve
/// aux actions principales, jaune pour les accents ponctuels (soulignes,
/// badge « Populaire »). Le logo de la salle reste tel quel sur ce fond clair.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Vert ESLIE — identite, icones actives, navigation.
  static const Color primary = Color(0xFF0B4F36);
  static const Color primaryLight = Color(0xFF15754F);
  static const Color primaryDark = Color(0xFF07382A);
  static const Color primarySoft = Color(0xFFE2EFE8);

  // Texte et icones poses sur le vert ou l'orange.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Orange — uniquement les actions principales.
  static const Color accent = Color(0xFFF2681C);
  static const Color accentDark = Color(0xFFD9560F);

  // Jaune — soulignes et badges.
  static const Color yellow = Color(0xFFFFC60B);
  static const Color yellowSoft = Color(0xFFFFF4CC);

  // Fond creme, cartes blanches.
  static const Color bg = Color(0xFFFBF8F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF4F0E6);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEAE5D8);
  static const Color borderStrong = Color(0xFFD8D2C2);

  static const Color textPrimary = Color(0xFF14231C);
  static const Color textSecondary = Color(0xFF55645C);
  static const Color textMuted = Color(0xFF7D8982);

  // Etats.
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color whatsapp = Color(0xFF25D366);

  // Alias historiques, conserves pour les ecrans secondaires.
  static const Color darkCard = surface;
  static const Color darkLighter = surfaceSubtle;
  static const Color darkBorder = border;
  static const Color darkMuted = textSecondary;
  static const Color secondary = textSecondary;

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient heroOverlay = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xE607382A), Color(0x8C07382A), Color(0x1A07382A)],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)
        .apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.primary,
      canvasColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accent,
        onSecondary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.borderStrong,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: TextStyle(color: AppColors.onPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: const BorderSide(color: AppColors.border),
        ),
        side: const BorderSide(color: AppColors.border),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      splashColor: AppColors.primary.withOpacity(0.06),
      highlightColor: AppColors.primary.withOpacity(0.04),
    );
  }
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 24;
  static const double full = 999;
}

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> pill = [
    BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> cta = [
    BoxShadow(color: Color(0x4DF2681C), blurRadius: 16, offset: Offset(0, 6)),
  ];
}
