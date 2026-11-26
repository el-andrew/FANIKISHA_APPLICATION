import 'package:fanikisha/core/api/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeApi api;
  late bool verified;
  late List<String> languages;

  setUp(() {
    verified = false;
    languages = [];
    api = FakeApi()
      ..on(
        'GET',
        '/v1/me',
        (_) => FakeResponse(200, userJson(phoneVerified: verified)),
      )
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson()),
      )
      ..on('GET', '/v1/goals', (_) => FakeResponse(200, [goalJson()]))
      ..on('POST', '/v1/me/phone/verification', (r) {
        languages.add((r.data as Map<String, Object?>)['language']! as String);
        final now = DateTime.now();
        return FakeResponse(202, {
          'phone': '+255712345678',
          'expiresAt': now.add(const Duration(minutes: 10)).toIso8601String(),
          'resendAvailableAt': now
              .add(const Duration(seconds: 60))
              .toIso8601String(),
        });
      })
      ..on('POST', '/v1/me/phone/verification/confirm', (r) {
        final code = (r.data as Map<String, Object?>)['code'];
        if (code == '123456') {
          verified = true;
          return FakeResponse(200, userJson(phoneVerified: true));
        }
        return const FakeResponse(400, {
          'statusCode': 400,
          'message': 'That code is not correct. 4 tries left',
          'code': 'code_incorrect',
          'triesLeft': 4,
        });
      });
  });

  Future<void> openVerification(
    WidgetTester tester, {
    String locale = 'en',
  }) async {
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      locale: locale,
    );
    await tester.tap(find.byType(TextButton).first); // "Verify now" on the card
    await tester.pumpAndSettle();
  }

  testWidgets('verifies the phone from the dashboard reminder', (tester) async {
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
    );
    expect(find.text('Verify your phone number'), findsOneWidget);

    await tester.tap(find.text('Verify now'));
    await tester.pumpAndSettle();
    expect(languages, ['en']);
    expect(
      find.text('We sent a 6-digit code to +255712345678.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();
    expect(
      find.text('That code is not correct. 4 tries left.'),
      findsOneWidget,
    );

    // Six digits submit by themselves.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('Phone number verified'), findsOneWidget);
    expect(find.text('Hello, Asha'), findsOneWidget);
    expect(find.text('Verify your phone number'), findsNothing);
  });

  testWidgets('says when the SMS could not be sent', (tester) async {
    // What the API answers when Beem refuses the message.
    api.on(
      'POST',
      '/v1/me/phone/verification',
      (_) => const FakeResponse(503, {
        'statusCode': 503,
        'message': 'We could not send the SMS. Please try again later',
        'code': 'sms_failed',
      }),
    );
    await openVerification(tester);

    expect(
      find.text("We couldn't send the SMS. Please try again later."),
      findsOneWidget,
    );
    // Not the general server error (errorServer).
    expect(
      find.text(
        'Something went wrong on our side. Please try again in a moment.',
      ),
      findsNothing,
    );
  });

  testWidgets('asks for the SMS and shows errors in Kiswahili', (tester) async {
    await openVerification(tester, locale: 'sw');
    expect(languages, ['sw']);
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();
    expect(find.text('Namba si sahihi. Zimebaki nafasi 4.'), findsOneWidget);
  });

  testWidgets('counts down before a new code can be requested', (tester) async {
    await openVerification(tester);
    final resend = find.widgetWithText(TextButton, 'Send a new code in 60s');
    expect(resend, findsOneWidget);
    expect(tester.widget<TextButton>(resend).onPressed, isNull);

    await tester.pump(const Duration(seconds: 61));
    final ready = find.widgetWithText(TextButton, 'Send a new code');
    expect(tester.widget<TextButton>(ready).onPressed, isNotNull);

    await tester.tap(ready);
    await tester.pumpAndSettle();
    expect(languages, ['en', 'en']);
  });

  testWidgets('shows the verified badge on the profile', (tester) async {
    verified = true;
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
    );
    expect(find.text('Verify your phone number'), findsNothing);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Verify phone number'), findsNothing);
  });
}
