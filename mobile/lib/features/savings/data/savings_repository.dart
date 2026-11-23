import '../../../core/api/api_client.dart';
import 'savings_models.dart';

class SavingsRepository {
  SavingsRepository(this._api);

  final ApiClient _api;

  Future<SavingsSummary> summary() async =>
      SavingsSummary.fromJson(await _api.getMap('/v1/savings/summary'));

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
        ),
      );
}
