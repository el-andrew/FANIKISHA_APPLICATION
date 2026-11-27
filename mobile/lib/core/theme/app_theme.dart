import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Fanikisha's Material 3 theme: light, calm, money first.
///
/// Type scale (DM Sans), used through the theme's roles, never ad-hoc sizes:
///
/// | Role             | Size | Weight | Used for                         |
/// | ---------------- | ---- | ------ | -------------------------------- |
/// | `headlineMedium` | 32   | 700    | The balance                      |
/// | `headlineSmall`  | 24   | 700    | Big amounts inside cards         |
/// | `titleLarge`     | 20   | 600    | Screen titles                    |
/// | `titleMedium`    | 16   | 600    | Section and card titles          |
/// | `titleSmall`     | 14   | 600    | Row titles, emphasised body text |
/// | `bodyMedium`     | 14   | 400    | Body text                        |
/// | `bodySmall`      | 12   | 400    | Captions: dates, "of TZS …"      |
/// | `labelLarge`     | 15   | 600    | Buttons                          |
/// | `labelMedium`    | 12   | 600    | Badges, chips, tab labels        |
abstract final class AppTheme {
  static const brandGreen = AppColors.brandGreen;
  static const deepGreen = AppColors.deepGreen;

  static const fontFamily = 'DM Sans';

  static const _control = BorderRadius.all(Radius.circular(AppRadius.control));

  static const _textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontSize: 32,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.25,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(fontSize: 14, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, height: 1.35),
    labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandGreen,
      primary: AppColors.deepGreen,
      onPrimary: Colors.white,
      primaryContainer: AppColors.tint,
      onPrimaryContainer: AppColors.deepGreen,
      secondaryContainer: AppColors.tint,
      onSecondaryContainer: AppColors.deepGreen,
      surface: AppColors.ground,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: AppColors.card,
      surfaceContainerLow: AppColors.card,
      surfaceContainer: AppColors.card,
      outline: AppColors.border,
      outlineVariant: AppColors.line,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ground,
      fontFamily: fontFamily,
      textTheme: _textTheme,
    );
    const buttonText = TextStyle(
      fontFamily: fontFamily,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: _control),
        enabledBorder: OutlineInputBorder(
          borderRadius: _control,
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSize.button),
          shape: const RoundedRectangleBorder(borderRadius: _control),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSize.button),
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border),
          shape: const RoundedRectangleBorder(borderRadius: _control),
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSize.touch, AppSize.touch),
          textStyle: buttonText.copyWith(fontSize: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.tint,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => base.textTheme.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.deepGreen
                : AppColors.muted,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
