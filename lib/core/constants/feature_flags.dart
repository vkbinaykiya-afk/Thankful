/// Compile-time feature toggles for in-progress or deferred product areas.
class FeatureFlags {
  FeatureFlags._();

  /// Play session recording from expanded entry cards on home and journal listing.
  /// When false, recordings are not uploaded to Supabase Storage on save.
  static const bool entryAudioPlayback = false;

  /// Skip session limit / paywall for user IDs on the dev allowlist in
  /// `subscription_service.dart`. Set false to test the real gate / paywall.
  static const bool subscriptionDevBypass = false;

  /// Lifetime free journal entries before paywall (production: 5).
  /// Gate applies only to **creating** new sessions, not viewing/sharing on home.
  static const int subscriptionFreeSessionLimit = 50;

  /// When true, ignore RevenueCat active entitlement for the session gate only.
  /// Keep false for TestFlight / App Store — must be false or subscribers stay on paywall.
  static const bool subscriptionIgnoreRevenueCatEntitlement = true;

  /// Tap "Subscription debug" on Account screen (RevenueCat + gate state).
  /// Set false before App Store submission.
  static const bool subscriptionDebugPanel = true;
}
