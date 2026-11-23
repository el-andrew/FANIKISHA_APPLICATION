import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class FakeResponse {
  const FakeResponse(this.status, [this.body]);

  /// A request that never got an answer (offline).
  const FakeResponse.offline() : status = -1, body = null;

  final int status;
  final Object? body;
}

typedef FakeHandler = FutureOr<FakeResponse> Function(RequestOptions request);

/// Stands in for the Fanikisha API: answers by `METHOD /path` and records
/// every request so tests can inspect headers and bodies.
class FakeApi implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final _handlers = <String, FakeHandler>{};

  void on(String method, String path, FakeHandler handler) =>
      _handlers['$method $path'] = handler;

  /// Requests to one route, oldest first.
  List<RequestOptions> requestsTo(String method, String path) =>
      requests.where((r) => r.method == method && r.uri.path == path).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final handler = _handlers['${options.method} ${options.uri.path}'];
    final response = handler == null
        ? FakeResponse(404, {'message': 'No fake for ${options.uri.path}'})
        : await handler(options);
    if (response.status == -1) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// Sample API responses.

Map<String, Object?> userJson({
  String id = 'user-1',
  String fullName = 'Asha Mwakyusa',
  String? businessName = 'Asha Duka',
}) => {
  'id': id,
  'email': 'asha@example.com',
  'phone': '+255712345678',
  'fullName': fullName,
  'businessName': businessName,
  'createdAt': '2026-11-01T08:00:00.000Z',
};

Map<String, Object?> tokensJson([String suffix = '1']) => {
  'accessToken': 'access-$suffix',
  'refreshToken': 'refresh-$suffix',
  'expiresIn': 900,
};

Map<String, Object?> goalJson({
  String id = 'goal-1',
  String name = 'New fridge',
  int target = 1200000,
  int saved = 300000,
  String status = 'ACTIVE',
  int priority = 4,
}) => {
  'id': id,
  'name': name,
  'category': null,
  'targetAmount': target,
  'savedAmount': saved,
  'remainingAmount': target - saved,
  'progressPercent': saved * 100 / target,
  'priority': priority,
  'startDate': '2026-11-01',
  'targetDate': '2027-03-01',
  'daysLeft': 100,
  'dailyTargetAmount': ((target - saved) / 100).ceil(),
  'status': status,
  'completedAt': null,
  'createdAt': '2026-11-01T08:00:00.000Z',
};

Map<String, Object?> summaryJson({int total = 300000, int deposits = 3}) => {
  'totalDeposited': total,
  'unallocatedAmount': 0,
  'depositCount': deposits,
  'activeGoals': 1,
  'completedGoals': 0,
};
