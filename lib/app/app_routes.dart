/// Named routes for [GoRouter]. Use these for navigation so paths stay in sync.
abstract final class AppRoutes {
  AppRoutes._();

  /// Cold-start shell until first Supabase auth event (see [AuthGateNotifier.isLoading]).
  static const splash = '/splash';
  static const launch = '/launch';
  static const signup = '/signup';
  static const login = '/login';
  /// Entry for “onboarding” in auth redirects; resolves to first onboarding step.
  static const onboarding = '/onboarding';
  static const onboardingOnb1 = '/onboarding/onb1';
  static const onboardingOnb2 = '/onboarding/onb2';
  static const onboardingOnb3 = '/onboarding/onb3';
  static const onboardingConvo = '/onboarding/convo';
  static const demo = '/demo';
  static const paywall = '/paywall';
  static const home = '/home';
  static const journalListing = '/journal';
  static const account = '/account';
  static const cancelConfirm = '/cancel-confirm';
  static const session = '/session';
  static const entryReview = '/entry-review';
}
