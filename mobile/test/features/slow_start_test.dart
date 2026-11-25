import 'dart:async';

import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('a slow start says the server is waking up', (tester) async {
    // The server answers only when the test says so, like a sleeping free
    // Render service.
    final me = Completer<FakeResponse>();
    final api = FakeApi()
      ..on('GET', '/v1/me', (_) => me.future)
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]));
    const hint = 'Starting up… this can take up to a minute.';

    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      settle: false,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(hint), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(hint), findsOneWidget);

    me.complete(FakeResponse(200, userJson()));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Asha'), findsOneWidget);
    expect(find.text(hint), findsNothing);

    // Requests ask for JSON, so a waking server doesn't answer with a
    // browser's loading page.
    expect(api.requests.first.headers['accept'], 'application/json');
  });
}
