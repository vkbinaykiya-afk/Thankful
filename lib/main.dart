import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/services/supabase_service.dart';

String? _trimEnv(String? raw) {
  if (raw == null) return null;
  var v = raw.trim();
  if (v.length >= 2) {
    final q = v[0];
    if ((q == '"' || q == "'") && v.endsWith(q)) {
      v = v.substring(1, v.length - 1).trim();
    }
  }
  return v.isEmpty ? null : v;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('dotenv.load(.env) failed: $e\n$st');
    }
  }

  final googleWebClientId = dotenv.isInitialized
      ? _trimEnv(dotenv.env['GOOGLE_WEB_CLIENT_ID'])
      : null;
  await GoogleSignIn.instance.initialize(
    serverClientId: googleWebClientId != null && googleWebClientId.isNotEmpty
        ? googleWebClientId
        : null,
  );

  const defineUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const defineKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  final urlDot = dotenv.isInitialized
      ? _trimEnv(dotenv.env['SUPABASE_URL'])
      : null;
  final keyDot = dotenv.isInitialized
      ? _trimEnv(dotenv.env['SUPABASE_ANON_KEY'])
      : null;

  final url =
      (urlDot != null && urlDot.isNotEmpty) ? urlDot : defineUrl.trim();
  final anonKey =
      (keyDot != null && keyDot.isNotEmpty) ? keyDot : defineKey.trim();

  if (url.isNotEmpty && anonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, anonKey: anonKey);
      SupabaseService.markInitialized();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Supabase.initialize failed: $e\n$st');
      }
    }
  } else if (kDebugMode) {
    debugPrint(
      'Supabase skipped: SUPABASE_URL / SUPABASE_ANON_KEY missing in .env '
      'and not passed as --dart-define. Keys loaded: '
      '${dotenv.isInitialized ? dotenv.env.length : 0}',
    );
  }

  runApp(const ThankfulApp());
}
