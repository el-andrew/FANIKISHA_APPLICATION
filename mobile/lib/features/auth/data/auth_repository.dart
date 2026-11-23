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
  /// Deletes the account and all its data on the server, then forgets the
  /// tokens. Cannot be undone.
  Future<void> deleteAccount({required String password}) async {
    await _api.deleteVoid('/v1/me', body: {'password': password});
    await _tokens.clear();
  }

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
      User.fromJson(await _api.getMap('/v1/me', cacheKey: 'me'));

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

  /// Asks for a password-reset code by SMS. The API answers the same way
  /// whether or not the account exists.
  Future<void> requestPasswordReset({
    required String email,
    required String language,
  }) => _api.postVoid(
    '/v1/auth/password-reset',
    body: {'email': email, 'language': language},
    authenticated: false,
  );

  /// Sets a new password with the texted code, and signs in.
  Future<User> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _signIn('/v1/auth/password-reset/confirm', {
    'email': email,
    'code': code,
    'newPassword': newPassword,
  });

  /// Texts a verification code to the user's phone, in [language].
  Future<PhoneCodeSent> sendPhoneCode({required String language}) async =>
      PhoneCodeSent.fromJson(
        await _api.postMap(
          '/v1/me/phone/verification',
          body: {'language': language},
        ),
      );

  /// Checks the code; returns the user with the phone marked verified.
  Future<User> confirmPhoneCode(String code) async => User.fromJson(
    await _api.postMap(
      '/v1/me/phone/verification/confirm',
      body: {'code': code},
    ),
  );

  Future<User> _signIn(String path, Map<String, Object?> body) async {
    final json = await _api.postMap(path, body: body, authenticated: false);
    await _tokens.save(TokenPair.fromJson(json));
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }
}

class PhoneCodeSent {
  const PhoneCodeSent({
    required this.phone,
    required this.expiresAt,
    required this.resendAvailableAt,
  });

  factory PhoneCodeSent.fromJson(Map<String, dynamic> json) => PhoneCodeSent(
    phone: json['phone'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    resendAvailableAt: DateTime.parse(json['resendAvailableAt'] as String),
  );

  final String phone;
  final DateTime expiresAt;

  /// When a new code may be requested.
  final DateTime resendAvailableAt;
}
