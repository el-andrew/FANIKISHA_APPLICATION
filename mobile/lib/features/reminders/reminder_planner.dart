import 'dart:math';

import '../goals/data/goal.dart';
import '../savings/data/savings_models.dart';

/// What a reminder says. Turned into text in the app's language by
/// `reminderText`.
sealed class ReminderMessage {
  const ReminderMessage();

  /// The screen a tap on the notification opens.
  String get route;
}

/// Today's saving rule target isn't met yet.
class SaveForRule extends ReminderMessage {
  const SaveForRule({required this.remaining, required this.rule});

  final int remaining;
  final SavingRule rule;

  @override
  String get route => '/save?amount=$remaining';

  @override
  bool operator ==(Object other) =>
      other is SaveForRule &&
      other.remaining == remaining &&
      other.rule.basis == rule.basis &&
      other.rule.percent == rule.percent;

  @override
  int get hashCode => Object.hash(remaining, rule.basis, rule.percent);
}

/// A goal has less in it than it should by now.
class GoalBehind extends ReminderMessage {
  const GoalBehind({
    required this.goalId,
    required this.goalName,
    required this.dailyAmount,
    required this.remaining,
    required this.targetDate,
    required this.overdue,
  });

  final String goalId;
  final String goalName;

  /// Saving this much a day from the reminder's day still finishes on time.
  final int dailyAmount;
  final int remaining;
  final DateTime targetDate;

  /// The target date has passed.
  final bool overdue;

  @override
  String get route => '/goals/$goalId';

  @override
  bool operator ==(Object other) =>
      other is GoalBehind &&
      other.goalId == goalId &&
      other.goalName == goalName &&
      other.dailyAmount == dailyAmount &&
      other.remaining == remaining &&
      other.targetDate == targetDate &&
      other.overdue == overdue;

  @override
  int get hashCode => Object.hash(
    goalId,
    goalName,
    dailyAmount,
    remaining,
    targetDate,
    overdue,
  );
}

/// A saving rule is set: record the day's sales so it can work.
class RecordSales extends ReminderMessage {
  const RecordSales({required this.rule});

  final SavingRule rule;

  @override
  String get route => '/business/new';

  @override
  bool operator ==(Object other) =>
      other is RecordSales &&
      other.rule.basis == rule.basis &&
      other.rule.percent == rule.percent;

  @override
  int get hashCode => Object.hash(rule.basis, rule.percent);
}

class PlannedReminder {
  const PlannedReminder({required this.at, required this.message});

  final DateTime at;
  final ReminderMessage message;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder && other.at == at && other.message == message;

  @override
  int get hashCode => Object.hash(at, message);

  @override
  String toString() => 'PlannedReminder($at, ${message.runtimeType})';
}

/// How many days ahead reminders are scheduled. Opening the app plans them
/// again, so someone who stops using it stops hearing from it after a week.
const reminderDays = 7;

/// At most one reminder a day, at [hour]:[minute], for the next
/// [reminderDays] days, from what the app last knew: the [goals] (active
/// ones) and [today]'s sales and saving rule (null if they couldn't load).
///
/// No money moves without the app being opened, and opening it plans again,
/// so later days assume nothing changes in between.
List<PlannedReminder> planReminders({
  required DateTime now,
  required int hour,
  required int minute,
  required List<Goal> goals,
  required TodaySavings? today,
}) {
  final rule = today?.rule;
  final todayDate = DateTime(now.year, now.month, now.day);
  final plan = <PlannedReminder>[];

  for (var offset = 0; offset < reminderDays; offset++) {
    final day = DateTime(
      todayDate.year,
      todayDate.month,
      todayDate.day + offset,
    );
    final at = DateTime(day.year, day.month, day.day, hour, minute);
    if (!at.isAfter(now)) continue;

    ReminderMessage? message;
    if (offset == 0 && today != null && rule != null && today.target > 0) {
      // Today's sales are in: the rule says exactly what to save, and once
      // that's done the day needs no reminder.
      if (today.remaining > 0) {
        message = SaveForRule(remaining: today.remaining, rule: rule);
      } else {
        continue;
      }
    }
    message ??= _mostBehind(goals, day);
    // Sales recorded today but no target (a loss, with a profit rule):
    // nothing to ask for.
    final salesRecorded = offset == 0 && (today?.sales ?? 0) > 0;
    if (message == null && rule != null && !salesRecorded) {
      message = RecordSales(rule: rule);
    }
    if (message != null) plan.add(PlannedReminder(at: at, message: message));
  }
  return plan;
}

/// The goal that is furthest behind on [day], most important first.
GoalBehind? _mostBehind(List<Goal> goals, DateTime day) {
  ({Goal goal, int shortfall})? worst;
  for (final goal in goals) {
    if (goal.status != GoalStatus.active) continue;
    final shortfall = shortfallOn(goal, day);
    if (shortfall == null) continue;
    final current = worst;
    if (current == null ||
        goal.priority > current.goal.priority ||
        (goal.priority == current.goal.priority &&
            shortfall > current.shortfall)) {
      worst = (goal: goal, shortfall: shortfall);
    }
  }
  final found = worst;
  if (found == null) return null;
  final goal = found.goal;
  final remaining = goal.targetAmount - goal.savedAmount;
  final daysLeft = max(1, _daysBetween(day, goal.targetDate));
  return GoalBehind(
    goalId: goal.id,
    goalName: goal.name,
    dailyAmount: (remaining / daysLeft).ceil(),
    remaining: remaining,
    targetDate: goal.targetDate,
    overdue: _daysBetween(day, goal.targetDate) < 0,
  );
}

/// How far [goal] is behind on [day], or null if it's on track.
///
/// On track means saving at an even pace from the start date to the target
/// date. A goal only counts as behind once it's more than a day's saving
/// short, so being a few shillings under doesn't set off a reminder.
int? shortfallOn(Goal goal, DateTime day) {
  final remaining = goal.targetAmount - goal.savedAmount;
  if (remaining <= 0) return null;
  final totalDays = max(1, _daysBetween(goal.startDate, goal.targetDate));
  final elapsed = _daysBetween(goal.startDate, day).clamp(0, totalDays);
  final expected = goal.targetAmount * elapsed ~/ totalDays;
  final shortfall = expected - goal.savedAmount;
  final perDay = (goal.targetAmount / totalDays).ceil();
  return shortfall > perDay ? shortfall : null;
}

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
