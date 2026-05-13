import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Web client ID only: Supabase verifies the ID token. Native iOS sign-in uses
  // CLIENT_ID from GoogleService-Info.plist (bundled) — do not pass clientId here.
  final googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
  await GoogleSignIn.instance.initialize(
    serverClientId: googleWebClientId != null && googleWebClientId.isNotEmpty
        ? googleWebClientId
        : null,
  );

  final url = dotenv.env['SUPABASE_URL']?.trim();
  final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
  if (url != null &&
      anonKey != null &&
      url.isNotEmpty &&
      anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  runApp(const ThankfulApp());
}
