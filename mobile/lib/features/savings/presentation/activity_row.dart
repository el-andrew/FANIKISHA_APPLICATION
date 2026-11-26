import 'package:flutter/material.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui.dart';
import '../data/savings_models.dart';

/// One line of savings activity: a deposit, a transfer or a withdrawal.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.activity, this.onTap});

  final Activity activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String place(MoneyPlace p) => p.goalName ?? l10n.generalSavings;

    final (
      IconData icon,
      StatusTone tone,
      String title,
      String detail,
      String amount,
      Color amountColor,
    ) = switch (activity) {
      DepositActivity(:final deposit) => (
        Icons.add,
        StatusTone.positive,
        l10n.activitySaved,
        [
          for (final a in deposit.allocations) a.goalName,
          if (deposit.unallocatedAmount > 0) l10n.generalSavings,
        ].join(', '),
        '+ ${formatTzs(deposit.amount)}',
        AppColors.moneyIn,
      ),
      final MovementActivity m when m.isTransfer => (
        Icons.swap_horiz,
        StatusTone.positive,
        l10n.activityTransfer(place(m.from), place(m.to!)),
        m.note ?? '',
        formatTzs(m.amount),
        AppColors.ink,
      ),
      final MovementActivity m => (
        Icons.north_east,
        StatusTone.attention,
        l10n.activityWithdrawal(place(m.from)),
        m.note ?? '',
        '− ${formatTzs(m.amount)}',
        AppColors.ink,
      ),
    };
    final when = formatDateTime(switch (activity) {
      DepositActivity(:final deposit) => deposit.createdAt,
      final MovementActivity m => m.createdAt,
    }, context.localeName);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            RowIcon(icon: icon, tone: tone),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    [when, if (detail.isNotEmpty) detail].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
