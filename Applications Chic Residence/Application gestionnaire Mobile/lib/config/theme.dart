import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette de la maquette du 2026-10-31, commune aux trois applications :
/// fond crème, titres bleu nuit, actions rouge-orangé.
class AppColors {
  AppColors._();

  static const primary = Color(0xFFF04E2E);
  static const primaryDark = Color(0xFFD93D1F);
  static const primaryLight = Color(0xFFFDE7E1);
  static const accent = Color(0xFFF5A623);

  static const surface = Color(0xFFFFF9F2);
  static const surfaceAlt = Color(0xFFF7EFE4);
  static const card = Color(0xFFFFFFFF);
  static const navy = Color(0xFF12294B);
  static const border = Color(0xFFEDE3D6);
  static const text = navy;
  static const textMuted = Color(0xFF66718A);
  static const shadow = Color(0x1F12294B);

  static const success = Color(0xFF16804A);
  static const successSoft = Color(0xFFDDF5E6);
  static const warning = Color(0xFFD98A06);
  static const info = Color(0xFF2F6FDB);
  static const error = Color(0xFFD92D20);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    return base.copyWith(
      // `onSecondary` vaut noir par défaut : un segment ou une puce choisis
      // s'affichaient en noir sur bleu nuit, illisibles.
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.navy,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.navy,
        onSecondaryContainer: Colors.white,
        surface: AppColors.card,
        onSurface: AppColors.text,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.border, width: 1.4),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.navy,
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        checkmarkColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.navy : AppColors.card),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? Colors.white : AppColors.text),
          iconColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? Colors.white : AppColors.text),
          side: WidgetStateProperty.all(
              const BorderSide(color: AppColors.border)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
