import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.background,
          secondary: AppColors.cta,
          onSecondary: AppColors.background,
          error: AppColors.error,
          onError: AppColors.background,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.display,
          displayMedium: AppTextStyles.heading1,
          displaySmall: AppTextStyles.heading2,
          headlineSmall: AppTextStyles.heading3,
          bodyLarge: AppTextStyles.body,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
          labelLarge: AppTextStyles.bodyMedium,
          labelSmall: AppTextStyles.micro,
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppRadius.lg),
            ),
          ),
          elevation: 0,
        ),
      );
}
