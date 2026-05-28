import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class AppSnackBar {
  /// Shows a DS-aligned snackbar. Use for errors, warnings, and info messages.
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    print('[AppSnackBar] Showing: $message | isError: $isError');
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.background,
          ),
        ),
        backgroundColor: isError ? AppColors.textPrimary : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          AppSpacing.lg,
        ),
        duration: const Duration(seconds: 3),
        elevation: 0,
      ),
    );
  }
}
