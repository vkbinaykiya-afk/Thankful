import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../app/app_routes.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/thankful_app_title.dart';

/// Microphone permission — matches `docs/reference/design_htmls/onb2_screen.html`.
class Onb2Screen extends StatefulWidget {
  const Onb2Screen({super.key});

  static const int totalSteps = 7;
  static const int currentStep = 3;

  @override
  State<Onb2Screen> createState() => _Onb2ScreenState();
}

class _Onb2ScreenState extends State<Onb2Screen> {
  static const String _micRequiredMessage =
      'Microphone access is required to record journal entries. '
      'Please enable it in Settings.';

  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.screen('onboarding_mic_permission'));
  }

  void _goOnb3(BuildContext context) {
    unawaited(AnalyticsService.onboardingStepCompleted(3, 'mic_permission'));
    if (context.mounted) {
      context.go(AppRoutes.onboardingLhamoIntro);
    }
  }

  Future<void> _showMicRequiredDialog(BuildContext context) async {
    if (!context.mounted) return;
    unawaited(AnalyticsService.micPermissionDenied());
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: const Text(_micRequiredMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onAllowMicrophone(BuildContext context) async {
    unawaited(AnalyticsService.onboardingStepCompleted(3, 'mic_permission'));
    var status = await Permission.microphone.status;
    if (!context.mounted) return;

    if (status.isGranted) {
      _goOnb3(context);
      return;
    }

    if (status.isRestricted || status.isPermanentlyDenied) {
      await _showMicRequiredDialog(context);
      return;
    }

    // Not determined (often reported as `denied` before first prompt) or
    // previously denied without a permanent flag — system sheet when eligible.
    final recorder = AudioRecorder();
    try {
      final granted = await recorder.hasPermission(request: true);
      if (!context.mounted) return;
      if (granted) {
        _goOnb3(context);
        return;
      }
    } finally {
      await recorder.dispose();
    }

    if (!context.mounted) return;
    status = await Permission.microphone.status;
    if (!context.mounted) return;

    if (status.isGranted) {
      _goOnb3(context);
      return;
    }

    if (!context.mounted) return;
    await _showMicRequiredDialog(context);
  }

  /// HTML `.dot` inactive fill (non-active pills).
  static const Color _dotIdle = Color(0xFFD8D2CA);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final noteStyle = AppTextStyles.body.copyWith(
      color: AppColors.textSecondary,
      height: 1.5,
    );

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
                    OnboardingProgressBar(
                      totalSteps: Onb2Screen.totalSteps,
                      currentStep: Onb2Screen.currentStep,
                      gap: 4,
                      inactiveColor: _dotIdle,
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 26,
                              height: 32,
                              child: CustomPaint(
                                painter: _Onb2MicGlyphPainter(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('One thing before', style: AppTextStyles.heading1),
                    Text(
                      'we begin',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Thankful is a voice journal. To hear you, we need '
                      'access to your microphone.',
                      style: noteStyle,
                    ),
                    const SizedBox(height: 14),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: _firstLineIconTopInset(
                                  fontSize: noteStyle.fontSize ?? 15,
                                  lineHeight: noteStyle.height ?? 1.5,
                                  iconSide: 14,
                                ),
                              ),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CustomPaint(
                                  painter: _Onb2InfoGlyphPainter(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'We only record during sessions — never in the '
                                'background.',
                                style: noteStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                    onTap: () => _onAllowMicrophone(context),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cta,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Allow microphone',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _goOnb3(context),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Not right now',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
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

/// Vertically centres a square icon with the first line of body text.
double _firstLineIconTopInset({
  required double fontSize,
  required double lineHeight,
  required double iconSide,
}) {
  final lineBox = fontSize * lineHeight;
  return ((lineBox - iconSide) / 2).clamp(0.0, double.infinity);
}

/// SVG microphone from `onb2_screen.html` (viewBox 0 0 26 32).
class _Onb2MicGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 26;
    final sy = size.height / 32;
    canvas.scale(sx, sy);
    final fill = Paint()..color = AppColors.primary;
    final stroke = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 1, 10, 16),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, fill);
    final arc = Path()
      ..moveTo(3, 15)
      ..cubicTo(3, 20.5, 7.5, 25, 13, 25)
      ..cubicTo(18.5, 25, 23, 20.5, 23, 15);
    canvas.drawPath(arc, stroke);
    canvas.drawLine(const Offset(13, 25), const Offset(13, 31), stroke);
    canvas.drawLine(const Offset(8, 31), const Offset(18, 31), stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// SVG info icon from `onb2_screen.html` (viewBox 0 0 14 14).
class _Onb2InfoGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 14;
    canvas.scale(s);
    final stroke = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(7, 7), 6, stroke);
    canvas.drawLine(const Offset(7, 6), const Offset(7, 10), stroke);
    canvas.drawCircle(
      const Offset(7, 4.5),
      0.6,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
