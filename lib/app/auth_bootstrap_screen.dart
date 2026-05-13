import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Blank screen while [AuthGateNotifier.isLoading] waits for the first
/// [Supabase.auth.onAuthStateChange] event (cold start).
class AuthBootstrapScreen extends StatelessWidget {
  const AuthBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: SizedBox.expand(),
    );
  }
}
