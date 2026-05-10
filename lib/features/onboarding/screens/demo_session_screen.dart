import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/monk_mascot.dart';

class DemoSessionScreen extends StatelessWidget {
  const DemoSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Demo session — coming soon',
                  style: Theme.of(context).textTheme.displaySmall,
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
