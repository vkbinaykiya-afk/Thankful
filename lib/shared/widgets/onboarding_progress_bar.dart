import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Minimal centred dot strip — same geometry as [LaunchScreen] carousel dots
/// (active = 14×4 pill, inactive = 4×4). [currentStep] is 1-based.
class OnboardingProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  /// Horizontal gap between dot centres — HTML reference uses `gap: 4px`.
  final double gap;

  /// Inactive dot colour (HTML `onb2`: `#D8D2CA`).
  final Color inactiveColor;

  const OnboardingProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.gap = 6,
    this.inactiveColor = AppColors.textTertiary,
  })  : assert(totalSteps > 0),
        assert(currentStep >= 1 && currentStep <= totalSteps);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < totalSteps; i++) ...[
            if (i > 0) SizedBox(width: gap),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              width: i == currentStep - 1 ? 14 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: i == currentStep - 1
                    ? AppColors.primary
                    : inactiveColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
