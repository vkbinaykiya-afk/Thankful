import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/oauth_continue_button.dart';
import '../../../shared/widgets/thankful_app_title.dart';
import '../controllers/auth_controller.dart';
import '../google_auth_helpers.dart';

/// Matches [LaunchScreen] chrome (app name, centered monk, 80% hairline, ticker)
/// with auth CTAs and footer per signup HTML.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<double> _drift;
  late final PageController _pageController;
  Timer? _carouselTimer;

  static const _words = ['Gratitude', 'Meditation', 'Journalling'];

  int _pageIndex = 0;

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

    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final next =
            ((_pageController.page?.round() ?? _pageIndex) + 1) %
                _words.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      });
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenW = MediaQuery.sizeOf(context).width;
    final monkW = screenW * AppConstants.launchMonkWidthFraction;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ThankfulAppTitle(),
            Expanded(
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
                      state: MonkState.meditation,
                      width: monkW,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: screenW * 0.8,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.surface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: SizedBox(
                height: 44,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _pageIndex = i),
                  itemCount: _words.length,
                  itemBuilder: (context, i) => Center(
                    child: Text(
                      _words[i],
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_words.length, (i) {
                final on = i == _pageIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs / 2,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    width: on ? 14 : 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: on ? AppColors.primary : AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.screenH,
                bottomInset + AppSpacing.screenBot,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your thoughts,', style: AppTextStyles.heading1),
                  Text(
                    'finally heard.',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'A voice journal that listens back.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OAuthContinueButton(
                    kind: OAuthContinueKind.apple,
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      return OAuthContinueButton(
                        kind: OAuthContinueKind.google,
                        onPressed: auth.isLoading
                            ? null
                            : () => completeGoogleSignIn(context),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          GoRouter.of(context).push(AppRoutes.login),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          spacing: 0,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Sign in',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
