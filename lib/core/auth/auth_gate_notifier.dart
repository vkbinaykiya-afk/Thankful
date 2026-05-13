import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Drives [GoRouter] refresh from Supabase auth + `users` row presence.
class AuthGateNotifier extends ChangeNotifier {
  StreamSubscription<AuthState>? _authSub;

  /// True until the first [Supabase.auth.onAuthStateChange] event (avoids routing
  /// before persisted session is applied on cold start).
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  /// `null` while checking `users` for the signed-in user; `true`/`false` once known.
  bool? _hasUsersRow;

  bool? get hasUsersRow => _hasUsersRow;

  /// Signed in but `users` lookup not finished yet.
  bool get isProfileLoading {
    if (!Supabase.instance.isInitialized) return false;
    final session = Supabase.instance.client.auth.currentSession;
    return session != null && _hasUsersRow == null;
  }

  void start() {
    if (!Supabase.instance.isInitialized) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final client = Supabase.instance.client;

    _authSub = client.auth.onAuthStateChange.listen((AuthState state) {
      if (_isLoading) {
        _isLoading = false;
      }

      final session = state.session;
      if (session == null) {
        _hasUsersRow = null;
        notifyListeners();
        return;
      }
      _hasUsersRow = null;
      notifyListeners();
      unawaited(_fetchUsersRow(session.user.id));
    });

    notifyListeners();
  }

  Future<void> _fetchUsersRow(String userId) async {
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      _hasUsersRow = row != null;
    } catch (_) {
      _hasUsersRow = false;
    }
    notifyListeners();
  }

  /// Call after a `users` row is created mid-session (e.g. end of onboarding) so the
  /// auth gate can route to [AppRoutes.home].
  void refreshProfileFromServer() {
    if (!Supabase.instance.isInitialized) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _hasUsersRow = null;
    notifyListeners();
    unawaited(_fetchUsersRow(user.id));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
