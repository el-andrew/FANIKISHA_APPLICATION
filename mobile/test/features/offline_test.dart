import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeApi api;
  late bool online;

  FakeResponse whenOnline(FakeResponse response) =>
      online ? response : const FakeResponse.offline();

  setUp(() {
    online = true;
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => whenOnline(FakeResponse(200, userJson())))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => whenOnline(FakeResponse(200, summaryJson(total: 300000))),
      )
      ..on(
        'GET',
        '/v1/goals',
        (_) => whenOnline(FakeResponse(200, [goalJson()])),
      )
      ..on(
        'GET',
        '/v1/savings/activity',
        (_) => whenOnline(
          const FakeResponse(200, {'items': [], 'nextCursor': null}),
        ),
      )
      ..on(
        'POST',
        '/v1/auth/logout',
        (_) => whenOnline(const FakeResponse(204)),
      );
  });

  testWidgets('opens offline with the data saved last time', (tester) async {
    // First launch, online: the dashboard loads and is saved.
    final storage = await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
    );
    expect(find.text('TZS 300,000'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);

    // Second launch, offline.
    online = false;
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, api, storage: storage, keepPreferences: true);

    expect(find.text('Hello, Asha'), findsOneWidget);
    expect(find.text('TZS 300,000'), findsOneWidget);
    expect(find.text('New fridge'), findsOneWidget);
    expect(find.textContaining("You're offline"), findsOneWidget);

    // Back online: "Try again" reloads and the banner goes.
    online = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsNothing);
  });

  testWidgets('logging out removes the saved data', (tester) async {
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('cache:')), isNotEmpty);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    final logOut = find.text('Log out');
    await tester.scrollUntilVisible(
      logOut,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(logOut);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(prefs.getKeys().where((k) => k.startsWith('cache:')), isEmpty);
    expect(find.text('Save for what your business needs next'), findsOneWidget);
  });
}
