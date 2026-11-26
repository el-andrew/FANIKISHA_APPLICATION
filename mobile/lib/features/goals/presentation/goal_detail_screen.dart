import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/ui.dart';
import '../../reminders/reminders.dart';
import '../../savings/application/savings_providers.dart';
import '../../savings/data/savings_models.dart';
import '../../savings/presentation/activity_row.dart';
import '../application/goals_providers.dart';
import '../data/goal.dart';
import '../data/goal_pace.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  static const _activityShown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final goal = ref.watch(goalProvider(goalId));
    final loaded = goal.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(loaded?.name ?? ''),
        actions: [
          if (loaded != null && loaded.status != GoalStatus.archived) ...[
            IconButton(
              tooltip: l10n.goalEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/goals/$goalId/edit'),
            ),
            // Archiving is rare: kept out of reach of a stray tap.
            PopupMenuButton<void>(
              tooltip: l10n.actionMore,
              itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: () => _archive(context, ref, loaded),
                  child: Text(l10n.goalArchive),
                ),
              ],
            ),
          ],
        ],
      ),
      body: goal.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(goalProvider(goalId)),
        ),
        data: (goal) {
          final activity = ref.watch(activityProvider).value?.items ?? [];
          return _GoalDetails(
            goal: goal,
            today: ref.watch(clockProvider)(),
            activity: activity
                .where((a) => _involves(a, goal.id))
                .take(_activityShown)
                .toList(),
          );
        },
      ),
    );
  }

  static bool _involves(Activity activity, String goalId) => switch (activity) {
    DepositActivity(:final deposit) => deposit.allocations.any(
      (a) => a.goalId == goalId,
    ),
    final MovementActivity m =>
      m.from.goalId == goalId || m.to?.goalId == goalId,
  };

  Future<void> _archive(BuildContext context, WidgetRef ref, Goal goal) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.goalArchiveConfirmTitle),
        content: Text(l10n.goalArchiveConfirmBody(formatTzs(goal.savedAmount))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSize.buttonCompact),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.goalArchiveConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(goalsRepositoryProvider).archive(goal.id);
      refreshSavingsData(ref);
      if (context.mounted) context.pop();
    } catch (error) {
      if (context.mounted) showMessage(context, describeError(error, l10n));
    }
  }
}

class _GoalDetails extends StatelessWidget {
  const _GoalDetails({
    required this.goal,
    required this.today,
    required this.activity,
  });

  final Goal goal;
  final DateTime today;
  final List<Activity> activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final active = goal.status == GoalStatus.active;
    final shortfall = active ? shortfallOn(goal, today) : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.s,
        AppSpace.l,
        AppSpace.xl,
      ),
      children: [
        _ProgressCard(goal: goal, today: today, shortfall: shortfall),
        if (active) ...[
          const SizedBox(height: AppSpace.m),
          _PaceCard(goal: goal),
        ],
        const SizedBox(height: AppSpace.m),
        _Actions(goal: goal),
        if (activity.isNotEmpty) ...[
          const SizedBox(height: AppSpace.l),
          SectionHeader(title: l10n.homeRecentActivity),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
            child: Column(
              children: [
                for (final (i, item) in activity.indexed) ...[
                  if (i > 0) const Divider(),
                  ActivityRow(activity: item, forGoalId: goal.id),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.l),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
          child: Column(
            children: [
              _DetailRow(
                l10n.goalDetailTargetDate,
                formatDate(goal.targetDate, context.localeName),
              ),
              const Divider(),
              _DetailRow(
                l10n.goalDetailPriority,
                priorityLabel(goal.priority, l10n),
              ),
              if (goal.category != null) ...[
                const Divider(),
                _DetailRow(l10n.goalDetailCategory, goal.category!),
              ],
            ],
          ),
        ),
        if (!active && goal.savedAmount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.m),
            child: Text(
              l10n.goalLeft(formatTzs(goal.savedAmount)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Saved so far, against the target and against an even pace.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.goal,
    required this.today,
    required this.shortfall,
  });

  final Goal goal;
  final DateTime today;

  /// How far behind an even pace, or null when on track (or not active).
  final int? shortfall;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final active = goal.status == GoalStatus.active;
    final expected = active ? expectedProgressOn(goal, today) : null;
    final caption = theme.textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final behind = shortfall;

    final badge = switch (goal.status) {
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
      GoalStatus.active when behind != null => StatusBadge(
        label: l10n.goalBehind,
        tone: StatusTone.attention,
        icon: Icons.schedule,
      ),
      GoalStatus.active => StatusBadge(
        label: l10n.goalOnTrack,
        tone: StatusTone.positive,
        icon: Icons.check,
      ),
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.l + AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.goalDetailSaved,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      formatTzs(goal.savedAmount),
                      style: theme.textTheme.headlineMedium,
                    ),
                    Text(
                      l10n.todayOfTarget(formatTzs(goal.targetAmount)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              badge,
            ],
          ),
          const SizedBox(height: AppSpace.l),
          ProgressBar(value: goal.progress, marker: expected, height: 10),
          const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.goalPercentSaved('${goal.progressPercent.floor()}'),
                  style: caption,
                ),
              ),
              if (expected != null)
                Text(
                  l10n.goalShouldBe('${(expected * 100).floor()}'),
                  style: caption,
                ),
            ],
          ),
          if (behind != null) ...[
            const SizedBox(height: AppSpace.m),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.m,
                vertical: AppSpace.s,
              ),
              decoration: BoxDecoration(
                color: AppColors.attentionBg,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Text(
                l10n.goalBehindBy(formatTzs(behind)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.attention,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What it takes to finish on time.
class _PaceCard extends StatelessWidget {
  const _PaceCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final caption = theme.textTheme.bodySmall?.copyWith(color: AppColors.muted);
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.goalToFinish, style: caption),
                Text(
                  l10n.goalPerDay(formatTzs(goal.dailyTargetAmount)),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${goal.daysLeft}', style: theme.textTheme.titleMedium),
              Text(l10n.goalDaysLeftLabel(goal.daysLeft), style: caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasMoney = goal.savedAmount > 0;
    const compact = Size(0, AppSize.button);
    // Three buttons share one row: less side padding leaves room for words.
    const padding = EdgeInsets.symmetric(horizontal: AppSpace.s);
    final buttons = <Widget>[
      if (goal.status == GoalStatus.active)
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: compact, padding: padding),
          onPressed: () => context.push('/save'),
          icon: const Icon(Icons.add, size: 20),
          label: Text(l10n.actionSave),
        ),
      if (hasMoney) ...[
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: compact,
            padding: padding,
          ),
          onPressed: () => context.push('/savings/move?from=${goal.id}'),
          icon: const Icon(Icons.swap_horiz, size: 20),
          label: Text(l10n.actionMove),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: compact,
            padding: padding,
          ),
          onPressed: () => context.push('/savings/withdraw?from=${goal.id}'),
          icon: const Icon(Icons.north_east, size: 20),
          label: Text(l10n.actionWithdraw),
        ),
      ],
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (final (i, button) in buttons.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpace.s),
          Expanded(child: button),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.m + 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
