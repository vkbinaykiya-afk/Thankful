import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> signInWithApple() async {
    // TODO: wire to Supabase + sign_in_with_apple
    _setLoading(true);
    _setLoading(false);
  }

  /// Native Google Sign-In (iOS client from `GoogleService-Info.plist`) → Supabase
  /// via ID token. [GoogleSignIn.initialize] in `main.dart` supplies only
  /// [serverClientId] = web client for token audience — no client ID is passed here.
  Future<bool> signInWithGoogle() async {
    _error = null;
    if (!SupabaseService.isInitialized) {
      _error = 'Supabase is not configured.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final GoogleSignInAccount user =
          await GoogleSignIn.instance.authenticate();
      final String? idToken = user.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        _error =
            'Missing Google ID token. Ensure GOOGLE_WEB_CLIENT_ID is set in .env '
            'for serverClientId and GoogleService-Info.plist is in the iOS app.';
        return false;
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return false;
      }
      _error = e.description ?? e.toString();
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    if (!SupabaseService.isInitialized) return;
    await Supabase.instance.client.auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
