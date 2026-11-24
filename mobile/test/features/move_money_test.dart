import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeApi api;
  late List<Map<String, Object?>> activity;

  setUp(() {
    activity = [];
    final fridge = goalJson(id: 'goal-1', name: 'New fridge', saved: 300000);
    final van = goalJson(id: 'goal-2', name: 'Van', target: 9000000, saved: 0);
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson(general: 20000)),
      )
      ..on('GET', '/v1/goals', (r) {
        final status = r.queryParameters['status'];
        return FakeResponse(200, status == 'ACTIVE' ? [fridge, van] : []);
      })
      ..on('GET', '/v1/goals/goal-1', (_) => FakeResponse(200, fridge))
      ..on('POST', '/v1/savings/transfers', (r) {
        final body = r.data as Map<String, Object?>;
        if ((body['amount']! as int) > 250000) {
          return const FakeResponse(400, {
            'statusCode': 400,
            'message': 'Only 250000 TZS is available there',
            'code': 'insufficient_funds',
            'available': 250000,
          });
        }
        return FakeResponse(201, {'id': 'm1', 'kind': 'TRANSFER', ...body});
      })
      ..on(
        'POST',
        '/v1/savings/withdrawals',
        (r) => FakeResponse(201, {'id': 'm2', 'kind': 'WITHDRAWAL'}),
      )
      ..on(
        'GET',
        '/v1/savings/activity',
        (_) => FakeResponse(200, {'items': activity, 'nextCursor': null}),
      );
  });

  Future<void> open(WidgetTester tester) => pumpApp(
    tester,
    api,
    tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
  );

  Future<void> submit(WidgetTester tester) async {
    final button = find.byType(FilledButton).last;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('moves money from one goal to another', (tester) async {
    await open(tester);
    await tester.tap(find.text('New fridge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move money'));
    await tester.pumpAndSettle();

    expect(find.text('From New fridge: TZS 300,000 available'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '50000');
    await tester.tap(find.text('Van'));
    await tester.pumpAndSettle();
    expect(find.text('Move TZS 50,000'), findsOneWidget);
    await submit(tester);

    final request = api.requestsTo('POST', '/v1/savings/transfers').single;
    expect(request.data, {'from': 'goal-1', 'to': 'goal-2', 'amount': 50000});
    expect(request.headers['Idempotency-Key'], isNotEmpty);
    expect(find.text('Money moved'), findsOneWidget);
  });

  testWidgets('will not move more than is available', (tester) async {
    await open(tester);
    await tester.tap(find.text('New fridge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move money'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '400000');
    await submit(tester);
    expect(
      find.text("That's more than the TZS 300,000 available"),
      findsOneWidget,
    );
    expect(api.requestsTo('POST', '/v1/savings/transfers'), isEmpty);

    // The server may know of less (e.g. a move on another phone).
    await tester.enterText(find.byType(TextFormField), '280000');
    await submit(tester);
    expect(
      find.text("That's more than the TZS 250,000 available"),
      findsOneWidget,
    );
  });

  testWidgets('takes money out of general savings', (tester) async {
    await open(tester);
    await tester.tap(find.text('General savings: TZS 20,000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();

    expect(
      find.text('From General savings: TZS 20,000 available'),
      findsOneWidget,
    );
    await tester.tap(find.text('All'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What was it for? (optional)'),
      'School fees',
    );
    await submit(tester);

    final request = api.requestsTo('POST', '/v1/savings/withdrawals').single;
    expect(request.data, {
      'from': null,
      'amount': 20000,
      'note': 'School fees',
    });
    expect(find.text('Withdrawal recorded'), findsOneWidget);
  });

  testWidgets('shows moves and withdrawals in history', (tester) async {
    activity = [
      {
        'kind': 'WITHDRAWAL',
        'id': 'm2',
        'amount': 40000,
        'from': {'goalId': 'goal-1', 'goalName': 'Blender'},
        'to': null,
        'note': 'Bought it',
        'createdAt': '2026-11-24T09:00:00.000Z',
      },
      {
        'kind': 'TRANSFER',
        'id': 'm1',
        'amount': 5000,
        'from': {'goalId': null, 'goalName': null},
        'to': {'goalId': 'goal-2', 'goalName': 'Van'},
        'note': null,
        'createdAt': '2026-11-24T08:00:00.000Z',
      },
    ];
    await open(tester);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('− TZS 40,000'), findsOneWidget);
    expect(
      find.textContaining('Taken out of Blender · Bought it'),
      findsOneWidget,
    );
    expect(find.text('TZS 5,000'), findsOneWidget);
    expect(
      find.textContaining('Moved from General savings to Van'),
      findsOneWidget,
    );
  });
}
