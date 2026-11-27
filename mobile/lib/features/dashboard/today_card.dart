import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ui.dart';
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
    return AppCard(
      child: rule == null ? const _SetUpRule() : _Target(today, rule),
    );
  }
}

class _SetUpRule extends StatelessWidget {
  const _SetUpRule();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        const RowIcon(icon: Icons.percent),
        const SizedBox(width: AppSpace.m),
        Expanded(
          child: Text(
            l10n.ruleSetupTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(width: AppSpace.s),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSize.buttonCompact),
          ),
          onPressed: () => context.push('/savings/rule'),
          child: Text(l10n.ruleSetupAction),
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
    final muted = theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted);
    final chip = rule.basis == SavingBasis.sales
        ? l10n.todayChipSales('${rule.percent}')
        : l10n.todayChipProfit('${rule.percent}');

    final List<Widget> body;
    if (today.sales == 0) {
      body = [
        Text(l10n.todayNoSales, style: muted),
        const SizedBox(height: AppSpace.m),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSize.buttonCompact),
          ),
          onPressed: () => context.push('/business/new'),
          child: Text(l10n.todayRecordSales),
        ),
      ];
    } else if (today.target == 0) {
      body = [Text(l10n.todayNoProfit, style: muted)];
    } else {
      final reached = today.remaining == 0;
      body = [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          children: [
            Text(
              formatTzs(today.savedToday),
              style: theme.textTheme.headlineSmall,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Text(
                // "TZS 45,000 of TZS 12,000" would read like a mistake.
                reached
                    ? l10n.todayTargetWas(formatTzs(today.target))
                    : l10n.todayOfTarget(formatTzs(today.target)),
                style: muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s),
        ProgressBar(value: today.savedToday / today.target),
        const SizedBox(height: AppSpace.m),
        if (reached)
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(
              label: l10n.todayReached,
              tone: StatusTone.positive,
              icon: Icons.check,
            ),
          )
        else
          FilledButton(
            onPressed: () => context.push('/save?amount=${today.remaining}'),
            child: Text(l10n.depositSubmit(formatTzs(today.remaining))),
          ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.todayTitle, style: theme.textTheme.titleMedium),
            ),
            // The rule, as a chip that opens it for editing.
            Tooltip(
              message: l10n.ruleEdit,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () => context.push('/savings/rule'),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.m - 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ground,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(chip, style: theme.textTheme.labelMedium),
                      const SizedBox(width: AppSpace.xs),
                      const Icon(Icons.tune, size: 14, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.m),
        ...body,
      ],
    );
  }
}
