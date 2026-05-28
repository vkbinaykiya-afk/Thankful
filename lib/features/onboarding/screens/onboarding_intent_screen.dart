import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/thankful_app_title.dart';

class OnboardingIntentScreen extends StatefulWidget {
  const OnboardingIntentScreen({super.key});

  static const int totalSteps = 8;
  static const int currentStep = 5;
  static const Color _dotIdle = Color(0xFFD8D2CA);
  static const List<String> options = [
    'Finding calm',
    'Feeling grateful',
    'Working through feelings',
    'Building a daily habit',
    'Just exploring',
  ];

  @override
  State<OnboardingIntentScreen> createState() => _OnboardingIntentScreenState();
}

class _OnboardingIntentScreenState extends State<OnboardingIntentScreen> {
  final Set<int> _selectedIndices = {0};

  @override
  void initState() {
    super.initState();
    print('[OnboardingIntent] Screen shown — not wired to flow yet');
  }

  Future<void> _onContinue() async {
    final selected = _selectedIndices
        .map((i) => OnboardingIntentScreen.options[i])
        .toList();
    print('[OnboardingIntent] Selected: $selected');
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .update({'intent': selected})
            .eq('id', user.id);
        print('[OnboardingIntent] Saved intent: $selected');
      }
    } catch (e) {
      print('[OnboardingIntent] Failed to save intent: $e — continuing anyway');
    }
    if (mounted) context.go(AppRoutes.onboardingOnb3);
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
                      totalSteps: OnboardingIntentScreen.totalSteps,
                      currentStep: OnboardingIntentScreen.currentStep,
                      gap: 4,
                      inactiveColor: OnboardingIntentScreen._dotIdle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('What brings', style: AppTextStyles.heading1),
                    Text(
                      'you here?',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Select all that apply. I will carry this into our first conversation.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (
                      int i = 0;
                      i < OnboardingIntentScreen.options.length;
                      i++
                    ) ...[
                      GestureDetector(
                        onTap: () => setState(() {
                          if (_selectedIndices.contains(i)) {
                            if (_selectedIndices.length > 1) {
                              _selectedIndices.remove(i);
                            }
                          } else {
                            _selectedIndices.add(i);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: AppConstants.cardPress,
                          curve: Curves.easeIn,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: _selectedIndices.contains(i)
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: AppConstants.cardPress,
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  color: _selectedIndices.contains(i)
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _selectedIndices.contains(i)
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: _selectedIndices.contains(i)
                                    ? const Icon(
                                        Icons.check,
                                        size: 13,
                                        color: AppColors.background,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                OnboardingIntentScreen.options[i],
                                style: AppTextStyles.body.copyWith(
                                  color: _selectedIndices.contains(i)
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: _selectedIndices.contains(i)
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i < OnboardingIntentScreen.options.length - 1)
                        const SizedBox(height: AppSpacing.xs),
                    ],
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
                    label: 'Continue',
                    onPressed: () => unawaited(_onContinue()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Skip for now',
                    onPressed: () => context.go(AppRoutes.onboardingOnb3),
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
