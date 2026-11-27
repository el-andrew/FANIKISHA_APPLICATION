import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/ui.dart';
import '../../reminders/reminders.dart';
import '../application/savings_providers.dart';
import '../data/savings_models.dart';
import 'activity_row.dart';
import 'split_list.dart';

/// Every deposit, withdrawal and transfer, newest first, grouped by day.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activity = ref.watch(activityProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: activity.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(activityProvider),
        ),
        data: (list) {
          final days = _byDay(list.items);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(activityProvider.future),
            child: NotificationListener<ScrollNotification>(
              // Load the next page when the list is nearly scrolled through.
              onNotification: (n) {
                if (n.metrics.extentAfter < 300) {
                  ref.read(activityProvider.notifier).loadMore();
                }
                return false;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.xs,
                  AppSpace.l,
                  AppSpace.xl,
                ),
                children: [
                  if (days.isEmpty)
                    AppCard(
                      child: Text(
                        l10n.homeNoActivity,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  for (final (i, (day, items)) in days.indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpace.l),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.xs,
                        0,
                        AppSpace.xs,
                        AppSpace.s,
                      ),
                      child: Semantics(
                        header: true,
                        child: Text(
                          _dayLabel(day, now, l10n, context.localeName),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ),
                    ),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.l,
                      ),
                      child: Column(
                        children: [
                          for (final (j, item) in items.indexed) ...[
                            if (j > 0) const Divider(),
                            ActivityRow(
                              activity: item,
                              onTap: item is DepositActivity
                                  ? () => _showSplit(context, item.deposit)
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  _Footer(list: list),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Items grouped by their local calendar day, keeping the newest-first
  /// order.
  static List<(DateTime, List<Activity>)> _byDay(List<Activity> items) {
    final days = <(DateTime, List<Activity>)>[];
    for (final item in items) {
      final at = switch (item) {
        DepositActivity(:final deposit) => deposit.createdAt,
        final MovementActivity m => m.createdAt,
      }.toLocal();
      final day = DateTime(at.year, at.month, at.day);
      if (days.isEmpty || days.last.$1 != day) {
        days.add((day, [item]));
      } else {
        days.last.$2.add(item);
      }
    }
    return days;
  }

  static String _dayLabel(
    DateTime day,
    DateTime now,
    AppLocalizations l10n,
    String locale,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final age = today.difference(day).inDays;
    return switch (age) {
      0 => l10n.periodToday,
      1 => l10n.historyYesterday,
      _ => formatDate(day, locale),
    };
  }

  /// How a deposit was shared between goals.
  static Future<void> _showSplit(BuildContext context, Deposit deposit) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              0,
              AppSpace.l,
              AppSpace.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '+ ${formatTzs(deposit.amount)}',
                  style: Theme.of(sheet).textTheme.headlineSmall,
                ),
                Text(
                  [
                    formatDateTime(deposit.createdAt, sheet.localeName),
                    ?deposit.note,
                  ].join(' · '),
                  style: Theme.of(
                    sheet,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpace.m),
                SplitList(split: deposit),
              ],
            ),
          ),
        ),
      );
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.list});

  final ActivityList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (list.loadMoreError != null) {
      return Center(
        child: TextButton(
          onPressed: () => ref.read(activityProvider.notifier).loadMore(),
          child: Text(context.l10n.actionRetry),
        ),
      );
    }
    if (list.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpace.l),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }
}
