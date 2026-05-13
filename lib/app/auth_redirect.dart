import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_gate_notifier.dart';
import 'app_routes.dart';

bool get _forceOnboarding =>
    dotenv.env['FORCE_ONBOARDING']?.trim().toLowerCase() == 'true';

bool _isPublic(String loc) =>
    loc == AppRoutes.launch ||
    loc == AppRoutes.login ||
    loc == AppRoutes.signup;

bool _isSplash(String loc) => loc == AppRoutes.splash;

bool _isOnboardingZone(String loc) =>
    loc == AppRoutes.onboarding || loc.startsWith('/onboarding/');

/// Steps after `/onboarding/*` but still part of first-run (not under that path).
/// Without this, [authRedirect] would send paywall / entry / session back to onboarding.
bool _isOnboardingFunnel(String loc) =>
    _isOnboardingZone(loc) ||
    loc == AppRoutes.paywall ||
    loc == AppRoutes.entryReview ||
    loc == AppRoutes.demo ||
    loc == AppRoutes.session;

/// Auth gate for [GoRouter.redirect]. Uses [authGate] for profile-loading state.
///
/// [FORCE_ONBOARDING]: when `true`, every **signed-in** user is steered into onboarding
/// until they reach main app surfaces (home, journal, account). Funnel routes
/// (session → entry → paywall) are not redirected away. When `false`, routing follows
/// `users` row: no row → onboarding + same funnel; row → home. Unsigned users always
/// use login/signup.
String? authRedirect(GoRouterState state, AuthGateNotifier authGate) {
  if (!Supabase.instance.isInitialized) {
    return null;
  }

  final loc = state.matchedLocation;

  if (authGate.isLoading) {
    if (_isSplash(loc)) {
      return null;
    }
    return AppRoutes.splash;
  }

  final session = Supabase.instance.client.auth.currentSession;

  if (session == null) {
    if (_isPublic(loc)) {
      return null;
    }
    return AppRoutes.login;
  }

  // Signed in: dev-only — start from onboarding, but do not trap the paywall → home path.
  if (_forceOnboarding) {
    if (_isOnboardingFunnel(loc)) {
      return null;
    }
    if (loc == AppRoutes.home ||
        loc == AppRoutes.journalListing ||
        loc == AppRoutes.account ||
        loc == AppRoutes.cancelConfirm) {
      return null;
    }
    return AppRoutes.onboarding;
  }

  if (authGate.isProfileLoading) {
    if (_isSplash(loc) || loc == AppRoutes.launch || _isPublic(loc)) {
      return null;
    }
    return AppRoutes.splash;
  }

  if (authGate.hasUsersRow == false) {
    if (_isOnboardingFunnel(loc)) {
      return null;
    }
    return AppRoutes.onboarding;
  }

  if (_isOnboardingZone(loc) ||
      loc == AppRoutes.login ||
      loc == AppRoutes.signup) {
    return AppRoutes.home;
  }
  if (loc == AppRoutes.splash || loc == AppRoutes.launch) {
    return AppRoutes.home;
  }
  return null;
}
