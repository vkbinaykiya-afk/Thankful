import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/primary_button.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.lg),
              Text('Your first week is free', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppConstants.sm),
              Text(
                'Then \$7.99/month or \$44.99/year',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              PrimaryButton(label: 'Start Free Trial', onPressed: () {}),
              const SizedBox(height: AppConstants.sm),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Restore Purchases'),
                ),
              ),
              const SizedBox(height: AppConstants.md),
            ],
          ),
        ),
      ),
    );
  }
}
