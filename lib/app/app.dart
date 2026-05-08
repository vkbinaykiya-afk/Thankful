import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class ThankfulApp extends StatelessWidget {
  const ThankfulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Thankful',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
