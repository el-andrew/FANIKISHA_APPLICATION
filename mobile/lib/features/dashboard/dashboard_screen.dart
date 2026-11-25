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
import '../reminders/reminder_widgets.dart';
import '../reminders/reminders.dart';
import '../savings/application/savings_providers.dart';
import '../savings/data/savings_models.dart';
import 'today_card.dart';

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
    final showTip = showReminderTip(
      supported: ref.watch(reminderSchedulerProvider).supported,
      settings: ref.watch(reminderSettingsProvider),
      hasActiveGoal: goals.value?.isNotEmpty ?? false,
      hasRule: ref.watch(todaySavingsProvider).value?.rule != null,
    );

    Future<void> refresh() => Future.wait([
      ref.refresh(summaryProvider.future),
      ref.refresh(goalsProvider(GoalStatus.active).future),
      ref.refresh(todaySavingsProvider.future),
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
            if (user != null && user.needsPhoneVerification) ...[
              const _VerifyPhoneCard(),
              const SizedBox(height: 16),
            ],
            summary.when(
              loading: () => const _SummaryCard(summary: null),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(summaryProvider),
              ),
              data: (summary) => _SummaryCard(summary: summary),
            ),
            const SizedBox(height: 16),
            const TodayCard(),
            const SizedBox(height: 16),
            if (showTip) ...[
              const ReminderTipCard(),
              const SizedBox(height: 16),
            ],
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
            summary == null ? '—' : formatTzs(summary.balance),
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
              InkWell(
                // General savings can be moved into a goal or taken out.
                onTap: () => _generalSavingsActions(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.dashboardGeneralSavings(
                          formatTzs(summary.unallocatedAmount),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onPrimary,
                          decoration: TextDecoration.underline,
                          decorationColor: onPrimary,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: onPrimary, size: 18),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Asks the user to confirm their phone number until they have.
class _VerifyPhoneCard extends StatelessWidget {
  const _VerifyPhoneCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sms_outlined, color: scheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.verifyPhoneBannerTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                      Text(
                        l10n.verifyPhoneBannerBody,
                        style: TextStyle(color: scheme.onTertiaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/profile/verify-phone'),
                child: Text(l10n.verifyPhoneAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _generalSavingsActions(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              l10n.generalSavings,
              style: Theme.of(sheet).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text(l10n.moveMoney),
            onTap: () {
              Navigator.pop(sheet);
              context.push('/savings/move?from=general');
            },
          ),
          ListTile(
            leading: const Icon(Icons.outbox_outlined),
            title: Text(l10n.withdrawMoney),
            onTap: () {
              Navigator.pop(sheet);
              context.push('/savings/withdraw?from=general');
            },
          ),
        ],
      ),
    ),
  );
}
