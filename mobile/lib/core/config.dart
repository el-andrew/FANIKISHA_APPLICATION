/// Build-time configuration, set with `--dart-define`.
abstract final class AppConfig {
  /// Where the Fanikisha API runs.
  ///
  /// The default reaches a development server on the host machine from the
  /// Android emulator. Pass `--dart-define=API_BASE_URL=https://…` for other
  /// targets; release builds must use HTTPS.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}

/// Why this build must not start, or null. A release build talking to the
/// API over plain HTTP would send passwords and tokens unencrypted.
String? releaseConfigProblem({
  required bool isRelease,
  required String apiBaseUrl,
}) => isRelease && !apiBaseUrl.startsWith('https://')
    ? 'Release builds need an HTTPS API_BASE_URL '
          '(--dart-define=API_BASE_URL=https://...), got $apiBaseUrl'
    : null;
