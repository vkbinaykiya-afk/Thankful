import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Minimal centred dot strip — same geometry as [LaunchScreen] carousel dots
/// (active = 14×4 pill, inactive = 4×4). [currentStep] is 1-based.
class OnboardingProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const OnboardingProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  })  : assert(totalSteps > 0),
        assert(currentStep >= 1 && currentStep <= totalSteps);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalSteps, (i) {
          final active = i == currentStep - 1;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs / 2,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              width: active ? 14 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
