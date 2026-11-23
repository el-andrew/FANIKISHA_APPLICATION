import '../../../core/api/api_client.dart';
import '../../../core/api/token_storage.dart';
import 'user.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? businessName,
  }) => _signIn('/v1/auth/register', {
    'email': email,
    'password': password,
    'fullName': fullName,
    'phone': ?phone,
    'businessName': ?businessName,
  });

  Future<User> login({required String email, required String password}) =>
      _signIn('/v1/auth/login', {'email': email, 'password': password});

  /// Revokes the refresh token on the server (best effort) and forgets it.
  Future<void> logout() async {
    final tokens = await _tokens.read();
    await _tokens.clear();
    if (tokens == null) return;
    try {
      await _api.postVoid(
        '/v1/auth/logout',
        body: {'refreshToken': tokens.refreshToken},
        authenticated: false,
      );
    } catch (_) {
      // Signed out locally either way; the token expires on its own.
    }
  }

  Future<bool> hasSession() async => await _tokens.read() != null;

  Future<User> currentUser() async =>
      User.fromJson(await _api.getMap('/v1/me'));

  /// Saves the whole profile. A null business name or phone clears it.
  Future<User> updateProfile({
    required String fullName,
    required String? businessName,
    required String? phone,
  }) async => User.fromJson(
    await _api.patchMap(
      '/v1/me',
      body: {
        'fullName': fullName,
        'businessName': businessName,
        'phone': phone,
      },
    ),
  );

  /// The server signs out every device after a password change, so this
  /// device signs straight back in with the new password.
  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.postVoid(
      '/v1/me/password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    await login(email: email, password: newPassword);
  }

  Future<User> _signIn(String path, Map<String, Object?> body) async {
    final json = await _api.postMap(path, body: body, authenticated: false);
    await _tokens.save(TokenPair.fromJson(json));
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }
}
