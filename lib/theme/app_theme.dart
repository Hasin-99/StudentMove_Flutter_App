import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StudentMove brand tokens aligned with the web/PWA design system
/// (Syne + IBM Plex Sans, route teal, signal amber).
abstract final class AppColors {
  static const Color brand = Color(0xFF0B6E6A);
  static const Color brandLight = Color(0xFF14A39C);
  static const Color brandDark = Color(0xFF0B4F4C);
  static const Color accent = Color(0xFFE0952C);
  static const Color accentHot = Color(0xFFEBB04A);
  static const Color success = Color(0xFF0B6E6A);
  static const Color warning = Color(0xFFE0952C);
  static const Color info = Color(0xFF14A39C);
  static const Color danger = Color(0xFFC45C4A);
  static const Color ink = Color(0xFF12161C);
  static const Color graphite = Color(0xFF1E2630);
  static const Color slate = Color(0xFF3D4654);
  static const Color muted = Color(0xFF5B6572);
  static const Color mist = Color(0xFFC8D3DB);
  static const Color fog = Color(0xFFB4C0CA);
  static const Color paper = Color(0xFFEDF2F1);
  static const Color border = Color(0xFFD5E0DC);
  static const Color surface = Color(0xFFF3F8F7);
  static const Color card = Color(0xFFFFFFFF);
}

abstract final class AppLayout {
  static const double pageHPad = 16;
  static const double pageTopPad = 14;
  static const double pageBottomPad = 24;
  static const double cardRadius = 18;
  static const double sectionGap = 16;

  static AppFormFactor formFactorFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return AppFormFactor.desktop;
    if (width >= 700) return AppFormFactor.tablet;
    return AppFormFactor.mobile;
  }

  static double pageHPadFor(BuildContext context) {
    return switch (formFactorFor(context)) {
      AppFormFactor.mobile => 16,
      AppFormFactor.tablet => 24,
      AppFormFactor.desktop => 32,
    };
  }

  static double pageTopPadFor(BuildContext context) {
    return switch (formFactorFor(context)) {
      AppFormFactor.mobile => 14,
      AppFormFactor.tablet => 18,
      AppFormFactor.desktop => 22,
    };
  }

  static double pageBottomPadFor(BuildContext context) {
    return switch (formFactorFor(context)) {
      AppFormFactor.mobile => 24,
      AppFormFactor.tablet => 28,
      AppFormFactor.desktop => 32,
    };
  }

  static double sectionGapFor(BuildContext context) {
    return switch (formFactorFor(context)) {
      AppFormFactor.mobile => 16,
      AppFormFactor.tablet => 18,
      AppFormFactor.desktop => 20,
    };
  }

  static double contentMaxWidthFor(BuildContext context) {
    return switch (formFactorFor(context)) {
      AppFormFactor.mobile => double.infinity,
      AppFormFactor.tablet => 860,
      AppFormFactor.desktop => 1040,
    };
  }
}

enum AppFormFactor { mobile, tablet, desktop }

abstract final class AppTheme {
  static TextStyle display(BuildContext context, {double size = 28, FontWeight weight = FontWeight.w700, Color? color}) {
    return GoogleFonts.syne(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.ink,
      letterSpacing: -0.3,
      height: 1.15,
    );
  }

  static TextStyle body(BuildContext context, {double size = 15, FontWeight weight = FontWeight.w500, Color? color}) {
    return GoogleFonts.ibmPlexSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.ink,
      height: 1.35,
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brandLight.withValues(alpha: 0.18),
      onPrimaryContainer: AppColors.brandDark,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      error: AppColors.danger,
      outline: AppColors.border,
    );

    final textTheme = GoogleFonts.ibmPlexSansTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.brandLight.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.ibmPlexSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.brand : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.brand : AppColors.muted,
            size: 24,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: AppColors.muted, fontSize: 15),
        labelStyle: TextStyle(color: AppColors.muted, fontSize: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.border;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.brandDark;
            }
            return AppColors.brand;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.muted;
            }
            return Colors.white;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.08);
            }
            return null;
          }),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.border;
            return AppColors.accent;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppColors.border);
            }
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(color: AppColors.brand, width: 1.4);
            }
            return const BorderSide(color: AppColors.border);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.muted;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.brandDark;
            }
            return AppColors.ink;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.brandLight.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.muted;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.brandDark;
            }
            return AppColors.brand;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.brandLight.withValues(alpha: 0.14);
            }
            return null;
          }),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppColors.ink,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.brandLight.withValues(alpha: 0.12),
        selectedColor: AppColors.brand,
        labelStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandDark, AppColors.brand, AppColors.brandLight],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent, AppColors.accentHot],
  );

  /// Soft atmospheric backdrop matching the web PWA page atmosphere.
  static const LinearGradient pageAtmosphere = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8F4F3),
      Color(0xFFEDF2F1),
      Color(0xFFF5F0E8),
    ],
  );

  static List<BoxShadow> elev1 = [
    BoxShadow(
      color: AppColors.brand.withValues(alpha: 0.07),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.06),
      blurRadius: 40,
      offset: const Offset(0, 18),
    ),
  ];
}
