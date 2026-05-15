/// Extra for [AppRoutes.entryReview] ([GoRouter] `state.extra`).
///
/// Legacy `extra: true` is supported via [fromGoRouterExtra].
class EntryReviewExtra {
  const EntryReviewExtra({
    this.showOnboardingProgress = false,
    this.recordingPath,
    this.transcript,
  });

  final bool showOnboardingProgress;
  final String? recordingPath;
  final String? transcript;

  static ({
    bool showOnboardingProgress,
    String? recordingPath,
    String? transcript,
  }) fromGoRouterExtra(
    Object? extra,
  ) {
    if (extra is EntryReviewExtra) {
      return (
        showOnboardingProgress: extra.showOnboardingProgress,
        recordingPath: extra.recordingPath,
        transcript: extra.transcript,
      );
    }
    if (extra == true) {
      return (showOnboardingProgress: true, recordingPath: null, transcript: null);
    }
    return (showOnboardingProgress: false, recordingPath: null, transcript: null);
  }
}
