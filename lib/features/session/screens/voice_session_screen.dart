import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/primary_button.dart';

/// Placeholder voice session — wire to Deepgram / TTS / LLM later.
class VoiceSessionScreen extends StatelessWidget {
  const VoiceSessionScreen({super.key});

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Voice session — voice pipeline coming soon',
                        style: theme.textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  PrimaryButton(
                    label: 'Finish session',
                    onPressed: () => context.go(AppRoutes.entryReview),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            const Positioned(
              right: -20,
              bottom: 88,
              child: MonkMascot(state: MonkState.meditation),
            ),
          ],
        ),
      ),
    );
  }
}
