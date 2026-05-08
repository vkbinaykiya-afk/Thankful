import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.saffronAccent,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          displayMedium: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          displaySmall: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          bodySmall: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(AppConstants.radiusCard),
            ),
          ),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cta,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}
