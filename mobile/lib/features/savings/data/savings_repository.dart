import '../../../core/api/api_client.dart';
import 'savings_models.dart';

class SavingsRepository {
  SavingsRepository(this._api);

  final ApiClient _api;

  Future<SavingsSummary> summary() async => SavingsSummary.fromJson(
    await _api.getMap('/v1/savings/summary', cacheKey: 'summary'),
  );

  Future<SavingRule?> rule() async =>
      SavingRule.fromJson((await _api.getMap('/v1/savings/rule'))['rule']);

  Future<SavingRule?> setRule(SavingBasis basis, int percent) async =>
      SavingRule.fromJson(
        (await _api.putMap(
          '/v1/savings/rule',
          body: {'basis': basis.apiValue, 'percent': percent},
        ))['rule'],
      );

  Future<void> removeRule() => _api.deleteVoid('/v1/savings/rule');

  Future<TodaySavings> today() async => TodaySavings.fromJson(
    await _api.getMap('/v1/savings/today', cacheKey: 'savings-today'),
  );

  Future<DepositSplit> preview(int amount) async => DepositSplit.fromJson(
    await _api.postMap(
      '/v1/savings/deposits/preview',
      body: {'amount': amount},
    ),
  );

  /// [idempotencyKey] must stay the same when retrying the same deposit, so
  /// the server records it once however many times the request is sent.
  Future<Deposit> deposit({
    required int amount,
    required String idempotencyKey,
    String? note,
  }) async => Deposit.fromJson(
    await _api.postMap(
      '/v1/savings/deposits',
      headers: {'Idempotency-Key': idempotencyKey},
      body: {'amount': amount, 'note': ?note},
    ),
  );

  Future<DepositPage> history({String? cursor, int limit = 20}) async =>
      DepositPage.fromJson(
        await _api.getMap(
          '/v1/savings/deposits',
          query: {'limit': limit, 'cursor': ?cursor},
          // The first page is kept for offline viewing; later pages are not.
          cacheKey: cursor == null ? 'deposits:first' : null,
        ),
      );
}
