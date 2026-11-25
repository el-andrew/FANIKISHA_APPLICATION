import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../savings/application/savings_providers.dart';
import '../data/business_models.dart';
import '../data/business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(apiClientProvider)),
);

enum BusinessPeriod {
  today(1),
  week(7),
  month(30);

  const BusinessPeriod(this.days);
  final int days;
}

final businessSummaryProvider = FutureProvider.autoDispose
    .family<BusinessSummary, BusinessPeriod>((ref, period) {
      ref.watch(currentUserIdProvider);
      final today = DateUtils.dateOnly(DateTime.now());
      return ref
          .watch(businessRepositoryProvider)
          .summary(
            from: today.subtract(Duration(days: period.days - 1)),
            to: today,
            cacheName: period.name,
          );
    });

final entryProvider = FutureProvider.autoDispose.family<BusinessEntry, String>((
  ref,
  id,
) {
  ref.watch(currentUserIdProvider);
  return ref.watch(businessRepositoryProvider).get(id);
});

class EntryList {
  const EntryList({
    required this.items,
    required this.nextCursor,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<BusinessEntry> items;
  final String? nextCursor;
  final bool loadingMore;
  final Object? loadMoreError;

  bool get hasMore => nextCursor != null;
}

/// Entries, newest first, loaded a page at a time.
class EntryListController extends AsyncNotifier<EntryList> {
  @override
  Future<EntryList> build() async {
    ref.watch(currentUserIdProvider);
    final page = await ref.watch(businessRepositoryProvider).list();
    return EntryList(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      EntryList(
        items: current.items,
        nextCursor: current.nextCursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(businessRepositoryProvider)
          .list(cursor: current.nextCursor);
      if (!ref.mounted) return;
      state = AsyncData(
        EntryList(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = AsyncData(
        EntryList(
          items: current.items,
          nextCursor: current.nextCursor,
          loadMoreError: error,
        ),
      );
    }
  }
}

final entryListProvider =
    AsyncNotifierProvider.autoDispose<EntryListController, EntryList>(
      EntryListController.new,
    );

/// After an entry is added, changed or removed.
void refreshBusinessData(WidgetRef ref) {
  ref
    ..invalidate(businessSummaryProvider)
    ..invalidate(entryListProvider)
    ..invalidate(entryProvider)
    // The day's sales set the saving target.
    ..invalidate(todaySavingsProvider);
}
