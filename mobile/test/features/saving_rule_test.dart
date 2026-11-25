import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeApi api;
  Map<String, Object?>? rule;
  late int sales;
  late int savedToday;

  Map<String, Object?> today() {
    final r = rule;
    final target = r == null ? 0 : sales * (r['percent']! as int) ~/ 100;
    return {
      'date': '2026-11-24',
      'sales': sales,
      'expenses': 0,
      'profit': sales,
      'rule': r,
      'target': target,
      'savedToday': savedToday,
      'remaining': (target - savedToday).clamp(0, target),
    };
  }

  setUp(() {
    rule = null;
    sales = 0;
    savedToday = 0;
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]))
      ..on('GET', '/v1/savings/today', (_) => FakeResponse(200, today()))
      ..on('PUT', '/v1/savings/rule', (r) {
        rule = Map<String, Object?>.from(r.data as Map);
        return FakeResponse(200, {'rule': rule});
      })
      ..on('DELETE', '/v1/savings/rule', (_) {
        rule = null;
        return const FakeResponse(204);
      })
      ..on('POST', '/v1/savings/deposits/preview', (r) {
        final amount = (r.data as Map<String, Object?>)['amount']! as int;
        return FakeResponse(200, {
          'amount': amount,
          'unallocatedAmount': 0,
          'allocations': [
            {'goalId': 'goal-1', 'goalName': 'New fridge', 'amount': amount},
          ],
        });
      });
  });

  Future<void> openDashboard(WidgetTester tester) => pumpApp(
    tester,
    api,
    tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
  );

  testWidgets('sets a rule from the dashboard', (tester) async {
    sales = 120000;
    await openDashboard(tester);
    expect(find.text("Save a share of each day's sales"), findsOneWidget);

    await tester.tap(find.text('Set a rule'));
    await tester.pumpAndSettle();
    expect(find.text('Saving rule'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '15%'));
    await tester.pumpAndSettle();
    expect(
      find.text('With TZS 100,000 in sales, you would save TZS 15,000.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save rule'));
    await tester.pumpAndSettle();

    expect(api.requestsTo('PUT', '/v1/savings/rule').single.data, {
      'basis': 'SALES',
      'percent': 15,
    });
    // Back on the dashboard, with today's target.
    expect(find.text("Today's saving target"), findsOneWidget);
    expect(find.text("15% of today's sales (TZS 120,000)"), findsOneWidget);
    expect(find.text('TZS 18,000'), findsOneWidget);
  });

  testWidgets('saves the rest of the target in one tap', (tester) async {
    rule = {'basis': 'SALES', 'percent': 10};
    sales = 120000;
    savedToday = 5000;
    await openDashboard(tester);

    expect(find.text('TZS 12,000'), findsOneWidget);
    expect(find.text('Saved today: TZS 5,000 of TZS 12,000'), findsOneWidget);
    await tester.tap(find.text('Save TZS 7,000'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Save money'), findsOneWidget);
    expect(find.text('7,000'), findsOneWidget);
    expect(api.requestsTo('POST', '/v1/savings/deposits/preview').single.data, {
      'amount': 7000,
    });
  });

  testWidgets('asks for sales before setting a target', (tester) async {
    rule = {'basis': 'SALES', 'percent': 10};
    await openDashboard(tester);
    expect(
      find.text("Record today's sales to see how much to save."),
      findsOneWidget,
    );
    await tester.tap(find.text('Record sales'));
    await tester.pumpAndSettle();
    expect(find.text('New entry'), findsOneWidget);
  });

  testWidgets('celebrates a reached target', (tester) async {
    rule = {'basis': 'SALES', 'percent': 10};
    sales = 50000;
    savedToday = 6000;
    await openDashboard(tester);
    expect(find.text("Today's target reached. Well done!"), findsOneWidget);
    expect(find.textContaining('Save TZS'), findsNothing);
  });

  testWidgets('switches to profit, or removes the rule', (tester) async {
    rule = {'basis': 'SALES', 'percent': 10};
    sales = 50000;
    await openDashboard(tester);
    await tester.tap(find.byTooltip('Change rule'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profit'));
    await tester.pumpAndSettle();
    expect(
      find.text('With TZS 40,000 in profit, you would save TZS 4,000.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Remove rule'));
    await tester.pumpAndSettle();
    expect(api.requestsTo('DELETE', '/v1/savings/rule'), hasLength(1));
    expect(find.text("Save a share of each day's sales"), findsOneWidget);
  });
}
