// Runs the real app against a running Fanikisha API:
//
//   flutter test integration_test -d linux \
//     --dart-define=API_BASE_URL=http://localhost:3000
//
// Creates a new account each run, so it is safe on a development database.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:fanikisha/app.dart';
import 'package:fanikisha/core/api/token_storage.dart';
import 'package:fanikisha/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Set `--dart-define=SCREENSHOT_DIR=/some/dir` to save a PNG of each step.
const _screenshotDir = String.fromEnvironment('SCREENSHOT_DIR');
final _screen = GlobalKey();

Future<void> capture(WidgetTester tester, String name) async {
  if (_screenshotDir.isEmpty) return;
  await tester.pump(const Duration(milliseconds: 400));
  final boundary =
      _screen.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_screenshotDir/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

/// The text in [field], ignoring thousands separators (amount fields).
String _textIn(WidgetTester tester, Finder field) => tester
    .widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .controller
    .text
    .replaceAll(',', '');

/// Types [value] into [field] and checks it arrived.
///
/// On a loaded desktop test machine, simulated typing occasionally loses a
/// field's text when focus moves on, so this retries. The app itself never
/// clears a field, so three failed tries still fail the test.
Future<void> typeInto(WidgetTester tester, Finder field, String value) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
    if (_textIn(tester, field) == value) return;
  }
  throw TestFailure('Could not type "$value" into $field');
}

