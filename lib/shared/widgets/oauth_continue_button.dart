import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum OAuthContinueKind { apple, google }

/// Pill OAuth row: cream fill, dark label, leading circular brand badge.
/// Matches signup HTML / Framer mock (not apricot [PrimaryButton]).
class OAuthContinueButton extends StatefulWidget {
  final OAuthContinueKind kind;
  final VoidCallback? onPressed;

  const OAuthContinueButton({super.key, required this.kind, this.onPressed});

  @override
  State<OAuthContinueButton> createState() => _OAuthContinueButtonState();
}

class _OAuthContinueButtonState extends State<OAuthContinueButton> {
  bool _pressed = false;

  String get _label => widget.kind == OAuthContinueKind.apple
      ? 'Continue with Apple'
      : 'Continue with Google';

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn,
        opacity: disabled ? 0.45 : (_pressed ? 0.82 : 1.0),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.oauthButtonFill,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _OAuthBadge(kind: widget.kind),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OAuthBadge extends StatelessWidget {
  final OAuthContinueKind kind;

  const _OAuthBadge({required this.kind});

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    if (kind == OAuthContinueKind.apple) {
      return Container(
        width: _size,
        height: _size,
        decoration: const BoxDecoration(
          color: AppColors.textPrimary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.apple, color: Colors.white, size: 22),
      );
    }

    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(
        color: AppColors.googleBrandCircle,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: AppTextStyles.heading3.copyWith(
          fontSize: 18,
          height: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}
