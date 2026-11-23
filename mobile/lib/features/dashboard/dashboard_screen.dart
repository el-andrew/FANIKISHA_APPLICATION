import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/async_views.dart';
import '../auth/application/auth_controller.dart';
import '../goals/application/goals_providers.dart';
import '../goals/data/goal.dart';
import '../goals/presentation/goal_card.dart';
import '../savings/application/savings_providers.dart';
import '../savings/data/savings_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _goalsShown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final user = auth is SignedIn ? auth.user : null;
    final summary = ref.watch(summaryProvider);
    final goals = ref.watch(goalsProvider(GoalStatus.active));

    Future<void> refresh() => Future.wait([
      ref.refresh(summaryProvider.future),
      ref.refresh(goalsProvider(GoalStatus.active).future),
    ]);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardGreeting(user?.firstName ?? ''),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (user?.businessName != null)
              Text(
                user!.businessName!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summary.when(
              loading: () => const _SummaryCard(summary: null),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(summaryProvider),
              ),
              data: (summary) => _SummaryCard(summary: summary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/save'),
              icon: const Icon(Icons.add),
              label: Text(l10n.dashboardSaveMoney),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dashboardActiveGoals,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/goals'),
                  child: Text(l10n.dashboardSeeAll),
                ),
              ],
            ),
            const SizedBox(height: 4),
            goals.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: LoadingView(),
              ),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(goalsProvider(GoalStatus.active)),
              ),
              data: (items) => items.isEmpty
                  ? EmptyView(
                      icon: Icons.flag_outlined,
                      title: l10n.dashboardNoGoalsTitle,
                      message: l10n.dashboardNoGoalsBody,
                      action: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                        ),
                        onPressed: () => context.push('/goals/new'),
                        child: Text(l10n.dashboardCreateGoal),
                      ),
                    )
                  : Column(
                      children: [
                        for (final goal in items.take(_goalsShown)) ...[
                          GoalCard(goal: goal),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  /// Null while loading.
  final SavingsSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final summary = this.summary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, const Color(0xFF43AF2A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTotalSaved,
            style: theme.textTheme.bodyLarge?.copyWith(color: onPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            summary == null ? '—' : formatTzs(summary.totalDeposited),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (summary != null) ...[
            Text(
              l10n.dashboardDepositCount(summary.depositCount),
              style: theme.textTheme.bodyMedium?.copyWith(color: onPrimary),
            ),
            if (summary.unallocatedAmount > 0)
              Text(
                l10n.dashboardGeneralSavings(
                  formatTzs(summary.unallocatedAmount),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(color: onPrimary),
              ),
          ],
        ],
      ),
    );
  }
}
