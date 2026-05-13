/// Extra for [AppRoutes.entryReview] ([GoRouter] `state.extra`).
///
/// Legacy `extra: true` is supported via [fromGoRouterExtra].
class EntryReviewExtra {
  const EntryReviewExtra({
    this.showOnboardingProgress = false,
    this.recordingPath,
  });

  final bool showOnboardingProgress;
  final String? recordingPath;

  static ({bool showOnboardingProgress, String? recordingPath}) fromGoRouterExtra(
    Object? extra,
  ) {
    if (extra is EntryReviewExtra) {
      return (
        showOnboardingProgress: extra.showOnboardingProgress,
        recordingPath: extra.recordingPath,
      );
    }
    if (extra == true) {
      return (showOnboardingProgress: true, recordingPath: null);
    }
    return (showOnboardingProgress: false, recordingPath: null);
  }
}
