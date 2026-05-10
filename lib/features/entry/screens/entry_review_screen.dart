import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/primary_button.dart';

class EntryReviewScreen extends StatelessWidget {
  const EntryReviewScreen({super.key});

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
                  Text("Today's entry", style: theme.textTheme.displayMedium),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      maxLines: null,
                      expands: true,
                      style: theme.textTheme.bodyMedium,
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  PrimaryButton(label: 'Save Entry', onPressed: () {}),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            const Positioned(
              right: -20,
              bottom: 60,
              child: MonkMascot(state: MonkState.writing),
            ),
          ],
        ),
      ),
    );
  }
}
