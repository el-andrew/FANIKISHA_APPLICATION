import 'dart:async';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'offline_cache.dart';
import 'token_storage.dart';

/// HTTP client for the Fanikisha API.
///
/// Adds the access token to every authenticated request. When the API answers
/// 401, it exchanges the refresh token for a new pair once (however many
/// requests failed at the same moment) and retries. If the refresh token is
/// refused too, the tokens are cleared and [sessionExpired] fires.
///
/// GET requests given a `cacheKey` save their answer in [OfflineCache]; when
/// the network is unreachable they return the saved answer instead, and
/// [offline] says how old it is.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this._tokens,
    this._cache,
    HttpClientAdapter? adapter,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 20),
           contentType: Headers.jsonContentType,
           responseType: ResponseType.json,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  final Dio _dio;
  final TokenStorage _tokens;
  final OfflineCache? _cache;
  final _sessionExpired = StreamController<void>.broadcast();
  final _offline = StreamController<DateTime?>.broadcast();
  Future<bool>? _refreshing;

  /// Fires when the user must sign in again.
  Stream<void> get sessionExpired => _sessionExpired.stream;

  /// When a request was answered from the offline cache: the time that data
  /// was saved. `null` once the API answers again.
  Stream<DateTime?> get offline => _offline.stream;

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, Object?>? query,
    String? cacheKey,
  }) async => _asMap(await _get(path, query, cacheKey));

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, Object?>? query,
    String? cacheKey,
  }) async {
    final data = await _get(path, query, cacheKey);
    return (data as List<Object?>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> postMap(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) async => _asMap(
    await _send(
      'POST',
      path,
      body: body,
      headers: headers,
      authenticated: authenticated,
    ),
  );

  Future<void> postVoid(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> patchMap(String path, {Object? body}) async =>
      _asMap(await _send('PATCH', path, body: body));

  Future<Map<String, dynamic>> putMap(String path, {Object? body}) async =>
      _asMap(await _send('PUT', path, body: body));

  Future<Map<String, dynamic>> deleteMap(String path) async =>
      _asMap(await _send('DELETE', path));

  Future<void> deleteVoid(String path, {Object? body}) =>
      _send('DELETE', path, body: body);

  void dispose() {
    _sessionExpired.close();
    _offline.close();
    _dio.close();
  }

  Future<Object?> _get(
    String path,
    Map<String, Object?>? query,
    String? cacheKey,
  ) async {
    final cache = _cache;
    try {
      final data = await _send('GET', path, query: query);
      if (cache != null && cacheKey != null) await cache.put(cacheKey, data);
      _offline.add(null);
      return data;
    } on ApiException catch (error) {
      final saved = error.kind == ApiErrorKind.network && cacheKey != null
          ? cache?.get(cacheKey)
          : null;
      if (saved == null) rethrow;
      _offline.add(saved.savedAt);
      return saved.data;
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    Future<Object?> attempt() async {
      final tokens = authenticated ? await _tokens.read() : null;
      final response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            ...?headers,
            if (tokens != null) 'Authorization': 'Bearer ${tokens.accessToken}',
          },
        ),
      );
      return response.data;
    }

    try {
      return await attempt();
    } on DioException catch (error) {
      if (!authenticated || error.response?.statusCode != 401) {
        throw ApiException.fromDio(error);
      }
    }

    // The access token expired (or was never valid): refresh once, retry once.
    if (!await _refresh()) {
      throw const ApiException(ApiErrorKind.sessionExpired, statusCode: 401);
    }
    try {
      return await attempt();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Concurrent callers share one refresh request.
  Future<bool> _refresh() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final current = await _tokens.read();
    if (current == null) {
      await _expire();
      return false;
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      await _tokens.save(TokenPair.fromJson(response.data!));
      return true;
    } on DioException catch (error) {
      // Only a refused token ends the session; being offline does not.
      if (error.response?.statusCode == 401) {
        await _expire();
        return false;
      }
      throw ApiException.fromDio(error);
    }
  }

  Future<void> _expire() async {
    await _tokens.clear();
    _sessionExpired.add(null);
  }

  static Map<String, dynamic> _asMap(Object? data) =>
      data as Map<String, dynamic>;
}
