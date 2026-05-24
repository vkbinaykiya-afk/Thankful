/// Compile-time feature toggles for in-progress or deferred product areas.
class FeatureFlags {
  FeatureFlags._();

  /// Play session recording from expanded entry cards on home and journal listing.
  /// When false, recordings are not uploaded to Supabase Storage on save.
  static const bool entryAudioPlayback = false;

  /// Skip session limit / paywall for user IDs on the dev allowlist in
  /// `subscription_service.dart`. Set false to test the real gate / paywall.
  static const bool subscriptionDevBypass = false;

  /// Lifetime free sessions before paywall (saved entries in Supabase).
  /// Set to `0` to hit the paywall immediately when testing.
  static const int subscriptionFreeSessionLimit = 5;

  /// When true, ignore RevenueCat active entitlement for the session gate only.
  /// Set true while testing the 5-entry paywall if sandbox purchase left an active sub.
  static const bool subscriptionIgnoreRevenueCatEntitlement = true;
}
