import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/l10n/l10n.dart';
import '../savings/application/savings_providers.dart';
import '../savings/data/savings_models.dart';

/// Today's saving target from the saving rule, or an invitation to set one.
class TodayCard extends ConsumerWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaySavingsProvider).value;
    // Errors and loading are shown by the rest of the dashboard.
    if (today == null) return const SizedBox.shrink();
    final rule = today.rule;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: rule == null ? const _SetUpRule() : _Target(today, rule),
      ),
    );
  }
}

class _SetUpRule extends StatelessWidget {
  const _SetUpRule();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.percent, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.ruleSetupTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(l10n.ruleSetupBody, style: theme.textTheme.bodyMedium),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/savings/rule'),
            child: Text(l10n.ruleSetupAction),
          ),
        ),
      ],
    );
  }
}

class _Target extends StatelessWidget {
  const _Target(this.today, this.rule);

  final TodaySavings today;
  final SavingRule rule;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final sales = rule.basis == SavingBasis.sales;

    final Widget body;
    final Widget? action;
    if (today.sales == 0) {
      body = Text(l10n.todayNoSales, style: muted);
      action = TextButton(
        onPressed: () => context.push('/business/new'),
        child: Text(l10n.todayRecordSales),
      );
    } else if (today.target == 0) {
      body = Text(l10n.todayNoProfit, style: muted);
      action = null;
    } else {
      final reached = today.remaining == 0;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatTzs(today.target),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (today.savedToday / today.target).clamp(0, 1),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reached
                ? l10n.todayReached
                : l10n.todaySavedOf(
                    formatTzs(today.savedToday),
                    formatTzs(today.target),
                  ),
            style: muted,
          ),
        ],
      );
      action = reached
          ? null
          : FilledButton.tonal(
              onPressed: () => context.push('/save?amount=${today.remaining}'),
              child: Text(l10n.depositSubmit(formatTzs(today.remaining))),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.todayTitle, style: theme.textTheme.titleSmall),
                  Text(
                    sales
                        ? l10n.todayRuleSales(
                            rule.percent,
                            formatTzs(today.sales),
                          )
                        : l10n.todayRuleProfit(
                            rule.percent,
                            formatTzs(today.profit),
                          ),
                    style: muted,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.ruleEdit,
              icon: const Icon(Icons.tune),
              onPressed: () => context.push('/savings/rule'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.only(right: 8), child: body),
        if (action != null)
          Align(alignment: Alignment.centerRight, child: action),
      ],
    );
  }
}
