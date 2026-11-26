import 'package:fanikisha/core/api/token_storage.dart';
import 'package:fanikisha/features/reminders/reminders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

Map<String, Object?> deposit(String id, int amount, DateTime at) => {
  'kind': 'DEPOSIT',
  'id': id,
  'amount': amount,
  'unallocatedAmount': 0,
  'allocations': [
    {'goalId': 'goal-1', 'goalName': 'New fridge', 'amount': amount},
  ],
  'note': null,
  'createdAt': at.toUtc().toIso8601String(),
};

void main() {
  late FakeApi api;
  final now = DateTime(2026, 11, 26, 15);

  setUp(() {
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]))
      ..on(
        'GET',
        '/v1/savings/activity',
        (_) => FakeResponse(200, {
          'items': [
            deposit('d3', 7000, DateTime(2026, 11, 26, 9)),
            deposit('d2', 6000, DateTime(2026, 11, 25, 18)),
            deposit('d1', 5000, DateTime(2026, 11, 20, 8)),
          ],
          'nextCursor': null,
        }),
      );
  });

  Future<void> openHistory(WidgetTester tester) async {
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    await tester.ensureVisible(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
  }

  testWidgets('groups activity by day', (tester) async {
    await openHistory(tester);

    final headers = [
      'Today',
      'Yesterday',
      '20 Nov 2026',
    ].map((t) => tester.getTopLeft(find.text(t)).dy).toList();
    // In that order, newest first, each above its own items.
    expect(headers, orderedEquals([...headers]..sort()));
    expect(
      tester.getTopLeft(find.text('+ TZS 6,000')).dy,
      inExclusiveRange(headers[1], headers[2]),
    );
  });

  testWidgets('a deposit opens how it was shared', (tester) async {
    await openHistory(tester);

    await tester.tap(find.text('+ TZS 7,000'));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('New fridge')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('TZS 7,000')),
      findsOneWidget,
    );
  });
}
