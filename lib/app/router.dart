import 'package:go_router/go_router.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/onboarding/screens/demo_session_screen.dart';
import '../features/paywall/screens/paywall_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/session/screens/voice_session_screen.dart';
import '../features/entry/screens/entry_review_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/signup',
  routes: [
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/demo', builder: (_, __) => const DemoSessionScreen()),
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/session', builder: (_, __) => const VoiceSessionScreen()),
    GoRoute(path: '/entry-review', builder: (_, __) => const EntryReviewScreen()),
  ],
);
