import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeApi api;
  var saved = 300000;

  Map<String, Object?> split(int amount) => {
    'amount': amount,
    'unallocatedAmount': 0,
    'allocations': [
      {'goalId': 'goal-1', 'goalName': 'New fridge', 'amount': amount},
    ],
  };

  setUp(() {
    saved = 300000;
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson(total: saved)),
      )
      ..on(
        'GET',
        '/v1/goals',
        (_) => FakeResponse(200, [goalJson(saved: saved)]),
      )
      ..on('POST', '/v1/savings/deposits/preview', (r) {
        final amount = (r.data as Map<String, Object?>)['amount']! as int;
        return FakeResponse(200, split(amount));
      });
  });

  Future<void> openDepositScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
    );
    // Home's "Save" action.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('previews the split, saves, and refreshes the dashboard', (
    tester,
  ) async {
    api.on('POST', '/v1/savings/deposits', (r) {
      final amount = (r.data as Map<String, Object?>)['amount']! as int;
      saved += amount;
      return FakeResponse(201, {
        ...split(amount),
        'id': 'deposit-1',
        'note': null,
        'createdAt': '2026-11-19T08:00:00.000Z',
      });
    });
    await openDepositScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, '50000');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '50,000'), findsOneWidget);
    expect(find.text('TZS 50,000'), findsOneWidget); // the preview row

    await tester.tap(find.text('Save TZS 50,000'));
    await tester.pumpAndSettle();
    expect(find.text('Saved!'), findsOneWidget);
    expect(
      api
          .requestsTo('POST', '/v1/savings/deposits')
          .single
          .headers['Idempotency-Key'],
      isNotEmpty,
    );

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Asha'), findsOneWidget);
    expect(find.text('TZS 350,000'), findsWidgets);
  });

  testWidgets('a quick amount fills in the amount and the split', (
    tester,
  ) async {
    await openDepositScreen(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, '20,000'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, '20,000'), findsOneWidget);
    expect(find.text('Save TZS 20,000'), findsOneWidget);
    expect(api.requestsTo('POST', '/v1/savings/deposits/preview').last.data, {
      'amount': 20000,
    });
  });

  testWidgets('a retry after a lost connection reuses the idempotency key', (
    tester,
  ) async {
    var attempts = 0;
    api.on('POST', '/v1/savings/deposits', (_) {
      attempts++;
      return attempts == 1
          ? const FakeResponse.offline()
          : FakeResponse(201, {
              ...split(20000),
              'id': 'deposit-1',
              'note': null,
              'createdAt': '2026-11-19T08:00:00.000Z',
            });
    });
    await openDepositScreen(tester);

    await tester.enterText(find.byType(TextFormField).first, '20000');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.text('Save TZS 20,000'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Can't reach Fanikisha"), findsOneWidget);

    await tester.tap(find.text('Save TZS 20,000'));
    await tester.pumpAndSettle();
    expect(find.text('Saved!'), findsOneWidget);

    final keys = api
        .requestsTo('POST', '/v1/savings/deposits')
        .map((r) => r.headers['Idempotency-Key'])
        .toList();
    expect(keys, hasLength(2));
    expect(keys[0], keys[1]);
  });

  testWidgets('rejects an empty amount without calling the API', (
    tester,
  ) async {
    await openDepositScreen(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save money'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
    expect(api.requestsTo('POST', '/v1/savings/deposits'), isEmpty);
  });
}
