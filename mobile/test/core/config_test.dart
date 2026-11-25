import 'package:fanikisha/core/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release builds refuse a plain-HTTP API', () {
    expect(
      releaseConfigProblem(isRelease: true, apiBaseUrl: 'http://10.0.2.2:3000'),
      contains('HTTPS'),
    );
    expect(
      releaseConfigProblem(
        isRelease: true,
        apiBaseUrl: 'https://api.fanikisha.app',
      ),
      isNull,
    );
  });

  test('release builds refuse plain-HTTP public pages', () {
    expect(
      releaseConfigProblem(
        isRelease: true,
        apiBaseUrl: 'https://api.fanikisha.northkings.co.tz',
        publicSiteUrl: 'http://fanikisha.northkings.co.tz',
      ),
      contains('PUBLIC_SITE_URL'),
    );
    expect(
      releaseConfigProblem(
        isRelease: true,
        apiBaseUrl: 'https://api.fanikisha.northkings.co.tz',
        publicSiteUrl: 'https://fanikisha.northkings.co.tz',
      ),
      isNull,
    );
  });

  test('debug builds may use a local HTTP API', () {
    expect(
      releaseConfigProblem(
        isRelease: false,
        apiBaseUrl: 'http://10.0.2.2:3000',
      ),
      isNull,
    );
  });
}
