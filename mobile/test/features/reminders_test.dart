import 'dart:async';

import 'package:fanikisha/core/api/token_storage.dart';
import 'package:fanikisha/features/reminders/reminder_scheduler.dart';
import 'package:fanikisha/features/reminders/reminders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/test_app.dart';

/// Stands in for the phone's notification scheduler.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.allow = true, this.launch});

  /// Whether the user allows notifications when asked.
  bool allow;
  String? launch;
  int permissionRequests = 0;
  List<ScheduledReminder> scheduled = [];
  ReminderChannel? channel;
  final tapped = StreamController<String>.broadcast();

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allow;
  }

  @override
  Future<void> replaceAll(
    List<ScheduledReminder> reminders, {
    required ReminderChannel channel,
  }) async {
    scheduled = reminders;
    this.channel = channel;
  }

  @override
  Future<void> cancelAll() async => scheduled = [];

  @override
  Future<String?> launchRoute() async {
    final route = launch;
    launch = null;
    return route;
  }

  @override
  Stream<String> get taps => tapped.stream;
}

void main() {
  late FakeApi api;
  late FakeReminderScheduler scheduler;
  // A goal from 1 Nov to 1 Mar should hold 240,000 by 25 Nov; it has 50,000.
  late int saved;
  late DateTime now;

  setUp(() {
    saved = 50000;
    now = DateTime(2026, 11, 25, 10);
    scheduler = FakeReminderScheduler();
    api = FakeApi()
      ..on('GET', '/v1/me', (_) => FakeResponse(200, userJson()))
      ..on(
        'GET',
        '/v1/savings/summary',
        (_) => FakeResponse(200, summaryJson(total: saved)),
      )
      ..on(
        'GET',
        '/v1/goals',
        (_) => FakeResponse(200, [goalJson(saved: saved)]),
      )
      ..on(
        'GET',
        '/v1/goals/goal-1',
        (_) => FakeResponse(200, goalJson(saved: saved)),
      )
      ..on(
        'GET',
        '/v1/savings/today',
        (_) => FakeResponse(200, {
          'date': '2026-11-25',
          'sales': 0,
          'expenses': 0,
          'profit': 0,
          'rule': null,
          'target': 0,
          'savedToday': 0,
          'remaining': 0,
        }),
      )
      ..on('GET', '/v1/business/entries', (_) => const FakeResponse(200, []))
      ..on('POST', '/v1/auth/logout', (_) => const FakeResponse(204));
  });

  Future<void> start(
    WidgetTester tester, {
    Map<String, Object> preferences = const {},
  }) async {
    SharedPreferences.setMockInitialValues({'locale': 'en', ...preferences});
    await pumpApp(
      tester,
      api,
      tokens: const TokenPair(accessToken: 'a', refreshToken: 'r'),
      keepPreferences: true,
      overrides: [
        reminderSchedulerProvider.overrideWithValue(scheduler),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  }

  Future<void> openProfile(WidgetTester tester) async {
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
  }

  testWidgets('turning reminders on in Profile schedules a week of them', (
    tester,
  ) async {
    await start(tester);
    await openProfile(tester);
    expect(find.text('Off'), findsOneWidget);
    expect(scheduler.scheduled, isEmpty);

    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    expect(find.text('Reminders on: evenings around 19:00'), findsOneWidget);
    expect(
      find.text(
        "Evenings around 19:00, when a goal falls behind or today's saving is due",
      ),
      findsOneWidget,
    );
    expect(scheduler.scheduled, hasLength(7));
    final first = scheduler.scheduled.first;
    expect(first.at, DateTime(2026, 11, 25, 19));
    expect(first.title, 'New fridge is falling behind');
    expect(first.body, 'Save TZS 11,980 a day to reach it by 1 Mar 2027.');
    expect(first.route, '/goals/goal-1');
    expect(scheduler.channel?.name, 'Saving reminders');
  });

  testWidgets('a new time moves every reminder; off cancels them', (
    tester,
  ) async {
    await start(tester, preferences: {'reminders.enabled': true});
    await openProfile(tester);
    expect(scheduler.scheduled.first.at, DateTime(2026, 11, 25, 19));

    await tester.ensureVisible(find.text('Reminder time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reminder time'));
    await tester.pumpAndSettle();
    // The dial's input mode: type 20:30.
    await tester.tap(find.byTooltip('Switch to text input mode'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '20');
    await tester.enterText(fields.at(1), '30');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('20:30'), findsOneWidget);
    expect(scheduler.scheduled.first.at, DateTime(2026, 11, 25, 20, 30));
    expect(scheduler.scheduled, hasLength(7));

    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    expect(scheduler.scheduled, isEmpty);
    expect(find.text('Reminder time'), findsNothing);
  });

  testWidgets('if notifications are refused, reminders stay off', (
    tester,
  ) async {
    scheduler.allow = false;
    await start(tester);
    await openProfile(tester);

    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Notifications are blocked for Fanikisha'),
      findsOneWidget,
    );
    expect(find.text('Off'), findsOneWidget);
    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('the dashboard suggests reminders until answered', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Evening reminders'), findsOneWidget);

    await tester.tap(find.byTooltip('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Evening reminders'), findsNothing);
    expect(scheduler.permissionRequests, 0);
  });

  testWidgets('turning them on from the dashboard', (tester) async {
    await start(tester);

    await tester.ensureVisible(find.text('Turn on'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    expect(find.text('Evening reminders'), findsNothing);
    expect(find.text('Reminders on: evenings around 19:00'), findsOneWidget);
    expect(scheduler.scheduled, hasLength(7));
  });

  testWidgets('no suggestion while there is nothing to remind about', (
    tester,
  ) async {
    api.on('GET', '/v1/goals', (_) => const FakeResponse(200, []));
    await start(tester);

    expect(find.text('Evening reminders'), findsNothing);
  });

  testWidgets('a goal back on track drops its reminders', (tester) async {
    await start(tester, preferences: {'reminders.enabled': true});
    expect(scheduler.scheduled, hasLength(7));

    // Money was saved (elsewhere in the app); the data reloads.
    saved = 400000;
    await tester.drag(find.byType(ListView).first, const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('coming back to the app plans from the new day', (tester) async {
    await start(tester, preferences: {'reminders.enabled': true});
    expect(scheduler.scheduled.first.at, DateTime(2026, 11, 25, 19));

    // Left in the background overnight.
    final binding = tester.binding;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    now = DateTime(2026, 11, 26, 8);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();

    expect(scheduler.scheduled.first.at, DateTime(2026, 11, 26, 19));
    expect(scheduler.scheduled.last.at, DateTime(2026, 12, 2, 19));
  });

  testWidgets('logging out cancels the reminders', (tester) async {
    await start(tester, preferences: {'reminders.enabled': true});
    expect(scheduler.scheduled, isNotEmpty);

    await openProfile(tester);
    await tester.scrollUntilVisible(find.text('Log out'), 200);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Create an account'), findsOneWidget);
    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('tapping a reminder opens its goal', (tester) async {
    await start(tester, preferences: {'reminders.enabled': true});

    scheduler.tapped.add('/goals/goal-1');
    await tester.pumpAndSettle();

    expect(find.text('TZS 1,200,000'), findsWidgets);
    expect(find.text('Withdraw'), findsOneWidget);
  });

  testWidgets('a reminder that opened the app shows its screen', (
    tester,
  ) async {
    scheduler.launch = '/business/new';
    await start(tester, preferences: {'reminders.enabled': true});

    expect(find.text('New entry'), findsOneWidget);
  });

  testWidgets('unknown routes from a notification are ignored', (tester) async {
    await start(tester, preferences: {'reminders.enabled': true});

    scheduler.tapped.add('/profile/delete');
    await tester.pumpAndSettle();

    expect(find.text('Delete account'), findsNothing);
  });
}
