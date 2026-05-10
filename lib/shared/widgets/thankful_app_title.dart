import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Top app chrome — same layout and style on launch, signup, onboarding.
class ThankfulAppTitle extends StatelessWidget {
  const ThankfulAppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.screenTop),
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: AppTextStyles.display.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
