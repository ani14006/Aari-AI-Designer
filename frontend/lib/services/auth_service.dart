import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Authentication — the backend trusts the access token this issues.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  /// Emits on every sign-in/sign-out/token-refresh event.
  Stream<User?> get authStateChanges =>
      _auth.onAuthStateChange.map((state) => state.session?.user);
  User? get currentUser => _auth.currentUser;

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(
      String email, String password, String displayName) {
    return _auth.signUp(
      email: email,
      password: password,
      data: displayName.isNotEmpty ? {'full_name': displayName} : null,
    );
  }

  Future<bool> signInWithGoogle() {
    return _auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
