import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';

Future<void> completeGoogleSignIn(
  BuildContext context, {
  required VoidCallback onSignedIn,
}) async {
  final auth = context.read<AuthController>();
  final ok = await auth.signInWithGoogle();
  if (!context.mounted) return;
  if (ok) {
    onSignedIn();
    return;
  }
  final err = auth.error;
  if (err != null && err.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err)),
    );
  }
}
