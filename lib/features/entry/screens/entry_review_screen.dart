import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/thankful_app_title.dart';

/// Entry review — matches `docs/reference/design_htmls/Post_entry_review_screen.html`.
///
/// **Onboarding:** pass [showOnboardingProgress] true (e.g. `context.go(..., extra: true)`)
/// for step **5** of **6** — Thankful title + dot strip; Save continues to paywall.
///
/// **Returning user:** `showOnboardingProgress` false — no progress UI; Save returns home.
class EntryReviewScreen extends StatelessWidget {
  const EntryReviewScreen({
    super.key,
    this.showOnboardingProgress = false,
  });

  /// Dot strip + app title (first-time onboarding only).
  final bool showOnboardingProgress;

  static const int totalSteps = 6;
  static const int currentStep = 5;

  static const Color _dotIdle = Color(0xFFD8D2CA);

  String _metaLine(DateTime d) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year} · 4 min 12 sec';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  0,
                  AppSpacing.screenH,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showOnboardingProgress) ...[
                      const ThankfulAppTitle(),
                      const SizedBox(height: AppSpacing.xs),
                      OnboardingProgressBar(
                        totalSteps: totalSteps,
                        currentStep: currentStep,
                        gap: 4,
                        inactiveColor: _dotIdle,
                      ),
                      const SizedBox(height: 12),
                    ] else
                      const SizedBox(height: 48),
                    Text('Your entry', style: AppTextStyles.heading1),
                    Text(
                      'is ready',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _metaLine(now),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      height: 204,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today I woke up feeling a quiet kind of '
                              'grateful. Not the big, loud kind — just a '
                              'small warmth when I made my tea and the '
                              'light came through the window just right.',
                              style: AppTextStyles.journal,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'I\'ve been thinking about the conversation '
                              'I had with my mother last week. She '
                              'mentioned that she was proud of me, and I '
                              'didn\'t quite know how to hold that. I still '
                              'don\'t, really. But I\'m trying to let it in '
                              'instead of deflecting.',
                              style: AppTextStyles.journal,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'The AI asked me what I was most looking '
                              'forward to today. I said nothing in '
                              'particular — and then I realised that '
                              'wasn\'t true. I\'m looking forward to the '
                              'quiet walk I\'ve been putting off.',
                              style: AppTextStyles.journal,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Small things. That\'s where it lives, I '
                              'think.',
                              style: AppTextStyles.journal,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                0,
                AppSpacing.screenH,
                bottomInset + AppSpacing.screenBot,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: 'Save entry',
                    onPressed: () {
                      if (showOnboardingProgress) {
                        context.go(AppRoutes.paywall, extra: true);
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Start over',
                    onPressed: () =>
                        context.go(AppRoutes.onboardingConvo),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
