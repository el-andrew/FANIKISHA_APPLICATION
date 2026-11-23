import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/async_views.dart';
import '../application/savings_providers.dart';
import '../data/savings_models.dart';
import 'split_list.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(depositHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: history.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(depositHistoryProvider),
        ),
        data: (history) => RefreshIndicator(
          onRefresh: () => ref.refresh(depositHistoryProvider.future),
          child: history.items.isEmpty
              ? ListView(
                  children: [
                    EmptyView(
                      icon: Icons.receipt_long_outlined,
                      message: l10n.historyEmpty,
                    ),
                  ],
                )
              : NotificationListener<ScrollNotification>(
                  // Load the next page when the list is nearly scrolled through.
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 300) {
                      ref.read(depositHistoryProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: history.items.length + 1,
                    itemBuilder: (context, i) => i < history.items.length
                        ? _DepositTile(deposit: history.items[i])
                        : _Footer(history: history),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DepositTile extends StatelessWidget {
  const _DepositTile({required this.deposit});

  final Deposit deposit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = formatDateTime(deposit.createdAt, context.localeName);
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.savings_outlined,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        formatTzs(deposit.amount),
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(deposit.note == null ? when : '$when · ${deposit.note}'),
      childrenPadding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
      children: [SplitList(split: deposit, dense: true)],
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.history});

  final DepositHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.loadMoreError != null) {
      return Center(
        child: TextButton(
          onPressed: () => ref.read(depositHistoryProvider.notifier).loadMore(),
          child: Text(context.l10n.actionRetry),
        ),
      );
    }
    if (history.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }
}
