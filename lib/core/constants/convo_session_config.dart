/// Voice session shape for onboarding / journal convo (opening is separate).
abstract final class ConvoSessionConfig {
  /// How many times the user speaks after Lhamo's opening before wrap-up.
  /// Opening is already a question; then deeper → gratitude → final reflection.
  static const int userTurnsBeforeClose = 3;

  /// [exchange_count] for Lhamo's gratitude-focused question (user answers next).
  static const int gratitudeTurnExchangeCount = 1;

  /// [exchange_count] for Lhamo's last reflective line (no question).
  static const int finalTurnExchangeCount = userTurnsBeforeClose - 1;
}
