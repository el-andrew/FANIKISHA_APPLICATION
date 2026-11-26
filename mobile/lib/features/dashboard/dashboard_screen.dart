import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money.dart';
import '../../core/l10n/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/ui.dart';
import '../auth/application/auth_controller.dart';
import '../goals/application/goals_providers.dart';
import '../goals/data/goal.dart';
import '../goals/data/goal_pace.dart';
import '../reminders/reminder_widgets.dart';
import '../reminders/reminders.dart';
import '../savings/application/savings_providers.dart';
import '../savings/data/savings_models.dart';
import '../savings/presentation/activity_row.dart';
import 'today_card.dart';

/// Whether Home shows the balance or dots, remembered on the phone.
class BalanceHidden extends Notifier<bool> {
  static const _key = 'balance.hidden';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> toggle() async {
    state = !state;
    await ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

final balanceHiddenProvider = NotifierProvider<BalanceHidden, bool>(
  BalanceHidden.new,
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _goalsShown = 3;
  static const _activityShown = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final user = auth is SignedIn ? auth.user : null;
    final summary = ref.watch(summaryProvider);
    final goals = ref.watch(goalsProvider(GoalStatus.active));
    final activity = ref.watch(activityProvider);
    final today = ref.watch(clockProvider)();
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
      ref.refresh(activityProvider.future),
    ]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons over the green header.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(
                firstName: user?.firstName ?? '',
                businessName: user?.businessName,
                summary: summary.value,
              ),
              const _ActionsCard(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (summary.hasError && !summary.hasValue) ...[
                      ErrorView(
                        error: summary.error!,
                        onRetry: () => ref.invalidate(summaryProvider),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (user != null && user.needsPhoneVerification) ...[
                      const _VerifyPhoneCard(),
                      const SizedBox(height: 16),
                    ],
                    const TodayCard(),
                    const SizedBox(height: 16),
                    if (showTip) ...[
                      const ReminderTipCard(),
                      const SizedBox(height: 16),
                    ],
                    SectionHeader(
                      title: l10n.navGoals,
                      actionLabel: l10n.dashboardSeeAll,
                      onAction: () => context.go('/goals'),
                    ),
                    goals.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: LoadingView(),
                      ),
                      error: (error, _) => ErrorView(
                        error: error,
                        onRetry: () =>
                            ref.invalidate(goalsProvider(GoalStatus.active)),
                      ),
                      data: (items) => items.isEmpty
                          ? const _NoGoals()
                          : AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                children: [
                                  for (final (i, goal)
                                      in items.take(_goalsShown).indexed) ...[
                                    if (i > 0) const Divider(),
                                    _GoalRow(goal: goal, today: today),
                                  ],
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    SectionHeader(
                      title: l10n.homeRecentActivity,
                      actionLabel: l10n.navHistory,
                      onAction: () => context.push('/history'),
                    ),
                    activity.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: LoadingView(),
                      ),
                      error: (error, _) => ErrorView(
                        error: error,
                        onRetry: () => ref.invalidate(activityProvider),
                      ),
                      data: (list) => AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: list.items.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  l10n.homeNoActivity,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final (i, item)
                                      in list.items
                                          .take(_activityShown)
                                          .indexed) ...[
                                    if (i > 0) const Divider(),
                                    ActivityRow(activity: item),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The green top of Home: greeting and the total saved.
class _Header extends ConsumerWidget {
  const _Header({
    required this.firstName,
    required this.businessName,
    required this.summary,
  });

  final String firstName;
  final String? businessName;

  /// Null while loading.
  final SavingsSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hidden = ref.watch(balanceHiddenProvider);
    final summary = this.summary;
    final initial = firstName.isEmpty
        ? ''
        : firstName.characters.first.toUpperCase();

    return Container(
      color: AppColors.deepGreen,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        12,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  child: Text(
                    initial,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardGreeting(firstName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.onHeader,
                      ),
                    ),
                    if (businessName != null)
                      Text(
                        businessName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onHeaderMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.dashboardTotalSaved,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onHeaderMuted,
            ),
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  summary == null
                      ? '—'
                      : hidden
                      ? 'TZS ••••••'
                      : formatTzs(summary.balance),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.onHeader,
                  ),
                ),
              ),
              IconButton(
                tooltip: hidden ? l10n.balanceShow : l10n.balanceHide,
                color: AppColors.onHeaderMuted,
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    ref.read(balanceHiddenProvider.notifier).toggle(),
              ),
            ],
          ),
          if (summary != null && summary.unallocatedAmount > 0 && !hidden)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Material(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  // General savings can be moved into a goal or taken out.
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => _chooseAction(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.dashboardGeneralSavings(
                            formatTzs(summary.unallocatedAmount),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onHeader,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.onHeader,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseAction(BuildContext context) {
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
              leading: const Icon(Icons.north_east),
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
}

/// Save, Move, Withdraw, Record sale: overlapping the bottom of the header.
class _ActionsCard extends ConsumerWidget {
  const _ActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Stack(
      children: [
        // The header's green continues behind the top half of the card.
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.deepGreen,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1417251B),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: ActionCircle(
                      icon: Icons.add,
                      label: l10n.actionSave,
                      onTap: () => context.push('/save'),
                    ),
                  ),
                  Expanded(
                    child: ActionCircle(
                      icon: Icons.swap_horiz,
                      label: l10n.actionMove,
                      onTap: () => _chooseSource(context, ref),
                    ),
                  ),
                  Expanded(
                    child: ActionCircle(
                      icon: Icons.north_east,
                      label: l10n.actionWithdraw,
                      onTap: () => _chooseSource(context, ref, withdraw: true),
                    ),
                  ),
                  Expanded(
                    child: ActionCircle(
                      icon: Icons.receipt_long_outlined,
                      label: l10n.actionRecordSale,
                      onTap: () => context.push('/business/new'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Asks where the money comes from: general savings or a goal with money.
  Future<void> _chooseSource(
    BuildContext context,
    WidgetRef ref, {
    bool withdraw = false,
  }) async {
    final l10n = context.l10n;
    final summary = ref.read(summaryProvider).value;
    final repository = ref.read(goalsRepositoryProvider);
    final List<Goal> goals;
    try {
      // Completed goals can hold money too; Home only lists active ones.
      goals = [
        ...await repository.list(status: GoalStatus.active),
        ...await repository.list(status: GoalStatus.completed),
      ].where((g) => g.savedAmount > 0).toList();
    } catch (error) {
      if (context.mounted) showMessage(context, describeError(error, l10n));
      return;
    }
    if (!context.mounted) return;
    final general = summary?.unallocatedAmount ?? 0;
    if (goals.isEmpty && general == 0) {
      showMessage(context, l10n.nothingToMove);
      return;
    }
    final path = withdraw ? '/savings/withdraw' : '/savings/move';
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  withdraw ? l10n.chooseSourceWithdraw : l10n.chooseSourceMove,
                  style: Theme.of(sheet).textTheme.titleMedium,
                ),
              ),
              if (general > 0)
                ListTile(
                  leading: const RowIcon(icon: Icons.savings_outlined),
                  title: Text(l10n.generalSavings),
                  trailing: Text(formatTzs(general)),
                  onTap: () {
                    Navigator.pop(sheet);
                    context.push('$path?from=general');
                  },
                ),
              for (final goal in goals)
                ListTile(
                  leading: const RowIcon(icon: Icons.track_changes),
                  title: Text(goal.name),
                  trailing: Text(formatTzs(goal.savedAmount)),
                  onTap: () {
                    Navigator.pop(sheet);
                    context.push('$path?from=${goal.id}');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal, required this.today});

  final Goal goal;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final behind = shortfallOn(goal, today) != null;
    return InkWell(
      onTap: () => context.push('/goals/${goal.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ProgressRing(value: goal.progress),
                  Text(
                    '${goal.progressPercent.floor()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
            const SizedBox(width: 8),
            behind
                ? StatusBadge(
                    label: l10n.goalBehind,
                    tone: StatusTone.attention,
                    icon: Icons.schedule,
                  )
                : StatusBadge(
                    label: l10n.goalOnTrack,
                    tone: StatusTone.positive,
                    icon: Icons.check,
                  ),
          ],
        ),
      ),
    );
  }
}

class _NoGoals extends StatelessWidget {
  const _NoGoals();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dashboardNoGoalsTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.push('/goals/new'),
            child: Text(l10n.dashboardCreateGoal),
          ),
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
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/profile/verify-phone'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const RowIcon(icon: Icons.sms_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.verifyPhoneBannerTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
