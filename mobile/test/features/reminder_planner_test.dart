import 'package:fanikisha/features/goals/data/goal.dart';
import 'package:fanikisha/features/goals/data/goal_pace.dart';
import 'package:fanikisha/features/reminders/reminder_planner.dart';
import 'package:fanikisha/features/reminders/reminders.dart';
import 'package:fanikisha/features/savings/data/savings_models.dart';
import 'package:fanikisha/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// 600,000 over the 60 days from 1 Nov to 31 Dec: 10,000 a day.
Goal goal({
  String id = 'goal-1',
  String name = 'Blender',
  int saved = 100000,
  int target = 600000,
  int priority = 3,
  DateTime? start,
  DateTime? targetDate,
}) => Goal(
  id: id,
  name: name,
  targetAmount: target,
  savedAmount: saved,
  remainingAmount: target - saved,
  progressPercent: saved * 100 / target,
  priority: priority,
  startDate: start ?? DateTime(2026, 11),
  targetDate: targetDate ?? DateTime(2026, 12, 31),
  daysLeft: 36,
  dailyTargetAmount: 0,
  status: GoalStatus.active,
);

TodaySavings today({
  SavingRule? rule,
  int sales = 0,
  int expenses = 0,
  int savedToday = 0,
}) {
  final target = rule?.targetFor(sales: sales, expenses: expenses) ?? 0;
  return TodaySavings(
    sales: sales,
    expenses: expenses,
    profit: sales - expenses,
    rule: rule,
    target: target,
    savedToday: savedToday,
    remaining: (target - savedToday).clamp(0, target),
  );
}

const tenPercentOfSales = SavingRule(basis: SavingBasis.sales, percent: 10);

