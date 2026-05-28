import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_routes.dart';
import 'core/router/go_router_refresh_stream.dart';
import 'core/services/analytics_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/account/screens/cancel_confirm_screen.dart';
import 'features/account/screens/user_account_screen.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/entry/entry_review_extra.dart';
import 'features/entry/screens/entry_review_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/journal/screens/journal_listing_screen.dart';
import 'features/onboarding/screens/demo_session_screen.dart';
import 'features/onboarding/screens/launch_screen.dart';
import 'features/onboarding/screens/onb1_screen.dart';
import 'features/onboarding/screens/onb2_screen.dart';
import 'features/onboarding/screens/onb3_screen.dart';
import 'features/onboarding/screens/onboarding_convo_screen.dart';
import 'features/onboarding/screens/onboarding_intent_screen.dart';
import 'features/onboarding/screens/onboarding_lhamo_intro_screen.dart';
import 'features/paywall/screens/paywall_screen.dart';

String? _trimEnv(String? raw) {
  if (raw == null) return null;
  var v = raw.trim();
  if (v.length >= 2) {
    final q = v[0];
    if ((q == '"' || q == "'") && v.endsWith(q)) {
      v = v.substring(1, v.length - 1).trim();
    }
  }
  return v.isEmpty ? null : v;
}

/// The SDK starts [SupabaseAuth.recoverSession] without awaiting it after
/// [Supabase.initialize], so [GoTrueClient.currentSession] can still be null
/// briefly even when a session is persisted. Align reads with that work.
Future<void> _awaitSupabaseAuthHydration() async {
  final auth = Supabase.instance.client.auth;
  try {
    await auth.onAuthStateChange.first.timeout(const Duration(seconds: 5));
  } on TimeoutException {
    // Unlikely — proceed to read currentSession
  } catch (_) {
    // Stream error — proceed; currentSession may still be set
  }
  if (auth.currentSession != null) return;
  // Expired-token refresh runs in the background recover path; give it a beat.
  await Future<void>.delayed(const Duration(milliseconds: 300));
}

bool _isOnboardingCompleteValue(dynamic value) {
  if (value == true) return true;
  if (value is String) {
    final v = value.trim().toLowerCase();
    return v == 'true' || v == 't' || v == '1';
  }
  if (value is num) return value == 1;
  return false;
}

bool _isOnboardingPath(String location) {
  return location == AppRoutes.onboardingOnb1 ||
      location == AppRoutes.onboardingOnb2 ||
      location == AppRoutes.onboardingLhamoIntro ||
      location == AppRoutes.onboardingIntent ||
      location == AppRoutes.onboardingOnb3 ||
      location == AppRoutes.demo;
}

Future<bool> _queryOnboardingComplete(String userId) async {
  try {
    final row = Map<String, dynamic>.from(
      await Supabase.instance.client
              .from('users')
              .select('onboarding_complete')
              .eq('id', userId)
              .single()
          as Map,
    );
    return _isOnboardingCompleteValue(row['onboarding_complete']);
  } catch (_) {
    return false;
  }
}

Future<String?> _thankfulAuthRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  if (!SupabaseService.isInitialized) return null;

  final location = state.matchedLocation;
  final hasSession = Supabase.instance.client.auth.currentSession != null;

  const publicPaths = {AppRoutes.login, AppRoutes.signup, AppRoutes.launch};

  if (!hasSession) {
    if (!publicPaths.contains(location)) {
      return AppRoutes.login;
    }
    return null;
  }

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return AppRoutes.login;

  final onboardingComplete = await _queryOnboardingComplete(user.id);

  if (onboardingComplete && _isOnboardingPath(location)) {
    return AppRoutes.home;
  }

  if (location == AppRoutes.login || location == AppRoutes.signup) {
    return onboardingComplete ? AppRoutes.home : AppRoutes.onboardingOnb1;
  }

  return null;
}

GoRouter _thankfulGoRouter({
  required String initialLocation,
  Listenable? refreshListenable,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: _thankfulAuthRedirect,
    routes: [
      GoRoute(path: AppRoutes.launch, builder: (_, _) => const LaunchScreen()),
      GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.onboardingOnb1,
        builder: (_, _) => const Onb1Screen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingOnb2,
        builder: (_, _) => const Onb2Screen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingLhamoIntro,
        builder: (_, _) => const OnboardingLhamoIntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingIntent,
        builder: (_, _) => const OnboardingIntentScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingOnb3,
        builder: (_, _) => const Onb3Screen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingConvo,
        builder: (_, _) => const OnboardingConvoScreen(),
      ),
      GoRoute(
        path: AppRoutes.demo,
        builder: (_, _) => const DemoSessionScreen(),
      ),
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
      GoRoute(
        path: AppRoutes.session,
        builder: (_, _) => const OnboardingConvoScreen(),
      ),
      GoRoute(
        path: AppRoutes.entryReview,
        builder: (context, state) {
          final e = EntryReviewExtra.fromGoRouterExtra(state.extra);
          return EntryReviewScreen(
            showOnboardingProgress: e.showOnboardingProgress,
            initialRecordingPath: e.recordingPath,
            initialTranscript: e.transcript,
          );
        },
      ),
    ],
  );
}

