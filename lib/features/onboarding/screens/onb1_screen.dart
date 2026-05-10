import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/thankful_app_title.dart';

/// Onboarding step 2 of 6 — copy & typography from
/// `docs/reference/design_htmls/onb1_screen.html` (mascot–monk export).
/// Progress: compact dot strip (same pattern as [LaunchScreen] ticker dots).
class Onb1Screen extends StatefulWidget {
  const Onb1Screen({super.key});

  static const int totalSteps = 6;
  static const int currentStep = 2;

  @override
  State<Onb1Screen> createState() => _Onb1ScreenState();
}

class _Onb1ScreenState extends State<Onb1Screen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<double> _drift;

  static const List<({String n, String title, String subtitle})> _steps = [
    (
      n: '1',
      title: 'I ask, you speak',
      subtitle:
          'Your guide asks a few questions. Just talk — no typing needed.',
    ),
    (
      n: '2',
      title: 'We listen together',
      subtitle: 'Take your time. Pause, reflect, continue — no rush.',
    ),
    (
      n: '3',
      title: 'Your entry is ready',
      subtitle:
          'We turn your words into a journal you can read and keep.',
    ),
  ];

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenW = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                      totalSteps: Onb1Screen.totalSteps,
                      currentStep: Onb1Screen.currentStep,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Here\'s how', style: AppTextStyles.heading1),
                    Text(
                      'it works',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._steps.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s.n,
                                style: AppTextStyles.micro.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    s.subtitle,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 130,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _fade.value,
                                child: Transform.translate(
                                  offset: Offset(0, _drift.value),
                                  child: child,
                                ),
                              );
                            },
                            child: MonkMascot(
                              state: MonkState.writing,
                              width: screenW * 0.72,
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
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.demo),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cta,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Continue',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