void main() {
  // Wednesday 25 November 2026, mid-morning.
  final now = DateTime(2026, 11, 25, 10);

  List<PlannedReminder> plan({
    List<Goal> goals = const [],
    TodaySavings? savings,
    DateTime? at,
  }) => planReminders(
    now: at ?? now,
    hour: 19,
    minute: 0,
    goals: goals,
    today: savings ?? today(),
  );

  group('a goal behind schedule', () {
    test('gets an evening reminder every day for a week', () {
      // By 25 Nov it should hold 240,000; it has 100,000.
      final reminders = plan(goals: [goal()]);

      expect(reminders.map((r) => r.at), [
        // 25 Nov to 1 Dec.
        for (var i = 0; i < 7; i++) DateTime(2026, 11, 25 + i, 19),
      ]);
      final first = reminders.first.message as GoalBehind;
      expect(first.goalName, 'Blender');
      // 500,000 left over the 36 days to 31 Dec.
      expect(first.dailyAmount, 13889);
      expect(first.overdue, isFalse);
      expect(first.route, '/goals/goal-1');
      // A day later there's a day less to do it in.
      expect((reminders[1].message as GoalBehind).dailyAmount, 14286);
    });

    test('skips today once the reminder time has passed', () {
      final reminders = plan(
        goals: [goal()],
        at: DateTime(2026, 11, 25, 19, 30),
      );

      expect(reminders, hasLength(6));
      expect(reminders.first.at, DateTime(2026, 11, 26, 19));
    });

    test('is not behind while within a day of the even pace', () {
      // Should hold 240,000; 235,000 is less than a day (10,000) short.
      final onTrack = goal(saved: 235000);
      expect(shortfallOn(onTrack, DateTime(2026, 11, 25)), isNull);

      // Tomorrow it should hold 250,000: more than a day behind.
      final reminders = plan(goals: [onTrack]);
      expect(reminders.first.at, DateTime(2026, 11, 26, 19));
    });

    test('a new goal is not behind on its first day', () {
      final fresh = goal(saved: 0, start: DateTime(2026, 11, 25));

      expect(shortfallOn(fresh, DateTime(2026, 11, 25)), isNull);
    });

    test('a fully saved goal is never behind', () {
      expect(plan(goals: [goal(saved: 600000)]), isEmpty);
    });

    test('the most important goal behind is the one mentioned', () {
      final reminders = plan(
        goals: [
          goal(id: 'a', name: 'Fridge', saved: 0, priority: 2),
          goal(id: 'b', name: 'Blender', priority: 5),
        ],
      );

      expect((reminders.first.message as GoalBehind).goalName, 'Blender');
    });

    test('among equally important goals, the furthest behind', () {
      final reminders = plan(
        goals: [
          goal(id: 'a', name: 'Fridge', saved: 200000),
          goal(id: 'b', name: 'Blender', saved: 0),
        ],
      );

      expect((reminders.first.message as GoalBehind).goalName, 'Blender');
    });

    test('past its target date, it asks for the rest', () {
      final late = goal(
        start: DateTime(2026, 10),
        targetDate: DateTime(2026, 11, 20),
      );

      final message = plan(goals: [late]).first.message as GoalBehind;

      expect(message.overdue, isTrue);
      expect(message.remaining, 500000);
      expect(message.dailyAmount, 500000);
    });
  });

  group('with a saving rule', () {
    test("today asks for what's left of the rule's target", () {
      final reminders = plan(
        goals: [goal()],
        savings: today(
          rule: tenPercentOfSales,
          sales: 120000,
          savedToday: 5000,
        ),
      );

      final first = reminders.first.message as SaveForRule;
      expect(first.remaining, 7000);
      expect(first.route, '/save?amount=7000');
      // Later days are about the goal again.
      expect(reminders[1].message, isA<GoalBehind>());
    });

    test("today is quiet once the rule's target is reached", () {
      final reminders = plan(
        goals: [goal()],
        savings: today(
          rule: tenPercentOfSales,
          sales: 120000,
          savedToday: 12000,
        ),
      );

      expect(reminders.first.at, DateTime(2026, 11, 26, 19));
    });

    test('asks for the sales when nothing else needs saying', () {
      final reminders = plan(savings: today(rule: tenPercentOfSales));

      expect(reminders, hasLength(7));
      expect(reminders.first.message, isA<RecordSales>());
      expect(reminders.first.message.route, '/business/new');
    });

    test("a day's loss under a profit rule asks for nothing that day", () {
      const rule = SavingRule(basis: SavingBasis.profit, percent: 20);
      final reminders = plan(
        savings: today(rule: rule, sales: 30000, expenses: 50000),
      );

      expect(reminders.first.at, DateTime(2026, 11, 26, 19));
      expect(reminders.first.message, const RecordSales(rule: rule));
    });
  });

  test('nothing to say: no goals behind and no rule', () {
    expect(plan(), isEmpty);
    // Ahead of the even pace all week.
    expect(plan(goals: [goal(saved: 300000)]), isEmpty);
  });

  test("when today's figures couldn't load, goals still count", () {
    final reminders = planReminders(
      now: now,
      hour: 19,
      minute: 0,
      goals: [goal()],
      today: null,
    );

    expect(reminders, hasLength(7));
  });

  group('notification text', () {
    setUpAll(initializeDateFormatting);

    test('in English', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final behind = reminderNotification(
        plan(goals: [goal()]).first,
        id: 0,
        l10n: l10n,
      );
      expect(behind.title, 'Blender is falling behind');
      expect(behind.body, 'Save TZS 13,889 a day to reach it by 31 Dec 2026.');
      expect(behind.route, '/goals/goal-1');

      final save = reminderNotification(
        plan(savings: today(rule: tenPercentOfSales, sales: 120000)).first,
        id: 0,
        l10n: l10n,
      );
      expect(save.title, 'Save TZS 12,000 today');
      expect(save.body, "That's 10% of today's sales, as your rule says.");
    });

    test('in Kiswahili', () {
      final l10n = lookupAppLocalizations(const Locale('sw'));
      final behind = reminderNotification(
        plan(goals: [goal()]).first,
        id: 0,
        l10n: l10n,
      );
      expect(behind.title, 'Lengo la Blender linabaki nyuma');
      expect(behind.body, startsWith('Weka TZS 13,889 kila siku'));
    });
  });

  test('only routes a reminder can open are followed', () {
    expect(isReminderRoute('/save?amount=7000'), isTrue);
    expect(isReminderRoute('/goals/0b9c-41aa'), isTrue);
    expect(isReminderRoute('/business/new'), isTrue);
    expect(isReminderRoute('/profile/delete'), isFalse);
    expect(isReminderRoute('/goals/x/edit'), isFalse);
  });
}
