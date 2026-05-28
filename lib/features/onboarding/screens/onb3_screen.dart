import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/subscription_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/thankful_app_title.dart';

/// Start first entry — matches `docs/reference/design_htmls/onb3_start entry_screen.html`.
class Onb3Screen extends StatefulWidget {
  const Onb3Screen({super.key});

  static const int totalSteps = 7;
  static const int currentStep = 5;

  static const Color _dotIdle = Color(0xFFD8D2CA);

  @override
  State<Onb3Screen> createState() => _Onb3ScreenState();
}

class _Onb3ScreenState extends State<Onb3Screen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<double> _drift;

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

  Future<void> _checkMicAndNavigate(BuildContext context) async {
    final status = await Permission.microphone.status;
    print('[MicCheck] status: $status');
    if (status.isGranted) {
      print('[EdgeState] onb3 mic granted - navigating');
      await SubscriptionService.navigateToSessionOrPaywall(
        context,
        paywallOnboardingProgress: true,
      );
      return;
    }
    if (status.isPermanentlyDenied) {
      print('[EdgeState] onb3 mic permanently denied');
      _showMicDeniedDialog(context);
      return;
    }
    final result = await Permission.microphone.request();
    print('[MicCheck] request result: $result');
    if (result.isGranted) {
      print('[EdgeState] onb3 mic granted after request - navigating');
      await SubscriptionService.navigateToSessionOrPaywall(
        context,
        paywallOnboardingProgress: true,
      );
    } else {
      print('[EdgeState] onb3 mic denied after request');
      _showMicDeniedDialog(context);
    }
  }

  void _showMicDeniedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(
          'Microphone access needed',
          style: AppTextStyles.heading3,
        ),
        content: Text(
          'Thankful needs microphone access to hear you. Please enable it in Settings.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not now',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
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
                    OnboardingProgressBar(
                      totalSteps: Onb3Screen.totalSteps,
                      currentStep: Onb3Screen.currentStep,
                      gap: 4,
                      inactiveColor: Onb3Screen._dotIdle,
                    ),
                    const SizedBox(height: 12),
                    Text('Make your', style: AppTextStyles.heading1),
                    Text(
                      'first entry',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'I\'ll ask a few gentle questions. Just speak — your '
                      'words become your journal.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ClipRect(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
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
                                  layoutHeight: constraints.maxHeight,
                                  multiplyWithBackground: true,
                                ),
                              ),
                            );
                          },
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
                0,
                AppSpacing.screenH,
                bottomInset + AppSpacing.screenBot,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () => unawaited(_checkMicAndNavigate(context)),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cta,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Begin my first entry',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 56,
                      height: 3,
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
