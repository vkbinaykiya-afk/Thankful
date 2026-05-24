import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_routes.dart';
import '../constants/feature_flags.dart';
import 'supabase_service.dart';

/// Subscription and session gate service (RevenueCat + free tier limit).
class SubscriptionService {
  const SubscriptionService();

  static int get freeSessionLimit => FeatureFlags.subscriptionFreeSessionLimit;
  static const String _entitlementId = 'Thankful: AI voice Journal Pro';
  static const String _offeringId = 'ThankfulDefault';

  // DEV BYPASS — remove before App Store submission
  static const List<String> _devBypassUserIds = [
    '7280bf48-fddf-4630-9466-1b7cc97f8234',
  ];

  static bool _hasDevBypass(String userId) =>
      FeatureFlags.subscriptionDevBypass &&
      _devBypassUserIds.contains(userId);

  /// Call once at app startup in main.dart after dotenv.load()
  static Future<void> initialise() async {
    final apiKey = dotenv.env['REVENUECAT_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      print('[RevenueCat] REVENUECAT_API_KEY missing — skipping init');
      return;
    }
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);
      print('[RevenueCat] Initialised');

      // Identify user with Supabase user ID so RevenueCat links purchases to user
      if (SupabaseService.isInitialized) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await Purchases.logIn(userId);
          print('[RevenueCat] Logged in user: $userId');
        }
      }
    } catch (e) {
      print('[RevenueCat] initialise error: $e');
    }
  }

  /// Returns true if user has active premium entitlement (includes free trial).
  Future<bool> isSubscribed() async {
    if (FeatureFlags.subscriptionIgnoreRevenueCatEntitlement) {
      print('[RevenueCat] isSubscribed: ignored (subscriptionIgnoreRevenueCatEntitlement)');
      return false;
    }
    try {
      final info = await Purchases.getCustomerInfo();
      final activeKeys = info.entitlements.active.keys.toList();
      final active = info.entitlements.active.containsKey(_entitlementId);
      print(
        '[RevenueCat] isSubscribed: $active | active entitlements: $activeKeys | '
        'looking for: $_entitlementId',
      );
      return active;
    } catch (e) {
      print('[RevenueCat] isSubscribed error: $e — defaulting to false');
      return false;
    }
  }

  /// Navigate to convo or paywall depending on [canStartSession].
  static Future<void> navigateToSessionOrPaywall(
    BuildContext context, {
    bool paywallOnboardingProgress = false,
  }) async {
    final canStart = await const SubscriptionService().canStartSession();
    if (!context.mounted) return;
    if (!canStart) {
      print('[Subscription] Blocked — navigating to paywall');
      context.go(
        AppRoutes.paywall,
        extra: paywallOnboardingProgress ? true : null,
      );
      return;
    }
    context.go(AppRoutes.onboardingConvo);
  }

  /// Fetch the default offering from RevenueCat.
  Future<Offering?> getOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering =
          offerings.getOffering(_offeringId) ?? offerings.current;
      print('[RevenueCat] Offering: ${offering?.identifier}');
      return offering;
    } catch (e) {
      print('[RevenueCat] getOffering error: $e');
      return null;
    }
  }

  /// Purchase a package. Returns true on success.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final active =
          result.customerInfo.entitlements.active.containsKey(_entitlementId);
      print('[RevenueCat] Purchase complete — entitlement active: $active');
      return active;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        print('[RevenueCat] Purchase cancelled by user');
        return false;
      }
      print('[RevenueCat] Purchase error: $code');
      return false;
    } catch (e) {
      print('[RevenueCat] Purchase unexpected error: $e');
      return false;
    }
  }

  /// Restore purchases — call from paywall restore button.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      final active = info.entitlements.active.containsKey(_entitlementId);
      print('[RevenueCat] Restore complete — entitlement active: $active');
      return active;
    } catch (e) {
      print('[RevenueCat] Restore error: $e');
      return false;
    }
  }

  /// Total saved entries for the current user.
  Future<int> getLifetimeSessionCount() async {
    if (!SupabaseService.isInitialized) {
      print('[Subscription] getLifetimeSessionCount: Supabase not initialized');
      return freeSessionLimit;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[Subscription] getLifetimeSessionCount: no auth user');
      return 0;
    }
    try {
      final rows = await Supabase.instance.client
          .from('entries')
          .select('id')
          .eq('user_id', user.id);
      final count = (rows as List).length;
      print(
        '[Subscription] lifetime session count: $count (user_id=${user.id})',
      );
      return count;
    } catch (e) {
      print('[Subscription] getLifetimeSessionCount error: $e — failing closed');
      return freeSessionLimit;
    }
  }

  /// Returns true if user can start a new session.
  Future<bool> canStartSession() async {
    if (!SupabaseService.isInitialized) {
      print('[Subscription] BLOCKED — Supabase not initialized');
      return false;
    }
    final user = Supabase.instance.client.auth.currentUser;
    print('[Subscription] Gate check for user_id=${user?.id ?? "none"}');
    if (user != null && _hasDevBypass(user.id)) {
      print('[Subscription] ALLOWED — dev bypass for ${user.id}');
      return true;
    }
    final subscribed = await isSubscribed();
    if (subscribed) {
      print('[Subscription] ALLOWED — RevenueCat entitlement active');
      return true;
    }
    final count = await getLifetimeSessionCount();
    final allowed = count < freeSessionLimit;
    if (allowed) {
      final remaining = freeSessionLimit - count;
      print(
        '[Subscription] ALLOWED — free tier ($remaining of $freeSessionLimit '
        'sessions left, $count saved)',
      );
    } else {
      print(
        '[Subscription] BLOCKED — free limit reached ($count >= $freeSessionLimit)',
      );
    }
    return allowed;
  }

  /// Sessions remaining for free users. Returns null if subscribed.
  Future<int?> sessionsRemaining() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _hasDevBypass(user.id)) return null;
    final subscribed = await isSubscribed();
    if (subscribed) return null;
    final count = await getLifetimeSessionCount();
    return (freeSessionLimit - count).clamp(0, freeSessionLimit);
  }
}
