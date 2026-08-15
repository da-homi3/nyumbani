import 'package:flutter/material.dart';

/// Design tokens mirrored from find-nyumba-smart/src/styles.css.
abstract final class NyumbaTokens {
  // Brand mark only (app icon / logo plate) — not UI primary.
  static const Color cocoa = Color(0xFF4A2713);

  static const Color forest = Color(0xFF086B2E);
  static const Color primaryLight = Color(0xFF0A8F3D); // jade
  static const Color primaryGlowLight = Color(0xFF16A34A); // mint
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color primaryGlowDark = Color(0xFF22C55E);
  static const Color sage = Color(0xFFDCFCE7);

  static const Color gold = Color(0xFFFFD54F);
  static const Color goldForeground = Color(0xFF111827);
  static const Color accent = Color(0xFFFEF9C3);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color foregroundLight = Color(0xFF111827);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color mutedLight = Color(0xFFF1F5F9);
  static const Color mutedForegroundLight = Color(0xFF64748B);

  static const Color backgroundDark = Color(0xFF111827);
  static const Color foregroundDark = Color(0xFFF8FAFC);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color mutedDark = Color(0xFF273549);
  static const Color mutedForegroundDark = Color(0xFF94A3B8);

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  static const Color destructive = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color sapphire = Color(0xFF3B82F6);

  /// Web `--radius: 0.75rem` (~12px) and scale.
  static const double radius = 12;
  static const double radiusSm = 8;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radius3xl = 28;

  /// Spacing scale (4px base — aligns with common Tailwind gaps).
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;

  /// Motion durations from styles.css.
  static const Duration durationMicro = Duration(milliseconds: 150);
  static const Duration durationFast = Duration(milliseconds: 250);
  static const Duration durationMedium = Duration(milliseconds: 450);
  static const Duration durationSlow = Duration(milliseconds: 700);

  static const Curve easeSpring = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve easeSmooth = Cubic(0.4, 0, 0.2, 1);
  static const Curve easeOutExpo = Cubic(0.19, 1, 0.22, 1);
  static const Curve easeOutSoft = Cubic(0.16, 1, 0.3, 1);

  static const String logoUrl =
      'https://nyumbasearch.com/brand/v4/logo-sm.webp';
  static const String iconUrl =
      'https://nyumbasearch.com/brand/v4/icon-sm.webp';
  static const String logoAsset = 'assets/brand/logo-sm.webp';
  static const String iconAsset = 'assets/brand/icon-sm.webp';

  static BorderRadius get borderRadius => BorderRadius.circular(radius);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadius2xl => BorderRadius.circular(radius2xl);

  /// Clearance for floating tenant bottom nav + safe area.
  static double shellBottomInset(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + 88;
  }

  static List<BoxShadow> shadowSoft(Brightness brightness) {
    final alpha = brightness == Brightness.dark ? 0.28 : 0.08;
    return [
      BoxShadow(
        color: const Color(0xFF111827).withValues(alpha: alpha),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> shadowCard(Brightness brightness) {
    final alpha = brightness == Brightness.dark ? 0.4 : 0.12;
    return [
      BoxShadow(
        color: const Color(0xFF111827).withValues(alpha: alpha),
        blurRadius: 28,
        offset: const Offset(0, 8),
        spreadRadius: -8,
      ),
    ];
  }

  static List<BoxShadow> shadowElegant() {
    return [
      BoxShadow(
        color: primaryLight.withValues(alpha: 0.28),
        blurRadius: 40,
        offset: const Offset(0, 12),
        spreadRadius: -12,
      ),
    ];
  }

  static List<BoxShadow> shadowGreen() {
    return [
      BoxShadow(
        color: primaryLight.withValues(alpha: 0.35),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static BoxDecoration glassNav(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      color: (isDark ? backgroundDark : backgroundLight).withValues(alpha: 0.75),
      borderRadius: borderRadius2xl,
      border: Border.all(
        color: (isDark ? borderDark : borderLight).withValues(alpha: 0.6),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF111827).withValues(alpha: isDark ? 0.35 : 0.12),
          blurRadius: 32,
          offset: const Offset(0, -8),
        ),
      ],
    );
  }

  /// Frosted header chrome (SiteTopBar) — mirrors mobile web SiteNav glass.
  static BoxDecoration glassTopBar({bool frosted = true}) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: frosted ? 0.28 : 0.52),
      borderRadius: BorderRadius.circular(radiusLg),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.22),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration cardSurface(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? cardDark : cardLight,
      borderRadius: borderRadiusLg,
      border: Border.all(
        color: (isDark ? borderDark : borderLight).withValues(alpha: 0.7),
      ),
      boxShadow: shadowCard(brightness),
    );
  }
}
