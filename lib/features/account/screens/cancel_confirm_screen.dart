import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

/// `docs/reference/design_htmls/screen11_cancel_confirm final.html` — static flows only.
class CancelConfirmScreen extends StatelessWidget {
  const CancelConfirmScreen({super.key});

  /// Farewell monk — layout width × zoom (locked 1.5× vs base 192px).
  static const double _monkZoom = 1.5;
  static const double _monkWidthPx = 192 * _monkZoom;
  static const String _monkAsset = 'assets/mascot/Monk_bye2.png';

  @override
  Widget build(BuildContext context) {
    final headlineStyle = AppTextStyles.heading1;
    final bodyMuted = AppTextStyles.body.copyWith(color: AppColors.textSecondary);
    final bodyAccent =
        AppTextStyles.bodyMedium.copyWith(color: AppColors.primary);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 36, left: 22, right: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Thank you for',
                          style: headlineStyle,
                          textAlign: TextAlign.start,
                          textDirection: TextDirection.ltr,
                        ),
                        Text(
                          'being here.',
                          style: headlineStyle,
                          textAlign: TextAlign.start,
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 22, right: 22, top: 6),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(style: bodyMuted, text: 'You showed up. '),
                          TextSpan(style: bodyAccent, text: 'Twelve times.'),
                          TextSpan(
                            style: bodyMuted,
                            text:
                                " That's the hard part — and you did it. Your journal stays here, "
                                'always.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.start,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSpacing.md),
                  Center(
                    child: RepaintBoundary(
                      child: _MonkByeImage(width: _monkWidthPx),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      'We hope you\u2019ve found a little more peace. Whatever brought '
                      'you here \u2014 we hope it helped.',
                      style: bodyMuted,
                      textAlign: TextAlign.start,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                0,
                22,
                AppSpacing.screenBot,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: 'Keep my subscription',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.account);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Cancel anyway',
                    onPressed: () => context.go(AppRoutes.home),
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

/// Farewell monk — `mix-blend-mode: multiply` vs [AppColors.background].
class _MonkByeImage extends StatelessWidget {
  const _MonkByeImage({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final cacheWidth = Theme.of(context).platform == TargetPlatform.iOS
        ? null
        : math.max(
            1,
            (width * MediaQuery.devicePixelRatioOf(context)).round().clamp(200, 900),
          );

    Widget img = Image.asset(
      CancelConfirmScreen._monkAsset,
      width: width,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => SizedBox(
        width: width,
        height: width,
        child: ColoredBox(color: AppColors.surfaceRaised),
      ),
    );

    img = ClipRect(
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          AppColors.background,
          BlendMode.multiply,
        ),
        child: img,
      ),
    );

    return img;
  }
}
