import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('saving the profile returns to it with the new details', (
    tester,
  ) async {
    var businessName = 'Asha Duka';
    final api = FakeApi()
      ..on(
        'GET',
        '/v1/me',
        (_) => FakeResponse(200, userJson(businessName: businessName)),
      )
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]))
      ..on('PATCH', '/v1/me', (r) {
        businessName =
            (r.data as Map<String, Object?>)['businessName']! as String;
        return FakeResponse(200, userJson(businessName: businessName));
      });
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
    );

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Business name (optional)'),
      'Asha Wholesale',
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Save profile'), findsNothing);
    expect(find.text('Asha Wholesale'), findsOneWidget);
    expect(find.text('Profile updated'), findsOneWidget);
  });
}
