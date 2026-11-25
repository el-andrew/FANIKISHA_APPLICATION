import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// A notification ready to be scheduled, in the user's language.
@immutable
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.route,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// The screen a tap opens.
  final String route;

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body &&
      other.route == route;

  @override
  int get hashCode => Object.hash(id, at, title, body, route);

  @override
  String toString() => 'ScheduledReminder($at, "$title", $route)';
}

/// How reminders are listed in the phone's notification settings.
typedef ReminderChannel = ({String name, String description});

/// Schedules notifications on the phone itself: no server, no push service.
abstract class ReminderScheduler {
  /// False where the phone can't schedule notifications (desktop, tests).
  bool get supported;

  /// Asks to show notifications; true if they are allowed.
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with [reminders]. [channel] names
  /// them in the phone's notification settings.
  Future<void> replaceAll(
    List<ScheduledReminder> reminders, {
    required ReminderChannel channel,
  });

  Future<void> cancelAll();

  /// The route of the reminder that opened the app, if one did. Answers
  /// once; later calls return null.
  Future<String?> launchRoute();

  /// Routes of reminders tapped while the app is running.
  Stream<String> get taps;
}

/// For platforms without scheduled notifications.
class NoReminderScheduler implements ReminderScheduler {
  const NoReminderScheduler();

  @override
  bool get supported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(
    List<ScheduledReminder> reminders, {
    required ReminderChannel channel,
  }) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<String?> launchRoute() async => null;

  @override
  Stream<String> get taps => const Stream.empty();
}

ReminderScheduler platformReminderScheduler() =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS)
    ? LocalNotificationScheduler()
    : const NoReminderScheduler();

class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  Future<void>? _ready;

  /// What is scheduled now, so an unchanged plan costs nothing.
  List<ScheduledReminder>? _scheduled;
  ReminderChannel? _channel;

  Future<void> _init() => _ready ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          // Ask when the user turns reminders on, not at start-up.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final route = response.payload;
          if (route != null) _taps.add(route);
        },
      )
      .then((_) {});

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> replaceAll(
    List<ScheduledReminder> reminders, {
    required ReminderChannel channel,
  }) async {
    if (listEquals(_scheduled, reminders) && _channel == channel) return;
    await _init();
    await _plugin.cancelAll();
    _scheduled = reminders;
    _channel = channel;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'saving_reminders',
        channel.name,
        channelDescription: channel.description,
        icon: 'ic_notification',
      ),
      iOS: const DarwinNotificationDetails(),
    );
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        payload: reminder.route,
        // The exact moment, whatever the phone's time zone.
        scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
        notificationDetails: details,
        // Inexact: Android may deliver it up to an hour late (the app says
        // "around" the time). Exact alarms need a permission Google Play
        // keeps for alarm-clock and calendar apps.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (_scheduled != null && _scheduled!.isEmpty) return;
    await _init();
    await _plugin.cancelAll();
    _scheduled = const [];
  }

  bool _launchHandled = false;

  @override
  Future<String?> launchRoute() async {
    // Only once: signing out and in again mustn't reopen it.
    if (_launchHandled) return null;
    _launchHandled = true;
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Stream<String> get taps => _taps.stream;
}
