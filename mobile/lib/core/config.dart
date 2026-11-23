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
