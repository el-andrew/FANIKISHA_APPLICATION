import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/async_views.dart';
import '../application/goals_providers.dart';
import '../data/goal.dart';
import 'goal_card.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-goal',
        onPressed: () => context.push('/goals/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.goalsNew),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<GoalStatus>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: GoalStatus.active,
                    label: Text(l10n.goalsFilterActive),
                  ),
                  ButtonSegment(
                    value: GoalStatus.completed,
                    label: Text(l10n.goalsFilterCompleted),
                  ),
                  ButtonSegment(
                    value: GoalStatus.archived,
                    label: Text(l10n.goalsFilterArchived),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
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
                child: items.isEmpty
                    ? ListView(
                        children: [
                          EmptyView(
                            icon: Icons.flag_outlined,
                            message: switch (_status) {
                              GoalStatus.active => l10n.goalsEmptyActive,
                              GoalStatus.completed => l10n.goalsEmptyCompleted,
                              GoalStatus.archived => l10n.goalsEmptyArchived,
                            },
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => GoalCard(goal: items[i]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
