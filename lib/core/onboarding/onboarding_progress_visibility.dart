import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether onboarding dot progress should show on convo / entry review / paywall.
abstract final class OnboardingProgressVisibility {
  static bool isOnboardingCompleteValue(dynamic value) {
    if (value == true) return true;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == 't' || v == '1';
    }
    if (value is num) return value == 1;
    return false;
  }

  /// `true` when the user has not finished onboarding (first-time journey).
  static Future<bool> shouldShowProgressStrip() async {
    if (!SupabaseService.isInitialized) return false;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    try {
      final row = Map<String, dynamic>.from(
        await Supabase.instance.client
            .from('users')
            .select('onboarding_complete')
            .eq('id', user.id)
            .single() as Map,
      );
      return !isOnboardingCompleteValue(row['onboarding_complete']);
    } catch (_) {
      // No profile row yet — still in first-time onboarding.
      return true;
    }
  }

  /// Marks onboarding finished in Supabase (independent of subscription / purchase).
  static Future<void> markOnboardingComplete() async {
    if (!SupabaseService.isInitialized) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('users')
          .update({'onboarding_complete': true})
          .eq('id', user.id);
      print('[Onboarding] onboarding_complete set for ${user.id}');
    } catch (e) {
      print('[Onboarding] markOnboardingComplete failed: $e');
    }
  }
}
