import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/async_views.dart';
import '../application/business_providers.dart';
import '../data/business_models.dart';
import 'daily_chart.dart';

/// Sales, expenses and profit for a period, and the entries behind them.
class BusinessScreen extends ConsumerStatefulWidget {
  const BusinessScreen({super.key});

  @override
  ConsumerState<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends ConsumerState<BusinessScreen> {
  BusinessPeriod _period = BusinessPeriod.today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = ref.watch(businessSummaryProvider(_period));
    final entries = ref.watch(entryListProvider);

    Future<void> refresh() => Future.wait([
      ref.refresh(businessSummaryProvider(_period).future),
      ref.refresh(entryListProvider.future),
    ]);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.businessTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-entry',
        onPressed: () => context.push('/business/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.businessAdd),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: NotificationListener<ScrollNotification>(
          // Load more entries when the list is nearly scrolled through.
          onNotification: (n) {
            if (n.metrics.extentAfter < 300) {
              ref.read(entryListProvider.notifier).loadMore();
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              SegmentedButton<BusinessPeriod>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: BusinessPeriod.today,
                    label: Text(l10n.periodToday),
                  ),
                  ButtonSegment(
                    value: BusinessPeriod.week,
                    label: Text(l10n.period7Days),
                  ),
                  ButtonSegment(
                    value: BusinessPeriod.month,
                    label: Text(l10n.period30Days),
                  ),
                ],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
              const SizedBox(height: 16),
              summary.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: LoadingView(),
                ),
                error: (error, _) => ErrorView(
                  error: error,
                  onRetry: () =>
                      ref.invalidate(businessSummaryProvider(_period)),
                ),
                data: (summary) => _SummaryView(summary: summary),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.businessRecent,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              ...entries.when(
                loading: () => [const LoadingView()],
                error: (error, _) => [
                  ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(entryListProvider),
                  ),
                ],
                data: (list) => list.items.isEmpty
                    ? [
                        EmptyView(
                          icon: Icons.point_of_sale_outlined,
                          message: l10n.businessEmpty,
                        ),
                      ]
                    : [
                        for (final entry in list.items) _EntryTile(entry),
                        if (list.loadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: LoadingView(),
                          ),
                        if (list.loadMoreError != null)
                          Center(
                            child: TextButton(
                              onPressed: () => ref
                                  .read(entryListProvider.notifier)
                                  .loadMore(),
                              child: Text(l10n.actionRetry),
                            ),
                          ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.summary});

  final BusinessSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loss = summary.profit < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: scheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loss ? l10n.businessLoss : l10n.businessProfit,
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  formatTzs(summary.profit.abs()),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: loss ? scheme.error : scheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Figure(
                        label: l10n.businessSales,
                        amount: summary.sales,
                        color: scheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _Figure(
                        label: l10n.businessExpenses,
                        amount: summary.expenses,
                        color: scheme.tertiary,
                      ),
                    ),
                  ],
                ),
                if (summary.days.length > 1) ...[
                  const SizedBox(height: 16),
                  DailyChart(days: summary.days),
                ],
              ],
            ),
          ),
        ),
        if (summary.expenseCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.businessTopExpenses, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final c in summary.expenseCategories.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.trending_down, color: scheme.tertiary),
              title: Text(c.category ?? l10n.entryUncategorised),
              trailing: Text(
                formatTzs(c.amount),
                style: theme.textTheme.titleSmall,
              ),
            ),
        ],
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
        Text(formatTzs(amount), style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile(this.entry);

  final BusinessEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sale = entry.type == EntryType.sale;
    final details = [
      entry.category ?? (sale ? l10n.entrySale : l10n.entryUncategorised),
      ?entry.note,
      formatDate(entry.occurredOn, context.localeName),
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push('/business/${entry.id}/edit'),
      leading: CircleAvatar(
        backgroundColor: sale
            ? scheme.primaryContainer
            : scheme.tertiaryContainer,
        child: Icon(
          sale ? Icons.south_west : Icons.north_east,
          color: sale ? scheme.onPrimaryContainer : scheme.onTertiaryContainer,
          semanticLabel: sale ? l10n.entrySale : l10n.entryExpense,
        ),
      ),
      title: Text(
        '${sale ? '+' : '−'} ${formatTzs(entry.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: sale ? scheme.primary : null,
        ),
      ),
      subtitle: Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
