import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Food-delivery inspired UI: vibrant green, soft surfaces, rounded cards.
class AppTheme {
  /// Primary green (Foodu-style, inviting).
  static const primary = Color(0xFF28B446);
  static const primaryLight = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF1E8E36);
  static const accentOffer = Color(0xFFFF6B35);

  static const background = Color(0xFFF8F9FB);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1B1B1B);
  static const textMedium = Color(0xFF5C5C5C);
  static const textLight = Color(0xFF9AA0A6);
  static const divider = Color(0xFFECEFF1);
  static const fieldBorder = Color(0xFFE3E6EA);
  static const fieldFill = Color(0xFFF3F4F6);

  /// Card / sheet elevation (soft, Foodu-like).
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1B1B1B).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF28B446).withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static TextTheme get _poppinsTextTheme => GoogleFonts.poppinsTextTheme();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: primaryLight,
          surface: background,
        ),
        scaffoldBackgroundColor: background,
        textTheme: _poppinsTextTheme.apply(
          bodyColor: textDark,
          displayColor: textDark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: textDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            backgroundColor: surface,
            minimumSize: const Size.fromHeight(54),
            side: const BorderSide(color: fieldBorder, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return null;
          }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: fieldFill,
          hintStyle: GoogleFonts.poppins(color: textLight, fontSize: 15),
          labelStyle: GoogleFonts.poppins(color: textMedium, fontSize: 14),
          floatingLabelStyle: GoogleFonts.poppins(color: primary, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 18,
          ),
        ),
      );
}
