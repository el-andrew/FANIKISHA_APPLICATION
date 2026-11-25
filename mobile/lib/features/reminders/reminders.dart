import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/l10n/l10n.dart';
import '../../core/locale_controller.dart';
import '../../core/providers.dart';
import '../auth/application/auth_controller.dart';
import '../goals/application/goals_providers.dart';
import '../goals/data/goal.dart';
import '../savings/application/savings_providers.dart';
import '../savings/data/savings_models.dart';
import 'reminder_planner.dart';
import 'reminder_scheduler.dart';

class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 19,
    this.minute = 0,
    this.tipDismissed = false,
  });

  final bool enabled;

  /// When in the evening, in the phone's time.
  final int hour;
  final int minute;

  /// The dashboard suggestion to turn reminders on was closed.
  final bool tipDismissed;

  String get time =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Reminder settings belong to the phone, so they're kept on it.
class ReminderSettingsController extends Notifier<ReminderSettings> {
  static const _enabledKey = 'reminders.enabled';
  static const _timeKey = 'reminders.minuteOfDay';
  static const _tipKey = 'reminders.tipDismissed';

  @override
  ReminderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final minuteOfDay = prefs.getInt(_timeKey) ?? 19 * 60;
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      hour: minuteOfDay ~/ 60,
      minute: minuteOfDay % 60,
      tipDismissed: prefs.getBool(_tipKey) ?? false,
    );
  }

  /// Asks for permission to notify; false if the user refused.
  Future<bool> turnOn() async {
    final allowed = await ref
        .read(reminderSchedulerProvider)
        .requestPermission();
    if (!allowed) return false;
    // Once chosen, the dashboard stops suggesting it, even if turned off.
    await _save(enabled: true, tipDismissed: true);
    return true;
  }

  Future<void> turnOff() => _save(enabled: false);

  Future<void> setTime(int hour, int minute) =>
      _save(minuteOfDay: hour * 60 + minute);

  Future<void> dismissTip() => _save(tipDismissed: true);

  Future<void> _save({
    bool? enabled,
    int? minuteOfDay,
    bool? tipDismissed,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (enabled != null) await prefs.setBool(_enabledKey, enabled);
    if (minuteOfDay != null) await prefs.setInt(_timeKey, minuteOfDay);
    if (tipDismissed != null) await prefs.setBool(_tipKey, tipDismissed);
    ref.invalidateSelf();
  }
}

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettings>(
      ReminderSettingsController.new,
    );

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => platformReminderScheduler(),
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Counts the times the app came back to the foreground, so the plan is
/// worked out again for the new day.
class _AppResumed extends Notifier<int> {
  @override
  int build() {
    final listener = AppLifecycleListener(onResume: () => state++);
    ref.onDispose(listener.dispose);
    return 0;
  }
}

final _appResumedProvider = NotifierProvider<_AppResumed, int>(_AppResumed.new);

/// Keeps the phone's scheduled reminders in step with the signed-in user's
/// goals, today's sales and the settings. Kept alive by the app.
final reminderSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(reminderSchedulerProvider);
  if (!scheduler.supported) return;

  void report(Object error, StackTrace stack) =>
      debugPrint('Reminders: $error\n$stack');

  final signedIn = ref.watch(currentUserIdProvider) != null;
  final settings = ref.watch(reminderSettingsProvider);
  if (!signedIn || !settings.enabled) {
    unawaited(scheduler.cancelAll().catchError(report));
    return;
  }

  ref.watch(_appResumedProvider);
  final goals = ref.watch(goalsProvider(GoalStatus.active)).value;
  final today = ref.watch(todaySavingsProvider);
  // Keep what is scheduled until the data is in.
  if (goals == null || (today.isLoading && !today.hasValue)) return;

  final l10n = _l10nFor(ref.watch(localeControllerProvider));
  final plan = planReminders(
    now: ref.watch(clockProvider)(),
    hour: settings.hour,
    minute: settings.minute,
    goals: goals,
    today: today.value,
  );
  unawaited(
    scheduler
        .replaceAll(
          [
            for (final (i, planned) in plan.indexed)
              reminderNotification(planned, id: i, l10n: l10n),
          ],
          channel: (
            name: l10n.reminderChannelName,
            description: l10n.reminderChannelDescription,
          ),
        )
        .catchError(report),
  );
});

AppLocalizations _l10nFor(Locale? chosen) {
  final code = (chosen ?? PlatformDispatcher.instance.locale).languageCode;
  final supported = AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == code,
  );
  return lookupAppLocalizations(Locale(supported ? code : 'en'));
}

/// [planned] as a notification in the user's language.
ScheduledReminder reminderNotification(
  PlannedReminder planned, {
  required int id,
  required AppLocalizations l10n,
}) {
  final message = planned.message;
  final (title, body) = switch (message) {
    SaveForRule(:final remaining, :final rule) => (
      l10n.reminderSaveTitle(formatTzs(remaining)),
      rule.basis == SavingBasis.sales
          ? l10n.reminderSaveBodySales('${rule.percent}')
          : l10n.reminderSaveBodyProfit('${rule.percent}'),
    ),
    GoalBehind(overdue: true, :final goalName, :final remaining) => (
      l10n.reminderOverdueTitle(goalName),
      l10n.reminderOverdueBody(formatTzs(remaining)),
    ),
    GoalBehind(:final goalName, :final dailyAmount, :final targetDate) => (
      l10n.reminderBehindTitle(goalName),
      l10n.reminderBehindBody(
        formatTzs(dailyAmount),
        formatDate(targetDate, l10n.localeName),
      ),
    ),
    RecordSales(:final rule) => (
      l10n.reminderRecordTitle,
      rule.basis == SavingBasis.sales
          ? l10n.reminderRecordBodySales('${rule.percent}')
          : l10n.reminderRecordBodyProfit('${rule.percent}'),
    ),
  };
  return ScheduledReminder(
    id: id,
    at: planned.at,
    title: title,
    body: body,
    route: message.route,
  );
}

/// Only screens a reminder can point to, in case a payload is ever stale.
bool isReminderRoute(String route) =>
    route.startsWith('/save?amount=') ||
    route == '/business/new' ||
    RegExp(r'^/goals/[\w-]+$').hasMatch(route);
