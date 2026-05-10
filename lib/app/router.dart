import 'package:go_router/go_router.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/onboarding/screens/demo_session_screen.dart';
import '../features/onboarding/screens/launch_screen.dart';
import '../features/paywall/screens/paywall_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/session/screens/voice_session_screen.dart';
import '../features/entry/screens/entry_review_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/launch',
  routes: [
    GoRoute(path: '/launch', builder: (_, _) => const LaunchScreen()),
    GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
    GoRoute(path: '/demo', builder: (_, _) => const DemoSessionScreen()),
    GoRoute(path: '/paywall', builder: (_, _) => const PaywallScreen()),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/session', builder: (_, _) => const VoiceSessionScreen()),
    GoRoute(path: '/entry-review', builder: (_, _) => const EntryReviewScreen()),
  ],
);
