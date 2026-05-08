import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/monk_mascot.dart';

class VoiceSessionScreen extends StatelessWidget {
  const VoiceSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.lg),
                child: Text(
                  'Voice session — voice pipeline coming soon',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Positioned(
              right: -20,
              bottom: 0,
              child: MonkMascot(state: MonkState.meditation),
            ),
          ],
        ),
      ),
    );
  }
}
