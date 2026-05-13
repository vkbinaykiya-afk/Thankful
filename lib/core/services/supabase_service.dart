import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  /// Set in [main] right after [Supabase.initialize] completes successfully.
  /// Keeps auth/OAuth checks accurate even if reading the SDK flag alone is flaky.
  static bool _readyAfterInit = false;

  static void markInitialized() {
    _readyAfterInit = true;
  }

  /// `true` after [markInitialized] or when the SDK reports initialized.
  ///
  /// Uses try/catch around [Supabase.instance] for callers that run before init in
  /// edge builds (avoids failed asserts breaking taps).
  static bool get isInitialized {
    if (_readyAfterInit) return true;
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
