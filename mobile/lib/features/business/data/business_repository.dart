import '../../../core/api/api_client.dart';
import '../../../core/format/dates.dart';
import 'business_models.dart';

class BusinessRepository {
  BusinessRepository(this._api);

  final ApiClient _api;

  /// [idempotencyKey] must stay the same when retrying the same entry.
  Future<BusinessEntry> create({
    required EntryType type,
    required int amount,
    required DateTime occurredOn,
    required String idempotencyKey,
    String? category,
    String? note,
  }) async => BusinessEntry.fromJson(
    await _api.postMap(
      '/v1/business/entries',
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'type': type.apiValue,
        'amount': amount,
        'occurredOn': toDateOnly(occurredOn),
        'category': ?category,
        'note': ?note,
      },
    ),
  );

  /// A null [category] or [note] clears it.
  Future<BusinessEntry> update(
    String id, {
    required EntryType type,
    required int amount,
    required DateTime occurredOn,
    required String? category,
    required String? note,
  }) async => BusinessEntry.fromJson(
    await _api.patchMap(
      '/v1/business/entries/$id',
      body: {
        'type': type.apiValue,
        'amount': amount,
        'occurredOn': toDateOnly(occurredOn),
        'category': category,
        'note': note,
      },
    ),
  );

  Future<void> delete(String id) => _api.deleteVoid('/v1/business/entries/$id');

  Future<BusinessEntry> get(String id) async => BusinessEntry.fromJson(
    await _api.getMap('/v1/business/entries/$id', cacheKey: 'entry:$id'),
  );

  Future<EntryPage> list({String? cursor, int limit = 30}) async =>
      EntryPage.fromJson(
        await _api.getMap(
          '/v1/business/entries',
          query: {'limit': limit, 'cursor': ?cursor},
          // The first page is kept for offline viewing; later pages are not.
          cacheKey: cursor == null ? 'entries:first' : null,
        ),
      );

  /// [cacheName] names the period (e.g. "today"), so the saved copy is found
  /// again on a later day, when the dates differ.
  Future<BusinessSummary> summary({
    required DateTime from,
    required DateTime to,
    required String cacheName,
  }) async => BusinessSummary.fromJson(
    await _api.getMap(
      '/v1/business/summary',
      query: {'from': toDateOnly(from), 'to': toDateOnly(to)},
      cacheKey: 'business-summary:$cacheName',
    ),
  );
}
