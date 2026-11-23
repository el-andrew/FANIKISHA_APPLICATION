import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/savings/application/savings_providers.dart';
import '../format/dates.dart';
import '../l10n/l10n.dart';
import '../offline_controller.dart';

/// Says the app is showing saved data because it is offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAt = ref.watch(offlineProvider);
    if (savedAt == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final local = savedAt.toLocal();
    final now = DateTime.now();
    final today = DateUtils.isSameDay(local, now);
    final message = today
        ? l10n.offlineSavedToday(
            DateFormat.Hm(context.localeName).format(local),
          )
        : l10n.offlineSavedEarlier(formatDateTime(savedAt, context.localeName));

    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
            TextButton(
              onPressed: () => refreshSavingsData(ref),
              child: Text(l10n.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}
