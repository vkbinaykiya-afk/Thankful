import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/onboarding/onboarding_progress_visibility.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/onboarding_progress_bar.dart';
import '../../../shared/widgets/primary_button.dart';

/// Paywall — matches `docs/reference/design_htmls/screen7_paywall.html`.
///
/// **[showOnboardingProgress] true** — onboarding step **6** / **6** (dots under title).
///
/// **false** — same UI without progress (in-app nudges). Use `context.go(paywall)` with no `extra`.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    this.showOnboardingProgress = false,
  });

  /// Dot strip under app title (onboarding completion only).
  final bool showOnboardingProgress;

  static const int totalSteps = 6;
  static const int currentStep = 6;
  static const Color _dotIdle = Color(0xFFD8D2CA);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  static const _carouselWords = ['Gratitude', 'Meditation', 'Journalling'];

  bool _showOnboardingProgress = false;

  late final PageController _carouselController;
  Timer? _carouselTimer;
  int _carouselIndex = 0;

  /// `0` monthly, `1` annual (default).
  int _selectedPlan = 1;

  bool _isLoadingOffering = true;
  bool _isPurchasing = false;
  Package? _monthlyPackage;
  Package? _annualPackage;
  String _monthlyPrice = '\$4.99';
  String _annualPrice = '\$29.99';
  String _annualMonthlyPrice = '\$2.50';
  String _annualYearlyPrice = '\$29.99';

  @override
  void initState() {
    super.initState();
    unawaited(_resolveOnboardingProgress());
    unawaited(_loadOffering());
    _carouselController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || !_carouselController.hasClients) return;
        final next =
            ((_carouselController.page?.round() ?? _carouselIndex) + 1) %
                _carouselWords.length;
        _carouselController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      });
    });
  }

  Future<void> _resolveOnboardingProgress() async {
    final fromDb = await OnboardingProgressVisibility.shouldShowProgressStrip();
    if (!mounted) return;
    setState(() {
      _showOnboardingProgress =
          widget.showOnboardingProgress && fromDb;
    });
  }

  Future<void> _loadOffering() async {
    setState(() => _isLoadingOffering = true);
    try {
      final offering = await const SubscriptionService().getOffering();
      if (!mounted) return;
      if (offering == null) {
        setState(() => _isLoadingOffering = false);
        print('[Paywall] No offering returned — using fallback prices');
        return;
      }

      Package? monthly;
      Package? annual;

      for (final package in offering.availablePackages) {
        if (package.packageType == PackageType.monthly) monthly = package;
        if (package.packageType == PackageType.annual) annual = package;
      }

      String annualMonthly = '\$2.50';
      String annualYearly = '\$29.99';

      if (annual != null) {
        annualYearly = annual.storeProduct.priceString;
        final annualRaw = annual.storeProduct.price;
        annualMonthly = '\$${(annualRaw / 12).toStringAsFixed(2)}';
      }

      if (mounted) {
        setState(() {
          _monthlyPackage = monthly;
          _annualPackage = annual;
          _monthlyPrice = monthly?.storeProduct.priceString ?? '\$4.99';
          _annualPrice = annualYearly;
          _annualMonthlyPrice = annualMonthly;
          _annualYearlyPrice = annualYearly;
          _isLoadingOffering = false;
        });
      }
      print(
        '[Paywall] Loaded — monthly: $_monthlyPrice annual: $_annualYearlyPrice',
      );
    } catch (e) {
      print('[Paywall] _loadOffering error: $e');
      if (mounted) setState(() => _isLoadingOffering = false);
    }
  }

  Future<void> _onPurchaseTapped() async {
    final package = _selectedPlan == 0 ? _monthlyPackage : _annualPackage;
    if (package == null) {
      print('[Paywall] No package available for plan $_selectedPlan');
      return;
    }
    if (mounted) setState(() => _isPurchasing = true);
    try {
      final success = await const SubscriptionService().purchasePackage(package);
      if (!mounted) return;
      if (success) {
        print('[Paywall] Purchase successful — navigating home');
        context.go(AppRoutes.home);
      } else {
        print('[Paywall] Purchase failed or cancelled');
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _onRestoreTapped() async {
    if (mounted) setState(() => _isPurchasing = true);
    try {
      final success = await const SubscriptionService().restorePurchases();
      if (!mounted) return;
      if (success) {
        print('[Paywall] Restore successful — navigating home');
        context.go(AppRoutes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active subscription found to restore.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  static const _sepColor = Color(0xFFEAE4D8);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    print(
      '[Paywall] Built — selectedPlan: $_selectedPlan | purchasing: $_isPurchasing',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                5,
                AppSpacing.screenH,
                3,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: AppColors.primary,
                          letterSpacing: 0.01 * 18,
                        ),
                      ),
                      if (_showOnboardingProgress) ...[
                        const SizedBox(height: AppSpacing.xs),
                        OnboardingProgressBar(
                          totalSteps: PaywallScreen.totalSteps,
                          currentStep: PaywallScreen.currentStep,
                          gap: 4,
                          inactiveColor: PaywallScreen._dotIdle,
                        ),
                      ] else
                        const SizedBox(height: 12),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () => context.go(AppRoutes.home),
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  14,
                  AppSpacing.screenH,
                  12,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your first 3 days',
                      style: AppTextStyles.heading1.copyWith(height: 1.25),
                    ),
                    Text(
                      'are on us',
                      style: AppTextStyles.heading1.copyWith(
                        height: 1.25,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Try everything free for 3 days. No charge until '
                      'your trial ends.',
                      style: AppTextStyles.caption.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: _sepColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 7, bottom: 5),
                      child: SizedBox(
                        height: 44,
                        child: PageView.builder(
                          controller: _carouselController,
                          onPageChanged: (i) =>
                              setState(() => _carouselIndex = i),
                          itemCount: _carouselWords.length,
                          itemBuilder: (context, i) => Center(
                            child: Text(
                              _carouselWords[i],
                              style: AppTextStyles.captionMedium.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                                letterSpacing: 1.2,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_carouselWords.length, (i) {
                        final on = i == _carouselIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            width: on ? 14 : 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: on
                                  ? AppColors.primary
                                  : PaywallScreen._dotIdle,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 2),
                    ),
                    const SizedBox(height: 18),
                    if (_isLoadingOffering)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else ...[
                      _PlanCard(
                        selected: _selectedPlan == 0,
                        onTap: () => setState(() => _selectedPlan = 0),
                        radioSelected: _selectedPlan == 0,
                        title: 'Monthly',
                        meta: 'Billed every month',
                        amount: _monthlyPrice,
                        period: '/mo',
                        badge: null,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _PlanCard(
                        selected: _selectedPlan == 1,
                        onTap: () => setState(() => _selectedPlan = 1),
                        radioSelected: _selectedPlan == 1,
                        title: 'Annual',
                        meta: '$_annualPrice/yr · best value',
                        amount: _annualMonthlyPrice,
                        period: '/mo',
                        badge: 'Best value',
                      ),
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
                    label: 'Start 3-day free trial',
                    isLoading: _isPurchasing,
                    onPressed: (_isPurchasing || _isLoadingOffering)
                        ? null
                        : () => unawaited(_onPurchaseTapped()),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cancel anytime · ',
                        style: AppTextStyles.micro.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                          height: 1.4,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isPurchasing
                            ? null
                            : () => unawaited(_onRestoreTapped()),
                        child: Text(
                          'Restore purchase',
                          style: AppTextStyles.micro.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textTertiary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 56,
                      height: 3,
                      decoration: BoxDecoration(
                        color:
                            AppColors.textPrimary.withValues(alpha: 0.14),
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.onTap,
    required this.radioSelected,
    required this.title,
    required this.meta,
    required this.amount,
    required this.period,
    this.badge,
  });

  final bool selected;
  final VoidCallback onTap;
  final bool radioSelected;
  final String title;
  final String meta;
  final String amount;
  final String period;
  final String? badge;

  /// HTML `.plan-name` / `.plan-amount`: 13px / 500 / lh 1.3 — maps to captionMedium + explicit height.
  static final TextStyle _planPrimary = AppTextStyles.captionMedium.copyWith(
    height: 1.3,
    color: AppColors.textSecondary,
  );

  /// HTML `.plan-meta` / `.plan-period`: 11px / 400 / lh 1.4
  static final TextStyle _planSecondary = AppTextStyles.micro.copyWith(
    height: 1.4,
    color: AppColors.textTertiary,
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: AppConstants.cardPress,
          curve: Curves.easeIn,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.surfaceRaised : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: radioSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: radioSelected
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: radioSelected
                    ? Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: _planPrimary,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              badge!,
                              style: AppTextStyles.micro.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(meta, style: _planSecondary),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: _planPrimary.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(period, style: _planSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
