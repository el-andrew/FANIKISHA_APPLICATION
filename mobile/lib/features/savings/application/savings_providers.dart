import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../goals/application/goals_providers.dart';
import '../data/savings_models.dart';

final summaryProvider = FutureProvider.autoDispose<SavingsSummary>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(savingsRepositoryProvider).summary();
});

final todaySavingsProvider = FutureProvider.autoDispose<TodaySavings>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(savingsRepositoryProvider).today();
});

class ActivityList {
  const ActivityList({
    required this.items,
    required this.nextCursor,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<Activity> items;
  final String? nextCursor;
  final bool loadingMore;
  final Object? loadMoreError;

  bool get hasMore => nextCursor != null;
}

/// Savings history (deposits, withdrawals, transfers), newest first, loaded a
/// page at a time.
class ActivityController extends AsyncNotifier<ActivityList> {
  @override
  Future<ActivityList> build() async {
    ref.watch(currentUserIdProvider);
    final page = await ref.watch(savingsRepositoryProvider).activity();
    return ActivityList(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      ActivityList(
        items: current.items,
        nextCursor: current.nextCursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(savingsRepositoryProvider)
          .activity(cursor: current.nextCursor);
      if (!ref.mounted) return;
      state = AsyncData(
        ActivityList(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = AsyncData(
        ActivityList(
          items: current.items,
          nextCursor: current.nextCursor,
          loadMoreError: error,
        ),
      );
    }
  }
}

final activityProvider =
    AsyncNotifierProvider.autoDispose<ActivityController, ActivityList>(
      ActivityController.new,
    );

/// After money moves or a goal changes, everything that shows totals reloads.
void refreshSavingsData(WidgetRef ref) {
  ref
    ..invalidate(summaryProvider)
    ..invalidate(todaySavingsProvider)
    ..invalidate(goalsProvider)
    ..invalidate(goalProvider)
    ..invalidate(activityProvider);
}
