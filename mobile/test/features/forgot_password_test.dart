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
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]))
      ..on('POST', '/v1/auth/password-reset', (_) => const FakeResponse(202))
      ..on('POST', '/v1/auth/password-reset/confirm', (r) {
        final body = r.data as Map<String, Object?>;
        return body['code'] == '123456'
            ? FakeResponse(200, {...tokensJson(), 'user': userJson()})
            : const FakeResponse(400, {
                'statusCode': 400,
                'message': 'That code is not correct. 4 tries left',
                'code': 'code_incorrect',
                'triesLeft': 4,
              });
      });
  });

  Future<void> openReset(WidgetTester tester) async {
    await pumpApp(tester, api);
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'asha@example.com',
    );
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
  }

  Future<void> submitReset(WidgetTester tester, String code) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Verification code'),
      code,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'a brand new password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'a brand new password',
    );
    final submit = find.widgetWithText(FilledButton, 'Reset password');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  testWidgets('resets the password with the texted code and signs in', (
    tester,
  ) async {
    await openReset(tester);
    final request = api.requestsTo('POST', '/v1/auth/password-reset').single;
    expect(request.data, {'email': 'asha@example.com', 'language': 'en'});
    expect(
      find.textContaining('If asha@example.com has an account'),
      findsOneWidget,
    );

    await submitReset(tester, '123456');
    expect(find.text('Hello, Asha'), findsOneWidget);
  });

  testWidgets('explains a wrong code', (tester) async {
    await openReset(tester);
    await submitReset(tester, '000000');
    expect(
      find.text('That code is not correct. 4 tries left.'),
      findsOneWidget,
    );
  });

  testWidgets('waits before another code can be requested', (tester) async {
    await openReset(tester);
    expect(find.text('Send a new code in 60s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 61));
    await tester.tap(find.text('Send a new code'));
    await tester.pumpAndSettle();
    expect(api.requestsTo('POST', '/v1/auth/password-reset'), hasLength(2));
  });
}
