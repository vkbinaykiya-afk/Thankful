import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_routes.dart';
import 'controllers/auth_controller.dart';

Future<void> completeGoogleSignIn(BuildContext context) async {
  final auth = context.read<AuthController>();
  final ok = await auth.signInWithGoogle();
  if (!context.mounted) return;
  if (ok) {
    // Auth gate sends new users → /onboarding, returning → /home.
    GoRouter.of(context).go(AppRoutes.home);
    return;
  }
  final err = auth.error;
  if (err != null && err.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err)),
    );
  }
}
