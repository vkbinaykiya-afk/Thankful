import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/thankful_app_title.dart';

class OnboardingLhamoIntroScreen extends StatefulWidget {
  const OnboardingLhamoIntroScreen({super.key});

  static const int totalSteps = 7;
  static const int currentStep = 4;
  static const Color _dotIdle = Color(0xFFD8D2CA);

  @override
  State<OnboardingLhamoIntroScreen> createState() =>
      _OnboardingLhamoIntroScreenState();
}

class _OnboardingLhamoIntroScreenState extends State<OnboardingLhamoIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<double> _drift;

  @override
  void initState() {
    super.initState();
    print('[OnboardingLhamoIntro] Screen shown — step 4/7');
    _entranceController = AnimationController(
      vsync: this,
      duration: AppConstants.mascotEntryDuration,
    );
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _fade = curved;
    _drift = Tween<double>(
      begin: AppConstants.mascotEntryDriftPx,
      end: 0,
    ).animate(curved);
    _entranceController.forward();
    unawaited(AnalyticsService.screen('onboarding_lhamo_intro'));
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
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
                    const ThankfulAppTitle(),
                    const SizedBox(height: AppSpacing.xs),
                    const OnboardingProgressBar(
                      totalSteps: OnboardingLhamoIntroScreen.totalSteps,
                      currentStep: OnboardingLhamoIntroScreen.currentStep,
                      gap: 4,
                      inactiveColor: OnboardingLhamoIntroScreen._dotIdle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Hi, I am Lhamo.', style: AppTextStyles.display),
                    Text(
                      'Your journaling guide.',
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'I listen without judgment, ask without rushing, and sit '
                      'with you in whatever you bring today.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) => Opacity(
                              opacity: _fade.value,
                              child: Transform.translate(
                                offset: Offset(0, _drift.value),
                                child: child,
                              ),
                            ),
                            child: MonkMascot(
                              state: MonkState.namaste,
                              width: MediaQuery.sizeOf(context).width * 1.1,
                              multiplyWithBackground: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.screenH,
                bottomInset + AppSpacing.screenBot,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: 'Continue',
                    onPressed: () {
                      unawaited(
                        AnalyticsService.onboardingStepCompleted(
                          4,
                          'lhamo_intro',
                        ),
                      );
                      context.go(AppRoutes.onboardingOnb3);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: Container(
                      width: 56,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
