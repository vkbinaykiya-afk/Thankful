import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

/// Placeholder voice session — wire to Deepgram / TTS / LLM later.
class VoiceSessionScreen extends StatelessWidget {
  const VoiceSessionScreen({super.key});

  Future<void> _onRecordTap() async {
    final recorder = AudioRecorder();
    try {
      final granted = await recorder.hasPermission(request: false);
      if (!granted) {
        await recorder.hasPermission(request: true);
      }
    } finally {
      await recorder.dispose();
    }
  }

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
                    label: 'Record',
                    onPressed: _onRecordTap,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: 'Finish session',
                    onPressed: () =>
                        context.go(AppRoutes.paywall, extra: true),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Start over',
                    onPressed: () =>
                        context.go(AppRoutes.onboardingConvo),
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
