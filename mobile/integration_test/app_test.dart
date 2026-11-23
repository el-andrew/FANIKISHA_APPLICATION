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
    Future<void> fill(String label, String value) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    await fill('Full name', 'Neema Mollel');
    await fill('Business name (optional)', 'Neema Fresh Juice');
    await fill('Email', email);
    await fill('Password', 'juice stall 2026');
    await fill('Confirm password', 'juice stall 2026');
    await capture(tester, '02-register');
    await tapText(tester, 'Create account');

    // An empty dashboard.
    await waitFor(tester, find.text('Hello, Neema'));
    await waitFor(tester, find.text('No goals yet'));
    await capture(tester, '03-dashboard-empty');

    // Create a goal.
    await tapText(tester, 'Create a goal');
    await waitFor(tester, find.text('What are you saving for?'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What are you saving for?'),
      'Blender',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Target amount'),
      '450000',
    );
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

    // Save money and check the split.
    await tapText(tester, 'Save money');
    await waitFor(tester, find.text('How it will be shared'));
    await tester.enterText(find.byType(TextFormField).first, '45000');
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

    // So does the history tab.
    await tapText(tester, 'History');
    await waitFor(tester, find.text('TZS 45,000'));
    await tester.tap(find.text('TZS 45,000'));
    await tester.pumpAndSettle();
    await capture(tester, '09-history');
  });
}
