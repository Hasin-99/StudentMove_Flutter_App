import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand and layout tokens for StudentMove.
abstract final class AppColors {
  static const Color brand = Color(0xFF3B82F6);
  static const Color brandLight = Color(0xFF60A5FA);
  static const Color brandDark = Color(0xFF2563EB);
  static const Color accent = Color(0xFF1D4ED8);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF06B6D4);
  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color surface = Color(0xFFF1F5F9);
  static const Color card = Color(0xFFFFFFFF);
}

abstract final class AppLayout {
  static const double pageHPad = 16;
  static const double pageTopPad = 14;
  static const double pageBottomPad = 24;
  static const double cardRadius = 18;
  static const double sectionGap = 16;

  // Responsive-only sizing (width breakpoints).
  // No platform-adaptive behavior here.
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
  static ThemeData light() {
    final scheme = ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brandLight.withValues(alpha: 0.2),
      onPrimaryContainer: AppColors.brandDark,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      error: const Color(0xFFDC2626),
      outline: AppColors.border,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
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
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.brandLight.withValues(alpha: 0.22),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
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
            GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
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
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
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
    );
  }

  static LinearGradient brandGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandDark, AppColors.brand, AppColors.brandLight],
  );

  static LinearGradient accentGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent, Color(0xFF8B5CF6)],
  );
}
