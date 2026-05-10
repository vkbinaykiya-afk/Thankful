import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good morning', style: theme.textTheme.displayMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Day streak: 0', style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Past entries', style: theme.textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: Center(
                      child: Text(
                        'No entries yet.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: 'Start Session',
                    onPressed: () {},
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            const Positioned(
              right: -20,
              bottom: 60,
              child: MonkMascot(state: MonkState.meditation),
            ),
          ],
        ),
      ),
    );
  }
}