/// Fills a form, then re-checks every field before the caller submits.
Future<void> fillForm(WidgetTester tester, Map<Finder, String> values) async {
  for (final MapEntry(key: field, :value) in values.entries) {
    await typeInto(tester, field, value);
  }
  for (var round = 0; round < 3; round++) {
    var lost = false;
    for (final MapEntry(key: field, :value) in values.entries) {
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      if (_textIn(tester, field) != value) {
        lost = true;
        await typeInto(tester, field, value);
      }
    }
    if (!lost) return;
  }
  throw TestFailure('Form fields kept losing their text');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps until [finder] matches: real network calls take real time.
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    await capture(tester, 'timed-out');
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text).last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pump();
  }

  testWidgets('sign up, create a goal, save money, see it everywhere', (
    tester,
  ) async {
    // A phone-sized screen (412 x 892 logical pixels).
    // Integration tests leave the platform's text input connected; on Linux
    // it can echo a stale (empty) value back into a field when focus moves.
    // Route text input through the test instead.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);

    tester.view.physicalSize = const Size(1236, 2676);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    final preferences = await SharedPreferences.getInstance();
    final email = 'it-${DateTime.now().millisecondsSinceEpoch}@example.com';

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          // No desktop keyring on a headless test machine.
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          if (const String.fromEnvironment('API_BASE_URL').isNotEmpty)
            apiBaseUrlProvider.overrideWithValue(
              const String.fromEnvironment('API_BASE_URL'),
            ),
        ],
        child: RepaintBoundary(key: _screen, child: const FanikishaApp()),
      ),
    );

    // Sign up.
    await waitFor(tester, find.text('Create an account'));
    await capture(tester, '01-welcome');
    await tapText(tester, 'Create an account');
    await waitFor(tester, find.text('Create your account'));
    Finder field(String label) => find.widgetWithText(TextFormField, label);
    await fillForm(tester, {
      field('Full name'): 'Neema Mollel',
      field('Business name (optional)'): 'Neema Fresh Juice',
      field('Email'): email,
      field('Password'): 'juice stall 2026',
      field('Confirm password'): 'juice stall 2026',
    });
    await capture(tester, '02-register');
    await tapText(tester, 'Create account');

    // An empty dashboard.
    await waitFor(tester, find.text('Hello, Neema'));
    await waitFor(tester, find.text('No goals yet'));
    await capture(tester, '03-dashboard-empty');

    // Create a goal.
    await tapText(tester, 'Create a goal');
    await waitFor(tester, find.text('What are you saving for?'));
    await fillForm(tester, {
      field('What are you saving for?'): 'Blender',
      field('Target amount'): '450000',
    });
    await tester.tap(find.widgetWithText(TextFormField, 'Target date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Very high'));
    await tester.pumpAndSettle();
    await capture(tester, '04-new-goal');
    await tapText(tester, 'Create goal');

    // Its detail page, then back to the dashboard.
    await waitFor(tester, find.text('TZS 450,000'));
    await capture(tester, '05-goal-detail');
    await tester.pageBack();
    await waitFor(tester, find.text('Blender'));

    // Save money (Home's Save action) and check the split.
    await tapText(tester, 'Save');
    await waitFor(tester, find.text('How it will be shared'));
    await fillForm(tester, {find.byType(TextFormField).first: '45000'});
    await waitFor(tester, find.text('Save TZS 45,000'));
    await waitFor(tester, find.text('Blender'));
    await capture(tester, '06-save-preview');
    await tapText(tester, 'Save TZS 45,000');
    await waitFor(tester, find.text('Saved!'));
    await capture(tester, '07-saved');
    await tapText(tester, 'Done');

    // The dashboard shows the new total and the goal's progress.
    await waitFor(tester, find.text('TZS 45,000'));
    await waitFor(tester, find.text('10%'));
    await capture(tester, '08-dashboard');

    // So does the full history, opened from Home.
    await tapText(tester, 'History');
    await waitFor(tester, find.widgetWithText(AppBar, 'History'));
    await waitFor(tester, find.text('+ TZS 45,000'));
    await tester.tap(find.text('+ TZS 45,000'));
    await tester.pumpAndSettle();
    await capture(tester, '09-history');
    await tester.pageBack();
    await waitFor(tester, find.text('Hello, Neema'));

    // Record the day's sales and a stock purchase; see the profit.
    await tapText(tester, 'Business');
    await waitFor(tester, find.text('Sale'));
    await tapText(tester, 'Sale');
    await waitFor(tester, find.text('New entry'));
    await fillForm(tester, {find.byType(TextFormField).first: '120000'});
    await tapText(tester, 'Save');
    await waitFor(tester, find.text('+ TZS 120,000'));

    await tapText(tester, 'Expense');
    await waitFor(tester, find.text('New entry'));
    await fillForm(tester, {find.byType(TextFormField).first: '35000'});
    await tapText(tester, 'Stock');
    await tapText(tester, 'Save');
    await waitFor(tester, find.text('− TZS 35,000'));
    await waitFor(tester, find.text('TZS 85,000'));

    await tapText(tester, '7 days');
    await waitFor(tester, find.text('TZS 85,000'));
    await capture(tester, '10-business');

    // A 10% saving rule: today's 45,000 already covers the 12,000 target.
    await tapText(tester, 'Home');
    await waitFor(tester, find.text('Set a rule'));
    await tapText(tester, 'Set a rule');
    await waitFor(tester, find.text('Save rule'));
    await tapText(tester, 'Save rule');
    await waitFor(tester, find.text('10% of sales'));
    await waitFor(tester, find.text("Today's target reached. Well done!"));
    await capture(tester, '11-dashboard-rule');

    // Take some money out of the goal; History shows it.
    await tapText(tester, 'Blender');
    await waitFor(tester, find.text('Withdraw'));
    await tapText(tester, 'Withdraw');
    await waitFor(tester, find.text('From Blender: TZS 45,000 available'));
    await fillForm(tester, {find.byType(TextFormField).first: '5000'});
    await tapText(tester, 'Take out TZS 5,000');
    await waitFor(tester, find.text('Withdrawal recorded'));
    await waitFor(tester, find.text('TZS 40,000'));
    await tester.pageBack();
    await waitFor(tester, find.text('Hello, Neema'));
    await tapText(tester, 'History');
    await waitFor(tester, find.widgetWithText(AppBar, 'History'));
    await waitFor(tester, find.text('− TZS 5,000'));
    await capture(tester, '12-history-activity');
  });
}
