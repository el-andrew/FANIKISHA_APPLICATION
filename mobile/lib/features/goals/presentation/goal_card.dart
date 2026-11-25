import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../data/goal.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Card(
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/goals/${goal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${goal.progressPercent.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 10,
                  semanticsLabel: goal.name,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.goalSavedOf(
                  formatTzs(goal.savedAmount),
                  formatTzs(goal.targetAmount),
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(_statusLine(l10n), style: muted),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLine(AppLocalizations l10n) => switch (goal.status) {
    GoalStatus.completed => l10n.goalStatusCompleted,
    GoalStatus.archived => l10n.goalStatusArchived,
    GoalStatus.active =>
      '${l10n.goalDailyTarget(formatTzs(goal.dailyTargetAmount))} · '
          '${l10n.goalDaysLeft(goal.daysLeft)}',
  };
}
