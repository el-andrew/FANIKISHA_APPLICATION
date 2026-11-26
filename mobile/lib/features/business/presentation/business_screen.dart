import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/ui.dart';
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
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.l,
                    AppSpace.xs,
                    AppSpace.l,
                    AppSpace.l,
                  ),
                  children: [
                    SegmentedSwitch(
                      options: [
                        (BusinessPeriod.today, l10n.periodToday),
                        (BusinessPeriod.week, l10n.period7Days),
                        (BusinessPeriod.month, l10n.period30Days),
                      ],
                      selected: _period,
                      onChanged: (p) => setState(() => _period = p),
                    ),
                    const SizedBox(height: AppSpace.m),
                    summary.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpace.xxl),
                        child: LoadingView(),
                      ),
                      error: (error, _) => ErrorView(
                        error: error,
                        onRetry: () =>
                            ref.invalidate(businessSummaryProvider(_period)),
                      ),
                      data: (summary) => _SummaryView(summary: summary),
                    ),
                    const SizedBox(height: AppSpace.l),
                    SectionHeader(title: l10n.businessRecent),
                    entries.when(
                      loading: () => const LoadingView(),
                      error: (error, _) => ErrorView(
                        error: error,
                        onRetry: () => ref.invalidate(entryListProvider),
                      ),
                      data: (list) => AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.l,
                        ),
                        child: list.items.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpace.l,
                                ),
                                child: Text(
                                  l10n.businessEmpty,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final (i, entry)
                                      in list.items.indexed) ...[
                                    if (i > 0) const Divider(),
                                    _EntryRow(entry),
                                  ],
                                  if (list.loadingMore)
                                    const Padding(
                                      padding: EdgeInsets.all(AppSpace.l),
                                      child: LoadingView(),
                                    ),
                                  if (list.loadMoreError != null)
                                    TextButton(
                                      onPressed: () => ref
                                          .read(entryListProvider.notifier)
                                          .loadMore(),
                                      child: Text(l10n.actionRetry),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Record a sale or an expense: the form opens already set to it.
          Container(
            color: AppColors.ground,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.m,
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/business/new?type=sale'),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(l10n.entrySale),
                  ),
                ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/business/new?type=expense'),
                    icon: const Icon(Icons.remove, size: 20),
                    label: Text(l10n.entryExpense),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final loss = summary.profit < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loss ? l10n.businessLoss : l10n.businessProfit,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              Text(
                loss
                    ? '− ${formatTzs(summary.profit.abs())}'
                    : formatTzs(summary.profit),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: loss ? AppColors.attention : AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpace.m),
              Row(
                children: [
                  Expanded(
                    child: _Figure(
                      label: l10n.businessSales,
                      amount: summary.sales,
                      icon: Icons.south_west,
                      tone: StatusTone.positive,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: _Figure(
                      label: l10n.businessExpenses,
                      amount: summary.expenses,
                      icon: Icons.north_east,
                      tone: StatusTone.attention,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (summary.days.length > 1) ...[
          const SizedBox(height: AppSpace.m),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.businessEachDay,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    _LegendDot(
                      color: AppColors.deepGreen,
                      label: l10n.businessSales,
                    ),
                    const SizedBox(width: AppSpace.m),
                    _LegendDot(
                      color: AppColors.chartExpense,
                      label: l10n.businessExpenses,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.l),
                DailyChart(days: summary.days),
              ],
            ),
          ),
        ],
        if (summary.expenseCategories.isNotEmpty) ...[
          const SizedBox(height: AppSpace.l),
          SectionHeader(title: l10n.businessTopExpenses),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
            child: Column(
              children: [
                for (final (i, c)
                    in summary.expenseCategories.take(3).indexed) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.category ?? l10n.entryUncategorised,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          formatTzs(c.amount),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
    required this.icon,
    required this.tone,
  });

  final String label;
  final int amount;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (tone) {
      StatusTone.positive => (AppColors.positiveBg, AppColors.positive),
      StatusTone.attention => (AppColors.attentionBg, AppColors.attention),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpace.m),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: AppSpace.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: fg),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(formatTzs(amount), style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: AppSpace.xs),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
      ),
    ],
  );
}

class _EntryRow extends StatelessWidget {
  const _EntryRow(this.entry);

  final BusinessEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sale = entry.type == EntryType.sale;
    final details = [
      ?entry.note,
      formatDate(entry.occurredOn, context.localeName),
    ].join(' · ');

    return InkWell(
      onTap: () => context.push('/business/${entry.id}/edit'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
        child: Row(
          children: [
            Semantics(
              label: sale ? l10n.entrySale : l10n.entryExpense,
              child: RowIcon(
                icon: sale ? Icons.south_west : Icons.north_east,
                tone: sale ? StatusTone.positive : StatusTone.attention,
              ),
            ),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.category ??
                        (sale ? l10n.entrySale : l10n.entryUncategorised),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s),
            Text(
              '${sale ? '+' : '−'} ${formatTzs(entry.amount)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: sale ? AppColors.moneyIn : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
