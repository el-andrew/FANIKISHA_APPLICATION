import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../data/user.dart';

sealed class AuthState {
  const AuthState();
}

/// Still checking for a saved session.
class AuthLoading extends AuthState {
  const AuthLoading();
}

class SignedOut extends AuthState {
  const SignedOut({this.sessionExpired = false});

  /// True when the server ended the session, rather than the user logging out.
  final bool sessionExpired;
}

class SignedIn extends AuthState {
  const SignedIn(this.user);
  final User user;
}

/// A session exists but the account couldn't be loaded (e.g. offline).
class AuthRestoreFailed extends AuthState {
  const AuthRestoreFailed(this.error);
  final Object error;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final subscription = ref
        .watch(apiClientProvider)
        .sessionExpired
        .listen((_) => state = const SignedOut(sessionExpired: true));
    ref.onDispose(subscription.cancel);
    unawaited(Future.microtask(restore));
    return const AuthLoading();
  }

  Future<void> restore() async {
    final repository = ref.read(authRepositoryProvider);
    state = const AuthLoading();
    if (!await repository.hasSession()) {
      state = const SignedOut();
      return;
    }
    try {
      state = SignedIn(await repository.currentUser());
    } on ApiException catch (error) {
      state = error.kind == ApiErrorKind.sessionExpired
          ? const SignedOut(sessionExpired: true)
          : AuthRestoreFailed(error);
    } catch (error) {
      state = AuthRestoreFailed(error);
    }
  }

  Future<void> login({required String email, required String password}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    state = SignedIn(user);
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? businessName,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .register(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          businessName: businessName,
        );
    state = SignedIn(user);
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .resetPassword(email: email, code: code, newPassword: newPassword);
    state = SignedIn(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const SignedOut();
  }

  /// After the profile was edited.
  void updateUser(User user) => state = SignedIn(user);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// The signed-in user's id. Data providers watch it, so nothing cached for
/// one account is ever shown to the next.
final currentUserIdProvider = Provider<String?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is SignedIn ? state.user.id : null;
});
