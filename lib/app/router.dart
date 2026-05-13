import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'auth_bootstrap_screen.dart';
import 'auth_redirect.dart';
import '../core/auth/auth_gate_notifier.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/onboarding/screens/demo_session_screen.dart';
import '../features/onboarding/screens/launch_screen.dart';
import '../features/onboarding/screens/onb1_screen.dart';
import '../features/onboarding/screens/onb2_screen.dart';
import '../features/onboarding/screens/onb3_screen.dart';
import '../features/onboarding/screens/onboarding_convo_screen.dart';
import '../features/paywall/screens/paywall_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/journal/screens/journal_listing_screen.dart';
import '../features/account/screens/cancel_confirm_screen.dart';
import '../features/account/screens/user_account_screen.dart';
import '../features/session/screens/voice_session_screen.dart';
import '../features/entry/screens/entry_review_screen.dart';

GoRouter createAppRouter(AuthGateNotifier authGate) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authGate,
    redirect: (context, state) => authRedirect(state, authGate),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const AuthBootstrapScreen(),
      ),
      GoRoute(path: AppRoutes.launch, builder: (_, _) => const LaunchScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        redirect: (context, state) => AppRoutes.onboardingOnb1,
      ),
      GoRoute(
        path: AppRoutes.onboardingOnb1,
        builder: (_, _) => const Onb1Screen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingOnb2,
        builder: (_, _) => const Onb2Screen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingOnb3,
        builder: (_, _) => const Onb3Screen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingConvo,
        builder: (_, _) => const OnboardingConvoScreen(),
      ),
      GoRoute(path: AppRoutes.demo, builder: (_, _) => const DemoSessionScreen()),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) {
          final onboarding = state.extra == true;
          return PaywallScreen(showOnboardingProgress: onboarding);
        },
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.journalListing,
        builder: (_, _) => const JournalListingScreen(),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (_, _) => const UserAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.cancelConfirm,
        builder: (_, _) => const CancelConfirmScreen(),
      ),
      GoRoute(path: AppRoutes.session, builder: (_, _) => const VoiceSessionScreen()),
      GoRoute(
        path: AppRoutes.entryReview,
        builder: (context, state) {
          final onboarding = state.extra == true;
          return EntryReviewScreen(showOnboardingProgress: onboarding);
        },
      ),
    ],
  );
}
