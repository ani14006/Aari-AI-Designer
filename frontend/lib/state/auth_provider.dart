import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// Emits the raw Supabase auth user (null when signed out).
final supabaseUserProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.authStateChanges;
});

/// The backend-side user profile (created lazily on first authenticated call).
final currentUserProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final supabaseUser = ref.watch(supabaseUserProvider).value;
  if (supabaseUser == null) return null;
  return ApiService.instance.getMe();
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => AuthService.instance.signInWithEmail(email, password));
  }

  Future<void> signUpWithEmail(
      String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => AuthService.instance.signUpWithEmail(email, password, displayName),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => AuthService.instance.signInWithGoogle());
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => AuthService.instance.sendPasswordResetEmail(email));
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    _ref.invalidate(currentUserProvider);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});
