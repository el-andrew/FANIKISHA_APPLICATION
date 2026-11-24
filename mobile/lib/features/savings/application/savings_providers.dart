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

class DepositHistory {
  const DepositHistory({
    required this.items,
    required this.nextCursor,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<Deposit> items;
  final String? nextCursor;
  final bool loadingMore;
  final Object? loadMoreError;

  bool get hasMore => nextCursor != null;
}

/// Deposit history, newest first, loaded a page at a time.
class DepositHistoryController extends AsyncNotifier<DepositHistory> {
  @override
  Future<DepositHistory> build() async {
    ref.watch(currentUserIdProvider);
    final page = await ref.watch(savingsRepositoryProvider).history();
    return DepositHistory(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      DepositHistory(
        items: current.items,
        nextCursor: current.nextCursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(savingsRepositoryProvider)
          .history(cursor: current.nextCursor);
      if (!ref.mounted) return;
      state = AsyncData(
        DepositHistory(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = AsyncData(
        DepositHistory(
          items: current.items,
          nextCursor: current.nextCursor,
          loadMoreError: error,
        ),
      );
    }
  }
}

final depositHistoryProvider =
    AsyncNotifierProvider.autoDispose<DepositHistoryController, DepositHistory>(
      DepositHistoryController.new,
    );

/// After money moves or a goal changes, everything that shows totals reloads.
void refreshSavingsData(WidgetRef ref) {
  ref
    ..invalidate(summaryProvider)
    ..invalidate(todaySavingsProvider)
    ..invalidate(goalsProvider)
    ..invalidate(goalProvider)
    ..invalidate(depositHistoryProvider);
}
