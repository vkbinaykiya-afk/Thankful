import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> signInWithApple() async {
    _setLoading(true);
    try {
      await SupabaseService.client.auth.signInWithOAuth(OAuthProvider.apple);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await SupabaseService.client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
