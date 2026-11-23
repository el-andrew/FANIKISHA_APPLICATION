import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_views.dart';
import '../../savings/application/savings_providers.dart';
import '../application/goals_providers.dart';
import '../data/goal.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(goalProvider(goalId));
    final loaded = goal.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(loaded?.name ?? ''),
        actions: [
          if (loaded != null && loaded.status != GoalStatus.archived) ...[
            IconButton(
              tooltip: context.l10n.goalEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/goals/$goalId/edit'),
            ),
            IconButton(
              tooltip: context.l10n.goalArchive,
              icon: const Icon(Icons.archive_outlined),
              onPressed: () => _archive(context, ref, loaded),
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
        data: (goal) => _GoalDetails(goal: goal),
      ),
    );
  }

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
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
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
  const _GoalDetails({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: SizedBox.square(
            dimension: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: goal.progress,
                  strokeWidth: 14,
                  backgroundColor: scheme.surfaceContainerHighest,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${goal.progressPercent.toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                      if (goal.status != GoalStatus.active)
                        Text(
                          goal.status == GoalStatus.completed
                              ? l10n.goalStatusCompleted
                              : l10n.goalStatusArchived,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: scheme.surfaceContainerLow,
          child: Column(
            children: [
              _Row(l10n.goalDetailSaved, formatTzs(goal.savedAmount)),
              _Row(l10n.goalDetailTarget, formatTzs(goal.targetAmount)),
              _Row(l10n.goalDetailRemaining, formatTzs(goal.remainingAmount)),
              if (goal.status == GoalStatus.active)
                _Row(
                  l10n.goalDetailDailyTarget,
                  formatTzs(goal.dailyTargetAmount),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: scheme.surfaceContainerLow,
          child: Column(
            children: [
              _Row(
                l10n.goalDetailTargetDate,
                formatDate(goal.targetDate, context.localeName),
                trailing: goal.status == GoalStatus.active
                    ? l10n.goalDaysLeft(goal.daysLeft)
                    : null,
              ),
              _Row(l10n.goalDetailPriority, priorityLabel(goal.priority, l10n)),
              if (goal.category != null)
                _Row(l10n.goalDetailCategory, goal.category!),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.trailing});

  final String label;
  final String value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value, style: theme.textTheme.titleSmall),
          if (trailing != null)
            Text(trailing!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
