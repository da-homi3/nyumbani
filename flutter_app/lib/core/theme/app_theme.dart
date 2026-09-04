import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nyumbasearch/core/theme/nyumba_tokens.dart';

/// NyumbaSearch theme — warm brown/cream light default; green obsidian dark mode.
class AppTheme {
  const AppTheme._();

  static TextTheme _textTheme(Brightness brightness, TextTheme base) {
    final display = GoogleFonts.syneTextTheme(base);
    final body = GoogleFonts.manropeTextTheme(base);
    final onSurface = brightness == Brightness.dark
        ? NyumbaTokens.foregroundDark
        : NyumbaTokens.foregroundLight;
    final muted = brightness == Brightness.dark
        ? NyumbaTokens.mutedForegroundDark
        : NyumbaTokens.mutedForegroundLight;

    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: onSurface),
      bodyMedium: body.bodyMedium?.copyWith(color: onSurface),
      bodySmall: body.bodySmall?.copyWith(color: muted),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: body.labelMedium?.copyWith(color: muted),
      labelSmall: body.labelSmall?.copyWith(color: muted),
    );
  }

  static ThemeData light() {
    const brightness = Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: NyumbaTokens.primaryLight,
      onPrimary: NyumbaTokens.ivory,
      primaryContainer: NyumbaTokens.primaryGlowLight,
      onPrimaryContainer: Colors.white,
      secondary: NyumbaTokens.gold,
      onSecondary: NyumbaTokens.goldForeground,
      secondaryContainer: NyumbaTokens.mutedLight,
      onSecondaryContainer: NyumbaTokens.foregroundLight,
      tertiary: NyumbaTokens.cocoa,
      onTertiary: Colors.white,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      surface: NyumbaTokens.cardLight,
      onSurface: NyumbaTokens.foregroundLight,
      surfaceContainerHighest: NyumbaTokens.mutedLight,
      onSurfaceVariant: NyumbaTokens.mutedForegroundLight,
      outline: NyumbaTokens.borderLight,
      outlineVariant: NyumbaTokens.borderLight,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: NyumbaTokens.backgroundLight,
    );

    return base.copyWith(
      textTheme: _textTheme(brightness, base.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: NyumbaTokens.backgroundLight.withValues(alpha: 0.92),
        foregroundColor: NyumbaTokens.foregroundLight,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: NyumbaTokens.foregroundLight,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: NyumbaTokens.cardLight,
        shadowColor: const Color(0xFF111827).withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: NyumbaTokens.borderRadiusLg),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NyumbaTokens.mutedLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NyumbaTokens.space4,
          vertical: NyumbaTokens.space3,
        ),
        border: OutlineInputBorder(borderRadius: NyumbaTokens.borderRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: NyumbaTokens.borderRadius,
          borderSide: const BorderSide(color: NyumbaTokens.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NyumbaTokens.borderRadius,
          borderSide: const BorderSide(color: NyumbaTokens.primaryLight, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: NyumbaTokens.primaryLight,
          foregroundColor: NyumbaTokens.ivory,
          elevation: 0,
          shadowColor: NyumbaTokens.primaryLight.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: NyumbaTokens.borderRadius),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: NyumbaTokens.primaryLight,
          side: const BorderSide(color: NyumbaTokens.primaryLight),
          shape: RoundedRectangleBorder(borderRadius: NyumbaTokens.borderRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        backgroundColor: NyumbaTokens.mutedLight,
        labelStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: NyumbaTokens.space2),
      ),
      dividerTheme: const DividerThemeData(color: NyumbaTokens.borderLight),
      navigationBarTheme: const NavigationBarThemeData(
        elevation: 0,
        height: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: NyumbaTokens.borderRadius),
      ),
    );
  }

  static ThemeData dark() {
    const brightness = Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: NyumbaTokens.primaryDark,
      onPrimary: const Color(0xFF052E16),
      primaryContainer: NyumbaTokens.primaryGlowDark,
      onPrimaryContainer: Colors.white,
      secondary: NyumbaTokens.gold,
      onSecondary: NyumbaTokens.goldForeground,
      secondaryContainer: NyumbaTokens.mutedDark,
      onSecondaryContainer: NyumbaTokens.foregroundDark,
      tertiary: NyumbaTokens.cocoa,
      onTertiary: Colors.white,
      error: const Color(0xFFF87171),
      onError: const Color(0xFF450A0A),
      surface: NyumbaTokens.cardDark,
      onSurface: NyumbaTokens.foregroundDark,
      surfaceContainerHighest: NyumbaTokens.mutedDark,
      onSurfaceVariant: NyumbaTokens.mutedForegroundDark,
      outline: NyumbaTokens.borderDark,
      outlineVariant: NyumbaTokens.borderDark,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: NyumbaTokens.backgroundDark,
    );

    return base.copyWith(
      textTheme: _textTheme(brightness, base.textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: NyumbaTokens.backgroundDark.withValues(alpha: 0.92),
        foregroundColor: NyumbaTokens.foregroundDark,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: NyumbaTokens.foregroundDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: NyumbaTokens.cardDark,
        shadowColor: const Color(0xFF111827).withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: NyumbaTokens.borderRadiusLg),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NyumbaTokens.mutedDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NyumbaTokens.space4,
          vertical: NyumbaTokens.space3,
        ),
        border: OutlineInputBorder(borderRadius: NyumbaTokens.borderRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: NyumbaTokens.borderRadius,
          borderSide: const BorderSide(color: NyumbaTokens.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NyumbaTokens.borderRadius,
          borderSide: const BorderSide(color: NyumbaTokens.primaryDark, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: NyumbaTokens.primaryDark,
          foregroundColor: const Color(0xFF052E16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: NyumbaTokens.borderRadius),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: NyumbaTokens.primaryDark,
          side: const BorderSide(color: NyumbaTokens.primaryDark),
          shape: RoundedRectangleBorder(borderRadius: NyumbaTokens.borderRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide.none,
        backgroundColor: NyumbaTokens.mutedDark,
        labelStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: NyumbaTokens.space2),
      ),
      dividerTheme: const DividerThemeData(color: NyumbaTokens.borderDark),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: NyumbaTokens.borderRadius),
      ),
    );
  }
}
