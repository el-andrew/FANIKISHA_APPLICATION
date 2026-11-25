import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('sign-up links to the terms and privacy policy', (tester) async {
    await pumpApp(tester, FakeApi());
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    final terms = find.widgetWithText(TextButton, 'Terms of service');
    await tester.scrollUntilVisible(
      terms,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'By creating an account, you accept the terms of service and the privacy policy.',
      ),
      findsOneWidget,
    );
    await tester.tap(terms);
    await tester.tap(find.widgetWithText(TextButton, 'Privacy policy'));
    await tester.pumpAndSettle();

    expect(openedUrls.map((u) => '${u.path}?${u.query}'), [
      '/terms?lang=en',
      '/privacy?lang=en',
    ]);
  });

  testWidgets('the profile opens the policy in the app language', (
    tester,
  ) async {
    final api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]));
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      locale: 'sw',
    );
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    final privacy = find.text('Sera ya faragha');
    await tester.scrollUntilVisible(
      privacy,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(privacy);
    await tester.pumpAndSettle();

    expect(openedUrls.single.path, '/privacy');
    expect(openedUrls.single.queryParameters, {'lang': 'sw'});
  });
}
