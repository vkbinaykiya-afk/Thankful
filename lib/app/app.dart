import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_gate_notifier.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/controllers/auth_controller.dart';
import 'router.dart';

class ThankfulApp extends StatefulWidget {
  const ThankfulApp({super.key});

  @override
  State<ThankfulApp> createState() => _ThankfulAppState();
}

class _ThankfulAppState extends State<ThankfulApp> {
  late final AuthGateNotifier _authGate;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authGate = AuthGateNotifier();
    _router = createAppRouter(_authGate);
    _authGate.start();
  }

  @override
  void dispose() {
    _authGate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthGateNotifier>.value(value: _authGate),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Thankful',
        theme: AppTheme.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