class _ThankfulAppRoot extends StatelessWidget {
  const _ThankfulAppRoot({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: MaterialApp.router(
        title: 'Thankful',
        theme: AppTheme.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('dotenv.load(.env) failed: $e\n$st');
    }
  }

  final googleWebClientId = dotenv.isInitialized
      ? _trimEnv(dotenv.env['GOOGLE_WEB_CLIENT_ID'])
      : null;
  await GoogleSignIn.instance.initialize(
    serverClientId: googleWebClientId != null && googleWebClientId.isNotEmpty
        ? googleWebClientId
        : null,
  );

  const defineUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const defineKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  final urlDot = dotenv.isInitialized
      ? _trimEnv(dotenv.env['SUPABASE_URL'])
      : null;
  final keyDot = dotenv.isInitialized
      ? _trimEnv(dotenv.env['SUPABASE_ANON_KEY'])
      : null;

  final url = (urlDot != null && urlDot.isNotEmpty) ? urlDot : defineUrl.trim();
  final anonKey = (keyDot != null && keyDot.isNotEmpty)
      ? keyDot
      : defineKey.trim();

  var initialLocation = AppRoutes.login;
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      SupabaseService.markInitialized();
      await _awaitSupabaseAuthHydration();
      final hasSession = Supabase.instance.client.auth.currentSession != null;
      print('hasSession: $hasSession');
      if (hasSession) {
        final user = Supabase.instance.client.auth.currentUser;
        var onboardingComplete = false;
        Map<String, dynamic>? row;
        if (user != null) {
          try {
            row = Map<String, dynamic>.from(
              await Supabase.instance.client
                      .from('users')
                      .select('onboarding_complete')
                      .eq('id', user.id)
                      .single()
                  as Map,
            );
            onboardingComplete = _isOnboardingCompleteValue(
              row['onboarding_complete'],
            );
          } catch (_) {
            onboardingComplete = false;
          }
        }
        print('onboardingComplete raw: ${row?['onboarding_complete']}');
        print('onboardingComplete: $onboardingComplete');
        initialLocation = onboardingComplete
            ? AppRoutes.home
            : AppRoutes.onboardingOnb1;
        print('initialLocation: $initialLocation');
      } else {
        // Show launch screen only on first ever install
        final prefs = await SharedPreferences.getInstance();
        final hasLaunchedBefore =
            prefs.getBool('has_launched_before') ?? false;
        print('[Launch] has_launched_before: $hasLaunchedBefore');
        if (!hasLaunchedBefore) {
          await prefs.setBool('has_launched_before', true);
          initialLocation = AppRoutes.launch;
          print('[Launch] First install detected — showing launch screen');
        } else {
          initialLocation = AppRoutes.login;
          print('[Launch] Returning unauthenticated user — showing login');
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Supabase.initialize failed: $e\n$st');
      }
    }
  } else if (kDebugMode) {
    debugPrint(
      'Supabase skipped: SUPABASE_URL / SUPABASE_ANON_KEY missing in .env '
      'and not passed as --dart-define. Keys loaded: '
      '${dotenv.isInitialized ? dotenv.env.length : 0}',
    );
  }

  await SubscriptionService.initialise();

  if (SupabaseService.isInitialized) {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      try {
        if ((data.event == AuthChangeEvent.signedIn ||
                data.event == AuthChangeEvent.initialSession) &&
            data.session?.user.id != null) {
          final userId = data.session!.user.id;
          await SubscriptionService.ensureRevenueCatUserLinked();
          await AnalyticsService.identify(
            userId,
            email: data.session?.user.email,
            name: data.session?.user.userMetadata?['name']?.toString(),
          );
        } else if (data.event == AuthChangeEvent.signedOut) {
          await Purchases.logOut();
          await AnalyticsService.reset();
          print('[RevenueCat] Logged out');
        }
      } catch (e) {
        print('[RevenueCat] Auth state listener error: $e');
      }
    });
  }

  final refreshListenable = SupabaseService.isInitialized
      ? GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange)
      : null;

  final router = _thankfulGoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
  );
  runApp(_ThankfulAppRoot(router: router));
}
