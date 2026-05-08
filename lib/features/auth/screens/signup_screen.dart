import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/monk_mascot.dart';
import '../../../shared/widgets/primary_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppConstants.fadeInDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppConstants.xl),
                    Text(
                      'Your daily\ngratitude ritual.',
                      style: theme.textTheme.displayLarge,
                    ),
                    const SizedBox(height: AppConstants.sm),
                    Text(
                      'Speak. Listen. Grow.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Continue with Apple',
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppConstants.sm),
                    PrimaryButton(
                      label: 'Continue with Google',
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppConstants.sm),
                    PrimaryButton(
                      label: 'Continue with Email',
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppConstants.lg),
                  ],
                ),
              ),
              const Positioned(
                right: -20,
                bottom: 0,
                child: MonkMascot(
                  state: MonkState.namaste,
                  width: 200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
