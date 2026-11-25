import 'package:fanikisha/core/api/api_client.dart';
import 'package:fanikisha/core/api/api_exception.dart';
import 'package:fanikisha/core/api/offline_cache.dart';
import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  late FakeApi api;
  late OfflineCache cache;
  late ApiClient client;
  late List<DateTime?> offlineEvents;
  var online = true;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = OfflineCache(await SharedPreferences.getInstance());
    online = true;
    api = FakeApi()
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => online
            ? FakeResponse(200, summaryJson(total: 7000))
            : const FakeResponse.offline(),
      );
    final tokens = MemoryTokenStorage();
    await tokens.save(const TokenPair(accessToken: 'a', refreshToken: 'r'));
    client = ApiClient(
      baseUrl: 'http://fanikisha.test',
      tokens: tokens,
      cache: cache,
      adapter: api,
    );
    offlineEvents = [];
    client.offline.listen(offlineEvents.add);
  });

  tearDown(() => client.dispose());

  test('answers from the cache when offline, and says how old it is', () async {
    await client.getMap('/v1/savings/summary', cacheKey: 'summary');
    online = false;

    final saved = await client.getMap(
      '/v1/savings/summary',
      cacheKey: 'summary',
    );

    expect(saved['totalDeposited'], 7000);
    await Future<void>.delayed(Duration.zero);
    expect(offlineEvents, [null, isA<DateTime>()]);
  });

  test('still fails offline when nothing was saved', () async {
    online = false;
    await expectLater(
      client.getMap('/v1/savings/summary', cacheKey: 'summary'),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.network),
      ),
    );
  });

  test('never hides a server error behind saved data', () async {
    await client.getMap('/v1/savings/summary', cacheKey: 'summary');
    api.on(
      'GET',
      '/v1/savings/summary',
      (_) => const FakeResponse(500, {'message': 'boom'}),
    );
    await expectLater(
      client.getMap('/v1/savings/summary', cacheKey: 'summary'),
      throwsA(isA<ApiException>()),
    );
  });

  test('keeps one account at a time', () async {
    await cache.claimFor('user-1');
    await cache.put('summary', {'x': 1});
    await cache.claimFor('user-1');
    expect(cache.get('summary'), isNotNull);

    await cache.claimFor('user-2');
    expect(cache.get('summary'), isNull);
  });
}
