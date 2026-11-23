import 'package:fanikisha/app.dart';
import 'package:fanikisha/core/api/api_client.dart';
import 'package:fanikisha/core/api/token_storage.dart';
import 'package:fanikisha/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api.dart';

/// Starts the whole app against [api], signed in when [tokens] is given.
/// Pass the [storage] a previous launch returned to keep its session.
Future<MemoryTokenStorage> pumpApp(
  WidgetTester tester,
  FakeApi api, {
  TokenPair? tokens,
  String locale = 'en',
  MemoryTokenStorage? storage,
  bool keepPreferences = false,
}) async {
  await initializeDateFormatting();
  // keepPreferences: a second launch, finding what the first one saved.
  if (!keepPreferences) {
    SharedPreferences.setMockInitialValues({'locale': locale});
  }
  final preferences = await SharedPreferences.getInstance();
  final tokenStorage = storage ?? MemoryTokenStorage();
  if (tokens != null) await tokenStorage.save(tokens);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        tokenStorageProvider.overrideWithValue(tokenStorage),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            baseUrl: 'http://fanikisha.test',
            tokens: tokenStorage,
            cache: ref.watch(offlineCacheProvider),
            adapter: api,
          ),
        ),
      ],
      child: const FanikishaApp(),
    ),
  );
  await tester.pumpAndSettle();
  return tokenStorage;
}
