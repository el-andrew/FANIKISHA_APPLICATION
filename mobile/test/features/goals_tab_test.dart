import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeApi api;

  setUp(() {
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (r) {
        return FakeResponse(200, switch (r.uri.queryParameters['status']) {
          'ACTIVE' => [goalJson(id: 'fridge', name: 'New fridge')],
          'COMPLETED' => [
            goalJson(
              id: 'oven',
              name: 'Oven',
              saved: 400000,
              target: 400000,
              status: 'COMPLETED',
            ),
          ],
          _ => <Object>[],
        });
      });
  });

  Future<void> openGoals(WidgetTester tester) async {
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
    );
    await tester.tap(find.text('Goals').last);
    await tester.pumpAndSettle();
  }

  testWidgets('lists goals by status', (tester) async {
    await openGoals(tester);
    expect(find.text('New fridge'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Oven'), findsOneWidget);
    // The badge on its row.
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('Oven'), matching: find.byType(Row)),
        matching: find.text('Completed'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('No archived goals.'), findsOneWidget);
  });

  testWidgets('New goal opens the form', (tester) async {
    await openGoals(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'New goal'));
    await tester.pumpAndSettle();
    expect(find.text('What are you saving for?'), findsOneWidget);
  });
}
