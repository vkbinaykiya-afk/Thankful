import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/feature_flags.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_snack_bar.dart';

/// Opens the subscription / RevenueCat debug bottom sheet from Account.
Future<void> showSubscriptionDebugSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => const _SubscriptionDebugSheet(),
  );
}

class _SubscriptionDebugSheet extends StatefulWidget {
  const _SubscriptionDebugSheet();

  @override
  State<_SubscriptionDebugSheet> createState() =>
      _SubscriptionDebugSheetState();
}

class _SubscriptionDebugSheetState extends State<_SubscriptionDebugSheet> {
  SubscriptionDebugSnapshot? _snapshot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await SubscriptionService.loadDebugSnapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _copyAll() async {
    final text = _snapshot?.displayText;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppSnackBar.show(
      context,
      'Debug info copied',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: maxHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sm,
          AppSpacing.screenH,
          AppSpacing.md + bottomInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Subscription debug',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _loading ? null : _load,
                child: Text(
                  'Refresh',
                  style: AppTextStyles.captionMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _snapshot == null ? null : _copyAll,
                child: Text(
                  'Copy',
                  style: AppTextStyles.captionMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (!FeatureFlags.subscriptionDebugPanel)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                'subscriptionDebugPanel is false in feature_flags.dart',
                style: AppTextStyles.micro.copyWith(
                  fontSize: 11,
                  color: AppColors.error,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _error != null
                    ? SingleChildScrollView(
                        child: SelectableText(
                          _error!,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: SelectableText(
                          _snapshot!.displayText,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: AppColors.textJournal,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Search RevenueCat Customers by Supabase user ID. Remove before App Store.',
            style: AppTextStyles.micro.copyWith(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          ],
        ),
      ),
    );
  }
}
