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
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]))
      ..on('DELETE', '/v1/me', (r) {
        final password = (r.data as Map<String, Object?>)['password'];
        return password == 'my password'
            ? const FakeResponse(204)
            : const FakeResponse(403, {
                'statusCode': 403,
                'message': 'That password is not correct',
                'code': 'wrong_password',
              });
      });
  });

  Future<MemoryTokenStorage> openDeleteScreen(
    WidgetTester tester, {
    String locale = 'en',
  }) async {
    final storage = await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      locale: locale,
    );
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    final delete = find.byIcon(Icons.delete_forever_outlined);
    await tester.scrollUntilVisible(
      delete,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    return storage;
  }

  Future<void> deleteWith(WidgetTester tester, String password) async {
    await tester.enterText(find.byType(TextFormField), password);
    final submit = find.byType(FilledButton);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  testWidgets('a wrong password deletes nothing', (tester) async {
    final storage = await openDeleteScreen(tester);
    await deleteWith(tester, 'not it');
    expect(find.text('That password is not correct.'), findsOneWidget);
    expect(await storage.read(), isNotNull);
  });

  testWidgets('deletes the account and returns to the welcome screen', (
    tester,
  ) async {
    final storage = await openDeleteScreen(tester);
    expect(find.text('Delete your account?'), findsOneWidget);

    await deleteWith(tester, 'my password');

    final request = api.requestsTo('DELETE', '/v1/me').single;
    expect(request.data, {'password': 'my password'});
    expect(find.text('Your account has been deleted.'), findsOneWidget);
    expect(find.text('Save for what your business needs next'), findsOneWidget);
    expect(await storage.read(), isNull);
  });

  testWidgets('explains a wrong password in Kiswahili', (tester) async {
    await openDeleteScreen(tester, locale: 'sw');
    await deleteWith(tester, 'not it');
    expect(find.text('Nenosiri si sahihi.'), findsOneWidget);
  });
}
