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
Future<MemoryTokenStorage> pumpApp(
  WidgetTester tester,
  FakeApi api, {
  TokenPair? tokens,
  String locale = 'en',
}) async {
  await initializeDateFormatting();
  SharedPreferences.setMockInitialValues({'locale': locale});
  final preferences = await SharedPreferences.getInstance();
  final storage = MemoryTokenStorage();
  if (tokens != null) await storage.save(tokens);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        tokenStorageProvider.overrideWithValue(storage),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            baseUrl: 'http://fanikisha.test',
            tokens: storage,
            adapter: api,
          ),
        ),
      ],
      child: const FanikishaApp(),
    ),
  );
  await tester.pumpAndSettle();
  return storage;
}
