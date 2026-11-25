import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeApi api;

  setUp(() {
    api = FakeApi()
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]));
  });

  testWidgets('a signed-out user lands on the welcome screen', (tester) async {
    await pumpApp(tester, api);
    expect(find.text('Save for what your business needs next'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('log in: validates, reports wrong passwords, then signs in', (
    tester,
  ) async {
    api.on('POST', '/v1/auth/login', (r) {
      final body = r.data as Map<String, Object?>;
      return body['password'] == 'correct password'
          ? FakeResponse(200, {...tokensJson(), 'user': userJson()})
          : const FakeResponse(401, {'message': 'Incorrect email or password'});
    });
    final storage = await pumpApp(tester, api);

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsNWidgets(2));
    expect(api.requestsTo('POST', '/v1/auth/login'), isEmpty);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'asha@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'correct password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Asha'), findsOneWidget);
    expect(find.text('TZS 300,000'), findsOneWidget);
    expect((await storage.read())!.accessToken, 'access-1');
  });

  testWidgets('register checks the password confirmation', (tester) async {
    await pumpApp(tester, api);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'a strong password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'something else',
    );
    final submit = find.widgetWithText(FilledButton, 'Create account');
    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(submit, 200, scrollable: page);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text("Passwords don't match"),
      -200,
      scrollable: page,
    );
    expect(find.text("Passwords don't match"), findsOneWidget);
    expect(api.requestsTo('POST', '/v1/auth/register'), isEmpty);
  });

  testWidgets('signing up opens the dashboard', (tester) async {
    api.on(
      'POST',
      '/v1/auth/register',
      (_) => FakeResponse(201, {...tokensJson(), 'user': userJson()}),
    );
    await pumpApp(tester, api);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    final page = find.byType(Scrollable).first;
    Future<void> fill(String label, String value) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.scrollUntilVisible(field, 100, scrollable: page);
      await tester.enterText(field, value);
    }

    await fill('Full name', 'Asha Mwakyusa');
    await fill('Email', 'asha@example.com');
    await fill('Password', 'a strong password');
    await fill('Confirm password', 'a strong password');
    final submit = find.widgetWithText(FilledButton, 'Create account');
    await tester.scrollUntilVisible(submit, 100, scrollable: page);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit, warnIfMissed: true);
    await tester.pumpAndSettle();

    expect(find.text('Hello, Asha'), findsOneWidget);
  });

  testWidgets('a saved session opens the dashboard directly', (tester) async {
    api.on('GET', '/v1/me', (_) => FakeResponse(200, userJson()));
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
    );
    expect(find.text('Hello, Asha'), findsOneWidget);
    expect(find.text('New fridge'), findsOneWidget);
  });

  testWidgets('shows the app in Swahili', (tester) async {
    api.on('GET', '/v1/me', (_) => FakeResponse(200, userJson()));
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      locale: 'sw',
    );
    expect(find.text('Habari, Asha'), findsOneWidget);
    expect(find.text('Weka akiba'), findsOneWidget);
  });
}
