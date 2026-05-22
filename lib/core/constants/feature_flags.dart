/// Compile-time feature toggles for in-progress or deferred product areas.
class FeatureFlags {
  FeatureFlags._();

  /// Play session recording from expanded entry cards on home and journal listing.
  /// When false, recordings are not uploaded to Supabase Storage on save.
  static const bool entryAudioPlayback = false;
}
