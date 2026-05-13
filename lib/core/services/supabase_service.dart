import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  /// `true` after [Supabase.initialize] in [main] succeeds (see `lib/main.dart`).
  static bool get isInitialized => Supabase.instance.isInitialized;

  /// Prefer checking [isInitialized] first when Supabase may be absent (no `.env`).
  static SupabaseClient get client => Supabase.instance.client;
}
