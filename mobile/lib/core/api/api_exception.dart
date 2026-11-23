import 'package:dio/dio.dart';

enum ApiErrorKind {
  /// No response: offline, server unreachable, or timed out.
  network,

  /// The refresh token was refused; the user has to sign in again.
  sessionExpired,

  /// 4xx: the request was understood and refused. [ApiException.messages]
  /// holds the server's explanation.
  rejected,

  /// 5xx or an unreadable response.
  server,
}

class ApiException implements Exception {
  const ApiException(
    this.kind, {
    this.statusCode,
    this.messages = const [],
    this.errorCode,
    this.details = const {},
  });

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return const ApiException(ApiErrorKind.network);
    }
    final status = response.statusCode ?? 0;
    if (status >= 500) {
      return ApiException(ApiErrorKind.server, statusCode: status);
    }
    final body = response.data;
    return ApiException(
      ApiErrorKind.rejected,
      statusCode: status,
      messages: _messagesFrom(body),
      errorCode: body is Map ? body['code'] as String? : null,
      details: body is Map ? Map<String, Object?>.from(body) : const {},
    );
  }

  final ApiErrorKind kind;
  final int? statusCode;

  /// Server messages, e.g. `amount: Too small: expected number to be >0`.
  final List<String> messages;

  /// A machine-readable reason, when the API gives one (e.g. `code_incorrect`).
  final String? errorCode;

  /// The whole error body, for extra fields such as `triesLeft`.
  final Map<String, Object?> details;

  /// The message for one field, without its `field: ` prefix.
  String? messageFor(String field) {
    for (final message in messages) {
      if (message.startsWith('$field: ')) {
        return message.substring(field.length + 2);
      }
    }
    return null;
  }

  @override
  String toString() =>
      'ApiException($kind, status: $statusCode, messages: $messages)';

  static List<String> _messagesFrom(Object? body) {
    if (body is Map) {
      final message = body['message'];
      if (message is String) return [message];
      if (message is List) return message.whereType<String>().toList();
    }
    return const [];
  }
}
