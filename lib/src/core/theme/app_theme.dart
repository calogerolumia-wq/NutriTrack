import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF4D7A),
      brightness: Brightness.light,
    ).copyWith(
      secondary: const Color(0xFF2F7CFF),
      tertiary: const Color(0xFFFFB703),
      surface: const Color(0xFFFFFBFF),
      surfaceContainerHighest: const Color(0xFFF2EEFF),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF8F6FF),
      cardTheme: base.cardTheme.copyWith(
        elevation: 2,
        margin: EdgeInsets.zero,
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF5E86),
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFF6AA8FF),
      tertiary: const Color(0xFFFFC94A),
      surface: const Color(0xFF151628),
      surfaceContainerHighest: const Color(0xFF252744),
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );
    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFF0E1024),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: const Color(0xFF1A1C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2242),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF15172E),
        indicatorColor: colorScheme.primaryContainer.withOpacity(0.7),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
