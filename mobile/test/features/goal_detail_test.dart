import 'package:fanikisha/core/api/token_storage.dart';
import 'package:fanikisha/features/reminders/reminders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeApi api;
  late Map<String, Object?> goal;

  // goalJson runs 1 Nov to 1 Mar (120 days). On 26 Nov an even pace has
  // saved 25/120 of 1,200,000: 250,000, about 20%.
  final clock = clockProvider.overrideWithValue(
    () => DateTime(2026, 11, 26, 10),
  );

  setUp(() {
    goal = goalJson(saved: 50000);
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goal]))
      ..on('GET', '/v1/goals/goal-1', (_) => FakeResponse(200, goal))
      ..on('DELETE', '/v1/goals/goal-1', (_) {
        goal = {...goal, 'status': 'ARCHIVED'};
        return FakeResponse(200, goal);
      });
  });

  Future<void> openGoal(WidgetTester tester) async {
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      overrides: [clock],
    );
    await tester.tap(find.text('New fridge'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows how far behind an even pace the goal is', (tester) async {
    await openGoal(tester);

    expect(find.text('TZS 50,000'), findsOneWidget);
    expect(find.text('of TZS 1,200,000'), findsOneWidget);
    expect(find.text('Behind'), findsOneWidget);
    expect(find.text('4% saved'), findsOneWidget);
    expect(find.text('Should be 20% by today'), findsOneWidget);
    expect(find.text('TZS 200,000 behind pace'), findsOneWidget);
    // What finishing on time takes.
    expect(find.text('TZS 11,500 a day'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('days left'), findsOneWidget);
  });

  testWidgets('a goal on pace says so', (tester) async {
    goal = goalJson(saved: 300000);
    await openGoal(tester);

    expect(find.text('On track'), findsOneWidget);
    expect(find.textContaining('behind pace'), findsNothing);
  });

  testWidgets('a goal started today has no pace marker yet', (tester) async {
    goal = {...goalJson(saved: 0), 'startDate': '2026-11-26'};
    await openGoal(tester);

    expect(find.text('0% saved'), findsOneWidget);
    expect(find.textContaining('Should be'), findsNothing);
    expect(find.text('On track'), findsOneWidget);
  });

  testWidgets('a completed goal has no pace or Save', (tester) async {
    goal = goalJson(saved: 1200000, status: 'COMPLETED');
    await openGoal(tester);

    expect(find.text('Completed'), findsOneWidget);
    expect(find.textContaining('a day'), findsNothing);
    expect(find.text('Save'), findsNothing);
    // The money in it can still move or be taken out.
    expect(find.text('Move'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);
  });

  testWidgets('archiving is in the menu, and asks first', (tester) async {
    await openGoal(tester);
    expect(find.text('Archive goal'), findsNothing);

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive goal'));
    await tester.pumpAndSettle();
    expect(find.text('Archive this goal?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();
    expect(api.requestsTo('DELETE', '/v1/goals/goal-1'), hasLength(1));
    // Back where it was opened from.
    expect(find.text('Hello, Asha'), findsOneWidget);
  });
}
