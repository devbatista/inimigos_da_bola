import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_theme.dart';

abstract final class AppTheme {
  static ThemeData light() {
    return _build(
      brightness: Brightness.light,
      background: AppColors.chalk,
      foreground: AppColors.ink,
      surface: AppColors.chalk,
      surfaceVariant: AppColors.mist,
      secondary: AppColors.stone,
    );
  }

  static ThemeData dark() {
    return _build(
      brightness: Brightness.dark,
      background: AppColors.ink,
      foreground: AppColors.chalk,
      surface: AppColors.ink,
      surfaceVariant: AppColors.stone,
      secondary: AppColors.mist,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color foreground,
    required Color surface,
    required Color surfaceVariant,
    required Color secondary,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.leather,
      onPrimary: background,
      secondary: secondary,
      onSecondary: background,
      error: AppColors.danger,
      onError: background,
      surface: surface,
      onSurface: foreground,
      surfaceContainerHighest: surfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      textTheme: AppTextTheme.build(foreground),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: surfaceVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: surfaceVariant.subtle,
        thickness: 1,
        space: 1,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: AppColors.leather,
        collapsedIconColor: secondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant.subtle,
        labelStyle: TextStyle(color: foreground.muted),
        floatingLabelStyle: const TextStyle(color: AppColors.leather),
        hintStyle: TextStyle(color: foreground.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.leather, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.leather,
        selectionColor: AppColors.leather.subtle,
        selectionHandleColor: AppColors.leather,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.leather,
          foregroundColor: AppColors.chalk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: foreground),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
