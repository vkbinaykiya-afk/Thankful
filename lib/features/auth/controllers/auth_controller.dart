import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> signInWithApple() async {
    _error = null;
    if (!SupabaseService.isInitialized) {
      _error = 'Supabase is not configured.';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      print('[AppleSignIn] Requesting Apple ID credential...');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      print('[AppleSignIn] Got credential, extracting identity token...');
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        _error = 'Apple Sign In failed: missing identity token.';
        return false;
      }
      print('[AppleSignIn] Signing in with Supabase...');
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
      print('[AppleSignIn] Success');
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        print('[AppleSignIn] Cancelled by user');
        return false;
      }
      _error = e.message;
      print('[AppleSignIn] Authorization error: ${e.message}');
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      print('[AppleSignIn] Supabase auth error: ${e.message}');
      return false;
    } catch (e) {
      _error = e.toString();
      print('[AppleSignIn] Unexpected error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Native Google Sign-In (iOS client from `GoogleService-Info.plist`) → Supabase
  /// via ID token. [GoogleSignIn.initialize] in `main.dart` supplies only
  /// [serverClientId] = web client for token audience — no client ID is passed here.
  Future<bool> signInWithGoogle() async {
    _error = null;
    if (!SupabaseService.isInitialized) {
      _error =
          'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY '
          'to .env (see pubspec assets), or run with '
          '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=..., '
          'then fully restart the app.';
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
    try {
      await Purchases.logOut();
      print('[RevenueCat] Logged out');
    } catch (e) {
      print('[RevenueCat] LogOut error: $e');
    }
    await Supabase.instance.client.auth.signOut();
    await GoogleSignIn.instance.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
