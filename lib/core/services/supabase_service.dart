import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  /// `true` only after [initialize] runs [Supabase.initialize] successfully.
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL']?.trim();
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      return;
    }
    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
  }

  /// Prefer checking [isInitialized] first when Supabase may be absent (dev / no `.env`).
  static SupabaseClient get client => Supabase.instance.client;
}
