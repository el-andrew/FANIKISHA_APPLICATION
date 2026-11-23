import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../data/savings_models.dart';

/// Rows showing how a deposit is shared: one per goal, then general savings.
class SplitList extends StatelessWidget {
  const SplitList({super.key, required this.split, this.dense = false});

  final DepositSplit split;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = [
      for (final a in split.allocations) (a.goalName, a.amount, false),
      if (split.unallocatedAmount > 0)
        (l10n.generalSavings, split.unallocatedAmount, true),
    ];
    return Column(
      children: [
        for (final (name, amount, general) in rows)
          Padding(
            padding: EdgeInsets.symmetric(vertical: dense ? 4 : 8),
            child: Row(
              children: [
                Icon(
                  general ? Icons.savings_outlined : Icons.flag_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(name)),
                Text(
                  formatTzs(amount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
