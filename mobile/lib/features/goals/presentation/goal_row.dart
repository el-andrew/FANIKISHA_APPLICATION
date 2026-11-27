import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/ui.dart';
import '../data/goal.dart';
import '../data/goal_pace.dart';

/// A goal in a list: progress ring, name, amounts and its status.
class GoalRow extends StatelessWidget {
  const GoalRow({super.key, required this.goal, required this.today});

  final Goal goal;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final behind =
        goal.status == GoalStatus.active && shortfallOn(goal, today) != null;
    return InkWell(
      onTap: () => context.push('/goals/${goal.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.m),
        child: Row(
          children: [
            SizedBox.square(
              dimension: AppSize.ring,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ProgressRing(value: goal.progress),
                  Text(
                    '${goal.progressPercent.floor()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    l10n.goalSavedOf(
                      formatTzs(goal.savedAmount),
                      formatTzs(goal.targetAmount),
                    ),
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
            switch (goal.status) {
              GoalStatus.completed => StatusBadge(
                label: l10n.goalStatusCompleted,
                tone: StatusTone.positive,
                icon: Icons.check,
              ),
              GoalStatus.archived => StatusBadge(
                label: l10n.goalStatusArchived,
                tone: StatusTone.attention,
                icon: Icons.archive_outlined,
              ),
              GoalStatus.active when behind => StatusBadge(
                label: l10n.goalBehind,
                tone: StatusTone.attention,
                icon: Icons.schedule,
              ),
              GoalStatus.active => StatusBadge(
                label: l10n.goalOnTrack,
                tone: StatusTone.positive,
                icon: Icons.check,
              ),
            },
          ],
        ),
      ),
    );
  }
}
