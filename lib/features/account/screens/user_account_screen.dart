import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Matches `docs/reference/design_htmls/user_account_screen.html`.
class UserAccountScreen extends StatelessWidget {
  const UserAccountScreen({super.key});

  static String _displayName() {
    if (!SupabaseService.isInitialized) return 'Guest';
    final user = SupabaseService.client.auth.currentUser;
    final metaName = user?.userMetadata?['name'];
    if (metaName is String && metaName.trim().isNotEmpty) {
      return metaName.trim();
    }
    return 'Member';
  }

  static String _email() {
    if (!SupabaseService.isInitialized) return '';
    final email = SupabaseService.client.auth.currentUser?.email;
    return email ?? '';
  }

  static String _avatarLetter() {
    if (!SupabaseService.isInitialized) return 'A';
    final user = SupabaseService.client.auth.currentUser;
    final metaName = user?.userMetadata?['name'];
    if (metaName is String && metaName.trim().isNotEmpty) {
      return metaName.trim()[0].toUpperCase();
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'A';
  }

  Future<void> _signOut(BuildContext context) async {
    if (SupabaseService.isInitialized) {
      await SupabaseService.client.auth.signOut();
    }
    if (context.mounted) context.go(AppRoutes.launch);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyles.heading3.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1,
      color: AppColors.textPrimary,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                10,
                AppSpacing.screenH,
                12,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.chevron_left,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text('Account', style: titleStyle),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.xs,
                  AppSpacing.screenH,
                  AppSpacing.screenBot,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _avatarLetter(),
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w500,
                                height: 1,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            _displayName(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading2.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            _email().isEmpty ? '—' : _email(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 0.5, color: AppColors.surface),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Subscription',
                      style: AppTextStyles.captionMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Annual',
                                style: AppTextStyles.heading3.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cta,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'Trial',
                                  style: AppTextStyles.micro.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                    color: AppColors.background,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Free trial — subscribe to keep journaling',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Then \$7.99 / month or \$44.99 / year',
                            style: AppTextStyles.micro.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Container(height: 0.5, color: AppColors.surfaceRaised),
                          SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: AppColors.error,
                              ),
                              child: Text(
                                'Cancel trial',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Center(
                      child: TextButton(
                        onPressed: () => _signOut(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textTertiary,
                        ),
                        child: Text(
                          'Sign out',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
