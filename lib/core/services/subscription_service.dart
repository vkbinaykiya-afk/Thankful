import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Subscription and session gate service.
/// Phase 1 — stub: isSubscribed always returns false.
/// Phase 2 — wire to RevenueCat entitlement check.
class SubscriptionService {
  const SubscriptionService();

  static const int freeSessionLimit = 5;

  // DEV BYPASS — remove before App Store submission
  static const List<String> _devBypassUserIds = [
    '7280bf48-fddf-4630-9466-1b7cc97f8234',
  ];

  /// Phase 1 stub — always returns false until RevenueCat is wired.
  /// Replace this body with RevenueCat entitlement check in Phase 2.
  Future<bool> isSubscribed() async {
    print('[Subscription] isSubscribed: stub returning false');
    return false;
  }

  /// Total saved entries for the current user.
  Future<int> getLifetimeSessionCount() async {
    if (!SupabaseService.isInitialized) return 0;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;
    try {
      final response = await Supabase.instance.client
          .from('entries')
          .select('id')
          .eq('user_id', user.id)
          .count(CountOption.exact);
      final count = response.count;
      print('[Subscription] lifetime session count: $count');
      return count;
    } catch (e) {
      print('[Subscription] getLifetimeSessionCount error: $e');
      return 0;
    }
  }

  /// Returns true if the user can start a new session.
  /// Free users: allowed up to 5 lifetime sessions.
  /// Subscribed users: always allowed.
  Future<bool> canStartSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _devBypassUserIds.contains(user.id)) {
      print('[Subscription] DEV BYPASS active — skipping gate for ${user.id}');
      return true;
    }
    final subscribed = await isSubscribed();
    if (subscribed) {
      print('[Subscription] canStartSession: subscribed — allowed');
      return true;
    }
    final count = await getLifetimeSessionCount();
    final allowed = count < freeSessionLimit;
    print(
      '[Subscription] canStartSession: count=$count limit=$freeSessionLimit allowed=$allowed',
    );
    return allowed;
  }

  /// Sessions remaining for free users. Returns null if subscribed.
  Future<int?> sessionsRemaining() async {
    final subscribed = await isSubscribed();
    if (subscribed) return null;
    final count = await getLifetimeSessionCount();
    return (freeSessionLimit - count).clamp(0, freeSessionLimit);
  }
}
