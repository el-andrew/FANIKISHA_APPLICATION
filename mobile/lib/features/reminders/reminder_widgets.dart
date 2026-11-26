import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/ui.dart';
import 'reminders.dart';

/// Asks for notification permission and turns reminders on, saying so.
Future<void> turnOnReminders(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final controller = ref.read(reminderSettingsProvider.notifier);
  final allowed = await controller.turnOn();
  if (!context.mounted) return;
  showMessage(
    context,
    allowed
        ? l10n.remindersOnMessage(ref.read(reminderSettingsProvider).time)
        : l10n.remindersBlocked,
  );
}

/// The reminder switch and time, for the profile screen. Nothing on phones
/// (or desktops) that can't schedule notifications.
class ReminderSettingsTiles extends ConsumerWidget {
  const ReminderSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(reminderSchedulerProvider).supported) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final settings = ref.watch(reminderSettingsProvider);
    final controller = ref.read(reminderSettingsProvider.notifier);

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(l10n.remindersTitle),
          subtitle: Text(
            settings.enabled
                ? l10n.remindersOnSubtitle(settings.time)
                : l10n.remindersOffSubtitle,
          ),
          value: settings.enabled,
          onChanged: (on) =>
              on ? turnOnReminders(context, ref) : controller.turnOff(),
        ),
        if (settings.enabled)
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l10n.remindersTime),
            trailing: Text(
              settings.time,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: settings.hour,
                  minute: settings.minute,
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (picked != null) {
                await controller.setTime(picked.hour, picked.minute);
              }
            },
          ),
      ],
    );
  }
}

/// A one-time suggestion on the dashboard to turn reminders on.
class ReminderTipCard extends ConsumerWidget {
  const ReminderTipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        children: [
          const RowIcon(icon: Icons.notifications_active_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.remindersTipTitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => turnOnReminders(context, ref),
            child: Text(l10n.remindersTurnOn),
          ),
          IconButton(
            tooltip: l10n.actionNotNow,
            icon: const Icon(Icons.close, color: AppColors.muted),
            onPressed: () =>
                ref.read(reminderSettingsProvider.notifier).dismissTip(),
          ),
        ],
      ),
    );
  }
}

/// Whether the dashboard should suggest reminders: they'd have something to
/// say (an active goal or a saving rule) and the user hasn't decided yet.
bool showReminderTip({
  required bool supported,
  required ReminderSettings settings,
  required bool hasActiveGoal,
  required bool hasRule,
}) =>
    supported &&
    !settings.enabled &&
    !settings.tipDismissed &&
    (hasActiveGoal || hasRule);
