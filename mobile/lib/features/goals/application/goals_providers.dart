import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/goal.dart';

final goalsProvider = FutureProvider.autoDispose.family<List<Goal>, GoalStatus>(
  (ref, status) {
    ref.watch(currentUserIdProvider);
    return ref.watch(goalsRepositoryProvider).list(status: status);
  },
);

final goalProvider = FutureProvider.autoDispose.family<Goal, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(goalsRepositoryProvider).get(id);
});
