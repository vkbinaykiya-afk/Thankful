import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'subscription_service.dart';
import 'supabase_service.dart';

class AnalyticsService {
  const AnalyticsService();

  // ── Helpers ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _baseProps() async {
    if (!SupabaseService.isInitialized) {
      return {
        'user_id': 'anonymous',
        'is_subscribed': false,
        'entry_count': 0,
      };
    }

    final user = Supabase.instance.client.auth.currentUser;
    final isSubscribed = await const SubscriptionService().isSubscribed();
    final entryCount =
        await const SubscriptionService().getLifetimeSessionCount();
    return {
      'user_id': user?.id ?? 'anonymous',
      'is_subscribed': isSubscribed,
      'entry_count': entryCount,
    };
  }

  static Future<void> _capture(
    String event, [
    Map<String, dynamic>? props,
  ]) async {
    try {
      final base = await _baseProps();
      await Posthog().capture(
        eventName: event,
        properties: {...base, ...?props},
      );
      print('[Analytics] $event | props: ${props ?? {}}');
    } catch (e) {
      print('[Analytics] Failed to capture $event: $e');
    }
  }

  static Future<void> screen(String screenName) async {
    try {
      await Posthog().screen(screenName: screenName);
      print('[Analytics] screen: $screenName');
    } catch (e) {
      print('[Analytics] Failed to track screen $screenName: $e');
    }
  }

  // ── Identity ──────────────────────────────────────────────

  static Future<void> identify(
    String userId, {
    String? email,
    String? name,
  }) async {
    try {
      await Posthog().identify(
        userId: userId,
        userPropertiesSetOnce: {
          if (email != null) 'email': email,
          if (name != null) 'name': name,
        },
      );
      print('[Analytics] identify: $userId');
    } catch (e) {
      print('[Analytics] identify failed: $e');
    }
  }

  static Future<void> reset() async {
    try {
      await Posthog().reset();
      print('[Analytics] reset');
    } catch (e) {
      print('[Analytics] reset failed: $e');
    }
  }

  // ── Onboarding ──────────────────────────────────────────────

  static Future<void> onboardingStarted() => _capture('onboarding_started');

  static Future<void> onboardingStepCompleted(int step, String stepName) =>
      _capture('onboarding_step_completed', {
        'step': step,
        'step_name': stepName,
      });

  static Future<void> onboardingCompleted() => _capture('onboarding_completed');

  static Future<void> intentSelected(List<String> intents) =>
      _capture('intent_selected', {'intents': intents});

  // ── Session ──────────────────────────────────────────────

  static Future<void> sessionStarted() => _capture('session_started');

  static Future<void> sessionCompleted(int exchangeCount) => _capture(
        'session_completed',
        {
          'exchange_count': exchangeCount,
          'completed_naturally': true,
        },
      );

  static Future<void> sessionExitedEarly(int exchangeCount) => _capture(
        'session_exited_early',
        {'exchange_count': exchangeCount},
      );

  // ── Entries ──────────────────────────────────────────────

  static Future<void> entrySaved({
    required bool hasHighlightQuote,
    required String? mood,
    required int tagCount,
  }) =>
      _capture('entry_saved', {
        'has_highlight_quote': hasHighlightQuote,
        'mood': mood ?? 'unknown',
        'tag_count': tagCount,
      });

  static Future<void> entryShared(bool hasHighlightQuote) => _capture(
        'entry_shared',
        {'has_highlight_quote': hasHighlightQuote},
      );

  // ── Paywall ──────────────────────────────────────────────

  static Future<void> paywallViewed(String trigger) =>
      _capture('paywall_viewed', {'trigger': trigger});

  static Future<void> trialStarted(String plan) =>
      _capture('trial_started', {'plan': plan});

  static Future<void> subscriptionPurchased(String plan) =>
      _capture('subscription_purchased', {'plan': plan});

  static Future<void> restoreAttempted(bool success) =>
      _capture('restore_attempted', {'success': success});

  static Future<void> cancelSubscriptionTapped() =>
      _capture('cancel_subscription_tapped');

  // ── Navigation ──────────────────────────────────────────────

  static Future<void> makeAnotherEntryTapped() =>
      _capture('make_another_entry_tapped');

  static Future<void> journalListingViewed() =>
      _capture('journal_listing_viewed');

  static Future<void> micPermissionDenied() => _capture('mic_permission_denied');
}
