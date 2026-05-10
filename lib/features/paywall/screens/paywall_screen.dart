import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text('Your first week is free', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Then \$7.99/month or \$44.99/year',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Start Free Trial',
                onPressed: () => context.go(AppRoutes.home),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Restore Purchases'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
