import 'package:fanikisha/core/api/token_storage.dart';
import 'package:fanikisha/core/format/dates.dart';
import 'package:fanikisha/features/business/presentation/daily_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

/// A tiny in-memory stand-in for the business endpoints.
class FakeBusiness {
  final entries = <Map<String, Object?>>[];
  var _next = 0;

  void add(String type, int amount, {String? category, String? note}) {
    entries.insert(0, {
      'id': 'entry-${++_next}',
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'occurredOn': toDateOnly(DateTime.now()),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  int _sum(String type) => entries
      .where((e) => e['type'] == type)
      .fold(0, (s, e) => s + (e['amount']! as int));

  void install(FakeApi api) {
    api
      ..on('GET', '/v1/business/entries', (_) {
        return FakeResponse(200, {'items': entries, 'nextCursor': null});
      })
      ..on('GET', '/v1/business/summary', (r) {
        final from = DateTime.parse(r.queryParameters['from']! as String);
        final to = DateTime.parse(r.queryParameters['to']! as String);
        final days = [
          for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1)))
            {
              'date': toDateOnly(d),
              'sales': toDateOnly(d) == toDateOnly(to) ? _sum('SALE') : 0,
              'expenses': toDateOnly(d) == toDateOnly(to) ? _sum('EXPENSE') : 0,
            },
        ];
        return FakeResponse(200, {
          'from': toDateOnly(from),
          'to': toDateOnly(to),
          'sales': _sum('SALE'),
          'expenses': _sum('EXPENSE'),
          'profit': _sum('SALE') - _sum('EXPENSE'),
          'days': days,
          'expenseCategories': [
            for (final e in entries.where((e) => e['type'] == 'EXPENSE'))
              {'category': e['category'], 'amount': e['amount']},
          ],
        });
      })
      ..on('POST', '/v1/business/entries', (r) {
        final body = r.data as Map<String, Object?>;
        add(
          body['type']! as String,
          body['amount']! as int,
          category: body['category'] as String?,
          note: body['note'] as String?,
        );
        return FakeResponse(201, entries.first);
      })
      ..on('GET', '/v1/business/entries/entry-1', (_) {
        return FakeResponse(
          200,
          entries.firstWhere((e) => e['id'] == 'entry-1'),
        );
      })
      ..on('PATCH', '/v1/business/entries/entry-1', (r) {
        final entry = entries.firstWhere((e) => e['id'] == 'entry-1');
        entry.addAll(r.data as Map<String, Object?>);
        return FakeResponse(200, entry);
      })
      ..on('DELETE', '/v1/business/entries/entry-1', (_) {
        entries.removeWhere((e) => e['id'] == 'entry-1');
        return const FakeResponse(204);
      });
  }
}

void main() {
  late FakeApi api;
  late FakeBusiness business;

  setUp(() {
    business = FakeBusiness();
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]));
    business.install(api);
  });

  Future<void> openBusiness(WidgetTester tester, {String locale = 'en'}) async {
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      locale: locale,
    );
    await tester.tap(find.byIcon(Icons.storefront_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets("shows the day's sales, expenses and profit", (tester) async {
    business
      ..add('SALE', 50000)
      ..add('EXPENSE', 12000, category: 'Stock', note: 'Sugar');
    await openBusiness(tester);

    expect(find.text('Profit'), findsOneWidget);
    expect(find.text('TZS 38,000'), findsOneWidget);
    expect(find.text('TZS 50,000'), findsOneWidget);
    expect(find.text('+ TZS 50,000'), findsOneWidget);
    expect(find.text('− TZS 12,000'), findsOneWidget);
    expect(find.text('Biggest expenses'), findsOneWidget);
    // One day: no chart. Seven days: a chart.
    expect(find.byType(DailyChart), findsNothing);
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(find.byType(DailyChart), findsOneWidget);
    final summary = api.requestsTo('GET', '/v1/business/summary').last;
    expect(summary.queryParameters['to'], toDateOnly(DateTime.now()));
    expect(
      summary.queryParameters['from'],
      toDateOnly(DateTime.now().subtract(const Duration(days: 6))),
    );
  });

  testWidgets('records an expense with a suggested category', (tester) async {
    await openBusiness(tester);
    expect(
      find.text(
        'No sales or expenses yet. Record them each day to see your profit.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '12000');
    await tester.tap(find.widgetWithText(ActionChip, 'Transport'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final request = api.requestsTo('POST', '/v1/business/entries').single;
    expect(request.headers['Idempotency-Key'], isNotEmpty);
    expect(request.data, {
      'type': 'EXPENSE',
      'amount': 12000,
      'occurredOn': toDateOnly(DateTime.now()),
      'category': 'Transport',
    });
    // Back on the tab, which reloaded.
    expect(find.text('Loss'), findsOneWidget);
    expect(find.text('− TZS 12,000'), findsOneWidget);
  });

  testWidgets('corrects and deletes an entry', (tester) async {
    business.add('SALE', 10000);
    await openBusiness(tester);

    await tester.tap(find.text('+ TZS 10,000'));
    await tester.pumpAndSettle();
    expect(find.text('Edit entry'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '11000');
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('+ TZS 11,000'), findsOneWidget);

    await tester.tap(find.text('+ TZS 11,000'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('+ TZS 11,000'), findsNothing);
    expect(business.entries, isEmpty);
  });

  testWidgets('speaks Kiswahili', (tester) async {
    business.add('SALE', 5000);
    await openBusiness(tester, locale: 'sw');
    expect(find.text('Biashara'), findsWidgets);
    expect(find.text('Faida'), findsOneWidget);
    expect(find.text('Mauzo'), findsWidgets);
  });
}
