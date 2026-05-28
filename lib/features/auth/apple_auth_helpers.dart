import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/app_snack_bar.dart';
import 'controllers/auth_controller.dart';

/// Signs in with Apple; routing is handled by [GoRouter] redirect on auth change.
Future<void> completeAppleSignIn(BuildContext context) async {
  final auth = context.read<AuthController>();
  final ok = await auth.signInWithApple();
  if (!context.mounted) return;
  if (ok) return;
  final err = auth.error;
  if (err != null && err.isNotEmpty) {
    AppSnackBar.show(
      context,
      err,
      isError: true,
    );
  }
}
