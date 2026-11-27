import 'package:fanikisha/core/api/token_storage.dart';
import 'package:fanikisha/features/reminders/reminders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeApi api;

  // Goals run 1 Nov to 1 Mar (120 days); on 26 Nov an even pace has saved
  // 25/120 of the target: 250,000 of 1,200,000.
  final clock = clockProvider.overrideWithValue(
    () => DateTime(2026, 11, 26, 10),
  );

  setUp(() {
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson(total: 370000, general: 20000)),
      )
      ..on('GET', '/v1/goals', (r) {
        final status = r.uri.queryParameters['status'];
        return FakeResponse(200, [
          if (status == 'ACTIVE') ...[
            goalJson(id: 'fridge', name: 'New fridge', saved: 300000),
            goalJson(id: 'van', name: 'Van', saved: 50000),
          ],
        ]);
      })
      ..on(
        'GET',
        '/v1/goals/van',
        (_) =>
            FakeResponse(200, goalJson(id: 'van', name: 'Van', saved: 50000)),
      )
      ..on(
        'GET',
        '/v1/savings/activity',
        (_) => const FakeResponse(200, {
          'items': [
            {
              'kind': 'DEPOSIT',
              'id': 'd1',
              'amount': 5000,
              'unallocatedAmount': 0,
              'allocations': [
                {'goalId': 'van', 'goalName': 'Van', 'amount': 5000},
              ],
              'note': null,
              'createdAt': '2026-11-26T05:14:00.000Z',
            },
          ],
          'nextCursor': null,
        }),
      );
  });

  Future<void> openHome(WidgetTester tester, {bool keep = false}) async {
    if (!keep) SharedPreferences.setMockInitialValues({'locale': 'en'});
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      keepPreferences: true,
      overrides: [clock],
    );
  }

  testWidgets('says which goals are on track and which are behind', (
    tester,
  ) async {
    await openHome(tester);

    Finder rowOf(String name) =>
        find.ancestor(of: find.text(name), matching: find.byType(InkWell));
    // 300,000 is ahead of the 250,000 an even pace needs; 50,000 isn't.
    expect(
      find.descendant(of: rowOf('New fridge'), matching: find.text('On track')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rowOf('Van'), matching: find.text('Behind')),
      findsOneWidget,
    );
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('hides the balance, and remembers it', (tester) async {
    await openHome(tester);
    expect(find.text('TZS 370,000'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide balance'));
    await tester.pumpAndSettle();
    expect(find.text('TZS 370,000'), findsNothing);
    expect(find.text('TZS ••••••'), findsOneWidget);
    // General savings would give it away too.
    expect(find.textContaining('General savings'), findsNothing);

    // Opened again later: still hidden.
    await tester.pumpWidget(const SizedBox());
    await openHome(tester, keep: true);
    expect(find.text('TZS ••••••'), findsOneWidget);

    await tester.tap(find.byTooltip('Show balance'));
    await tester.pumpAndSettle();
    expect(find.text('TZS 370,000'), findsOneWidget);
  });

  testWidgets('Move asks where the money comes from', (tester) async {
    await openHome(tester);

    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(find.text('Move money from'), findsOneWidget);
    // General savings and both goals hold money.
    final sheet = find.byType(BottomSheet);
    for (final place in ['General savings', 'New fridge', 'Van']) {
      expect(
        find.descendant(of: sheet, matching: find.text(place)),
        findsOneWidget,
      );
    }

    await tester.tap(find.descendant(of: sheet, matching: find.text('Van')));
    await tester.pumpAndSettle();
    expect(find.text('Move money'), findsOneWidget);
    expect(find.textContaining('From Van'), findsOneWidget);
  });

  testWidgets('shows recent activity and opens the full history', (
    tester,
  ) async {
    await openHome(tester);

    await tester.scrollUntilVisible(find.text('+ TZS 5,000'), 200);
    expect(find.text('Saved'), findsOneWidget);

    await tester.ensureVisible(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'History'), findsOneWidget);
    // A full page, with a way back.
    expect(find.byType(BackButton), findsOneWidget);
  });
}
