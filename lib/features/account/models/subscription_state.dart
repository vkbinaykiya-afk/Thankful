/// RevenueCat-ready subscription UI state (`user_account_screen.html` / screen10 patterns).
enum SubscriptionState {
  /// Paid subscriber — renews on schedule.
  activePaid,

  /// In free trial before first conversion.
  activeTrial,

  /// No entitlement — trial ended or subscription lapsed.
  lapsed,
}
