import '../../../core/api/api_client.dart';
import '../../../core/format/dates.dart';
import 'goal.dart';

class GoalsRepository {
  GoalsRepository(this._api);

  final ApiClient _api;

  Future<List<Goal>> list({GoalStatus? status}) async {
    final items = await _api.getList(
      '/v1/goals',
      query: {if (status != null) 'status': status.apiValue},
    );
    return items.map(Goal.fromJson).toList();
  }

  Future<Goal> get(String id) async =>
      Goal.fromJson(await _api.getMap('/v1/goals/$id'));

  Future<Goal> create({
    required String name,
    required int targetAmount,
    required int priority,
    required DateTime targetDate,
    String? category,
  }) async => Goal.fromJson(
    await _api.postMap(
      '/v1/goals',
      body: {
        'name': name,
        'targetAmount': targetAmount,
        'priority': priority,
        'targetDate': toDateOnly(targetDate),
        'category': ?category,
      },
    ),
  );

  /// A null [category] clears it.
  Future<Goal> update(
    String id, {
    required String name,
    required int targetAmount,
    required int priority,
    required DateTime targetDate,
    required String? category,
  }) async => Goal.fromJson(
    await _api.patchMap(
      '/v1/goals/$id',
      body: {
        'name': name,
        'targetAmount': targetAmount,
        'priority': priority,
        'targetDate': toDateOnly(targetDate),
        'category': category,
      },
    ),
  );

  Future<Goal> archive(String id) async =>
      Goal.fromJson(await _api.deleteMap('/v1/goals/$id'));
}
