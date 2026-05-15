import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';

/// Signs in with Google; routing is handled by [GoRouter] redirect on auth change.
Future<void> completeGoogleSignIn(BuildContext context) async {
  final auth = context.read<AuthController>();
  final ok = await auth.signInWithGoogle();
  if (!context.mounted) return;
  if (ok) return;
  final err = auth.error;
  if (err != null && err.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err)),
    );
  }
}
