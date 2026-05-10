import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> signInWithApple() async {
    // TODO: wire to Supabase OAuth + sign_in_with_apple package
    _setLoading(true);
    _setLoading(false);
  }

  Future<void> signInWithGoogle() async {
    // TODO: wire to Supabase OAuth + google_sign_in package
    _setLoading(true);
    _setLoading(false);
  }

  Future<void> signOut() async {
    if (!SupabaseService.isInitialized) return;
    await SupabaseService.client.auth.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
