import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// While the app shows saved data because the network is unreachable: when
/// the oldest of that data was saved. `null` when online.
class OfflineController extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final subscription = ref.watch(apiClientProvider).offline.listen((savedAt) {
      final current = state;
      state = savedAt == null || current == null || savedAt.isBefore(current)
          ? savedAt
          : current;
    });
    ref.onDispose(subscription.cancel);
    return null;
  }
}

final offlineProvider = NotifierProvider<OfflineController, DateTime?>(
  OfflineController.new,
);
