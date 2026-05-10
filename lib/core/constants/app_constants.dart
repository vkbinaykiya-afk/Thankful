class AppConstants {
  AppConstants._();

  static const String appName = 'Thankful';

  /// Splash monk entry — matches docs/reference/launch_screen.html & design system §9.
  static const Duration mascotEntryDuration = Duration(milliseconds: 600);
  static const double mascotEntryDriftPx = 8;
  static const double launchMonkWidthFraction = 0.92;

  static const Duration fadeInDuration = mascotEntryDuration;
  static const Duration screenEntry = Duration(milliseconds: 280);
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration cardPress = Duration(milliseconds: 150);
  static const Duration waveformBar = Duration(milliseconds: 120);
  static const Duration streakPulse = Duration(milliseconds: 2000);
}
