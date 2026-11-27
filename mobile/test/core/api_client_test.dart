import 'dart:async';

import 'package:fanikisha/core/api/api_client.dart';
import 'package:fanikisha/core/api/api_exception.dart';
import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

void main() {
  late FakeApi api;
  late MemoryTokenStorage storage;
  late ApiClient client;

  setUp(() async {
    api = FakeApi();
    storage = MemoryTokenStorage();
    await storage.save(
      const TokenPair(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );
    client = ApiClient(
      baseUrl: 'http://fanikisha.test',
      tokens: storage,
      adapter: api,
    );
  });

  tearDown(() => client.dispose());

  /// /v1/me accepts only the token named [valid].
  void meAccepts(String valid) => api.on('GET', '/v1/me', (r) {
    final ok = r.headers['Authorization'] == 'Bearer $valid';
    return ok
        ? FakeResponse(200, userJson())
        : const FakeResponse(401, {'message': 'Unauthorized'});
  });

  test('sends the access token', () async {
    meAccepts('old-access');
    await client.getMap('/v1/me');
    expect(api.requests.single.headers['Authorization'], 'Bearer old-access');
  });

  test('refreshes an expired access token and retries the request', () async {
    meAccepts('access-2');
    api.on('POST', '/v1/auth/refresh', (r) {
      expect(r.data, {'refreshToken': 'old-refresh'});
      return FakeResponse(200, tokensJson('2'));
    });

    final user = await client.getMap('/v1/me');

    expect(user['id'], 'user-1');
    expect(api.requestsTo('GET', '/v1/me'), hasLength(2));
    expect((await storage.read())!.refreshToken, 'refresh-2');
  });

  test('refreshes once for requests that fail at the same time', () async {
    meAccepts('access-2');
    final refreshGate = Completer<void>();
    api.on('POST', '/v1/auth/refresh', (_) async {
      await refreshGate.future;
      return FakeResponse(200, tokensJson('2'));
    });

    final calls = Future.wait([
      client.getMap('/v1/me'),
      client.getMap('/v1/me'),
      client.getMap('/v1/me'),
    ]);
    await Future<void>.delayed(Duration.zero);
    refreshGate.complete();
    await calls;

    expect(api.requestsTo('POST', '/v1/auth/refresh'), hasLength(1));
  });

  test('ends the session when the refresh token is refused', () async {
    meAccepts('never');
    api.on(
      'POST',
      '/v1/auth/refresh',
      (_) => const FakeResponse(401, {'message': 'reused'}),
    );
    var expired = false;
    client.sessionExpired.listen((_) => expired = true);

    await expectLater(
      client.getMap('/v1/me'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiErrorKind.sessionExpired,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(expired, isTrue);
    expect(await storage.read(), isNull);
  });

  test(
    'keeps the session when the refresh fails for lack of network',
    () async {
      meAccepts('never');
      api.on('POST', '/v1/auth/refresh', (_) => const FakeResponse.offline());

      await expectLater(
        client.getMap('/v1/me'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.network,
          ),
        ),
      );
      expect(await storage.read(), isNotNull);
    },
  );

  test('reads validation messages from the response', () async {
    api.on(
      'POST',
      '/v1/goals',
      (_) => const FakeResponse(400, {
        'message': ['name: Too small', 'targetAmount: Too small'],
        'statusCode': 400,
      }),
    );

    try {
      await client.postMap('/v1/goals', body: {});
      fail('expected an ApiException');
    } on ApiException catch (error) {
      expect(error.kind, ApiErrorKind.rejected);
      expect(error.messageFor('name'), 'Too small');
      expect(error.messages, hasLength(2));
    }
  });

  test('keeps the reason code of a server error, not its message', () async {
    api.on(
      'POST',
      '/v1/me/phone/verification',
      (_) => const FakeResponse(503, {
        'statusCode': 503,
        'message': 'We could not send the SMS. Please try again later',
        'code': 'sms_failed',
      }),
    );

    try {
      await client.postMap('/v1/me/phone/verification', body: {});
      fail('expected an ApiException');
    } on ApiException catch (error) {
      expect(error.kind, ApiErrorKind.server);
      expect(error.statusCode, 503);
      expect(error.errorCode, 'sms_failed');
      expect(error.messages, isEmpty);
    }
  });
}
