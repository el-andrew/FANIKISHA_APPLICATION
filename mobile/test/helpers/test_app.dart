import 'package:fanikisha/app.dart';
import 'package:fanikisha/core/api/api_client.dart';
import 'package:fanikisha/core/api/token_storage.dart';
import 'package:fanikisha/core/legal_links.dart';
import 'package:fanikisha/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api.dart';

/// URLs the app asked to open in the browser, in order.
final openedUrls = <Uri>[];

/// Starts the whole app against [api], signed in when [tokens] is given.
/// Pass the [storage] a previous launch returned to keep its session.
Future<MemoryTokenStorage> pumpApp(
  WidgetTester tester,
  FakeApi api, {
  TokenPair? tokens,
  String locale = 'en',
  MemoryTokenStorage? storage,
  bool keepPreferences = false,
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  await initializeDateFormatting();
  // keepPreferences: a second launch, finding what the first one saved.
  if (!keepPreferences) {
    SharedPreferences.setMockInitialValues({'locale': locale});
  }
  final preferences = await SharedPreferences.getInstance();
  openedUrls.clear();
  final tokenStorage = storage ?? MemoryTokenStorage();
  if (tokens != null) await tokenStorage.save(tokens);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        tokenStorageProvider.overrideWithValue(tokenStorage),
        urlOpenerProvider.overrideWithValue((uri) async {
          openedUrls.add(uri);
          return true;
        }),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            baseUrl: 'http://fanikisha.test',
            tokens: tokenStorage,
            cache: ref.watch(offlineCacheProvider),
            adapter: api,
          ),
        ),
        ...overrides,
      ],
      child: const FanikishaApp(),
    ),
  );
  // Not settling lets a test watch the app while a request is still open.
  if (settle) await tester.pumpAndSettle();
  return tokenStorage;
}
