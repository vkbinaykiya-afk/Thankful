import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/onboarding/screens/demo_session_screen.dart';
import '../features/onboarding/screens/launch_screen.dart';
import '../features/onboarding/screens/onb1_screen.dart';
import '../features/paywall/screens/paywall_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/session/screens/voice_session_screen.dart';
import '../features/entry/screens/entry_review_screen.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.launch,
  routes: [
    GoRoute(path: AppRoutes.launch, builder: (_, _) => const LaunchScreen()),
    GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupScreen()),
    GoRoute(
      path: AppRoutes.onboardingOnb1,
      builder: (_, _) => const Onb1Screen(),
    ),
    GoRoute(path: AppRoutes.demo, builder: (_, _) => const DemoSessionScreen()),
    GoRoute(path: AppRoutes.paywall, builder: (_, _) => const PaywallScreen()),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(path: AppRoutes.session, builder: (_, _) => const VoiceSessionScreen()),
    GoRoute(
      path: AppRoutes.entryReview,
      builder: (_, _) => const EntryReviewScreen(),
    ),
  ],
);
