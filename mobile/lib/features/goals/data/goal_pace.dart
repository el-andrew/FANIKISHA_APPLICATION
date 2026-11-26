import 'dart:math';

import 'goal.dart';

/// Whether a goal is keeping pace: saving evenly from its start date to its
/// target date. Used by Home, the goal page and reminders, so they agree.

/// The share (0 to 1) of [goal]'s target that an even pace would have saved
/// by [day].
double expectedProgressOn(Goal goal, DateTime day) {
  final totalDays = max(1, daysBetween(goal.startDate, goal.targetDate));
  final elapsed = daysBetween(goal.startDate, day).clamp(0, totalDays);
  return elapsed / totalDays;
}

/// How far [goal] is behind on [day], or null if it's on track.
///
/// A goal only counts as behind once it's more than a day's saving short, so
/// being a few shillings under doesn't set off a reminder.
int? shortfallOn(Goal goal, DateTime day) {
  final remaining = goal.targetAmount - goal.savedAmount;
  if (remaining <= 0) return null;
  final totalDays = max(1, daysBetween(goal.startDate, goal.targetDate));
  final elapsed = daysBetween(goal.startDate, day).clamp(0, totalDays);
  final expected = goal.targetAmount * elapsed ~/ totalDays;
  final shortfall = expected - goal.savedAmount;
  final perDay = (goal.targetAmount / totalDays).ceil();
  return shortfall > perDay ? shortfall : null;
}

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
