import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/ui.dart';
import '../../reminders/reminders.dart';
import '../application/goals_providers.dart';
import '../data/goal.dart';
import 'goal_row.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  GoalStatus _status = GoalStatus.active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final goals = ref.watch(goalsProvider(_status));
    final today = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.xs,
              AppSpace.l,
              AppSpace.m,
            ),
            child: SegmentedSwitch(
              options: [
                (GoalStatus.active, l10n.goalsFilterActive),
                (GoalStatus.completed, l10n.goalsFilterCompleted),
                (GoalStatus.archived, l10n.goalsFilterArchived),
              ],
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
            ),
          ),
          Expanded(
            child: goals.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(goalsProvider(_status)),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.refresh(goalsProvider(_status).future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.l,
                    0,
                    AppSpace.l,
                    AppSpace.l,
                  ),
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.l,
                      ),
                      child: items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpace.l,
                              ),
                              child: Text(
                                switch (_status) {
                                  GoalStatus.active => l10n.goalsEmptyActive,
                                  GoalStatus.completed =>
                                    l10n.goalsEmptyCompleted,
                                  GoalStatus.archived =>
                                    l10n.goalsEmptyArchived,
                                },
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            )
                          : Column(
                              children: [
                                for (final (i, goal) in items.indexed) ...[
                                  if (i > 0) const Divider(),
                                  GoalRow(goal: goal, today: today),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: AppColors.ground,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.m,
            ),
            child: FilledButton.icon(
              onPressed: () => context.push('/goals/new'),
              icon: const Icon(Icons.add, size: 20),
              label: Text(l10n.goalsNew),
            ),
          ),
        ],
      ),
    );
  }
}
