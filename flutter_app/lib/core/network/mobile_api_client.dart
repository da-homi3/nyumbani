import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nyumbasearch/core/config/app_config.dart';
import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/utils/app_log.dart';

/// Dio client for `/api/mobile/v1` — attaches Supabase access token + X-App-Client.
final mobileApiClientProvider = Provider<MobileApiClient>((ref) {
  return MobileApiClient();
});

class MobileApiClient {
  MobileApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.mobileApiV1,
                connectTimeout: const Duration(seconds: 25),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(seconds: 30),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                  'X-App-Client': AppConfig.appClient,
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!AppConfig.hasSupabaseKey) {
            handler.next(options);
            return;
          }
          try {
            final auth = Supabase.instance.client.auth;
            var session = auth.currentSession;
            if (session != null && session.isExpired) {
              try {
                final refreshed = await auth.refreshSession();
                session = refreshed.session;
              } catch (e) {
                AppLog.w('Session refresh failed: $e');
              }
            }
            final token = session?.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            AppLog.w('Auth header skipped: $e');
          }
          handler.next(options);
        },
        onError: (error, handler) {
          AppLog.w(
            'API ${error.requestOptions.method} ${error.requestOptions.path} → ${error.response?.statusCode}',
          );
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Duration? receiveTimeout,
  }) async {
    try {
      final cleaned = <String, dynamic>{};
      if (query != null) {
        for (final e in query.entries) {
          if (e.value != null) cleaned[e.key] = e.value;
        }
      }
      final res = await _dio.get<dynamic>(
        path,
        queryParameters: cleaned.isEmpty ? null : cleaned,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          // Listings/signing can be slow on cold cache; keep default generous.
          receiveTimeout: receiveTimeout ?? const Duration(seconds: 90),
        ),
      );
      final map = _asJsonMap(res.data);
      final total = map['total'];
      final items = map['items'];
      if (total != null || items is List) {
        AppLog.i(
          'API GET $path OK'
          '${total != null ? ' total=$total' : ''}'
          '${items is List ? ' items=${items.length}' : ''}',
        );
      }
      return map;
    } on DioException catch (e) {
      AppLog.w(
        'API GET $path → ${e.response?.statusCode ?? e.type.name}: ${e.message}',
      );
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(headers: headers, responseType: ResponseType.json),
      );
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> putJson(String path) async {
    try {
      final res = await _dio.put<dynamic>(
        path,
        options: Options(responseType: ResponseType.json),
      );
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final res = await _dio.patch<dynamic>(
        path,
        data: body,
        options: Options(headers: headers, responseType: ResponseType.json),
      );
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    try {
      final res = await _dio.delete<dynamic>(
        path,
        options: Options(responseType: ResponseType.json),
      );
      return _asJsonMap(res.data);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trim().isNotEmpty) {
      // Some edges return JSON as text.
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    throw const ServerFailure('Unexpected API response', code: 'BAD_JSON');
  }

  AppFailure _mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkFailure(_friendlyNetworkMessage(e));
    }
    // Some DNS failures surface as unknown with a SocketException cause.
    final raw = '${e.message ?? ''} ${e.error ?? ''}'.toLowerCase();
    if (raw.contains('failed host lookup') ||
        raw.contains('socketexception') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection refused')) {
      return NetworkFailure(_friendlyNetworkMessage(e));
    }
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Request failed';
    String? code;
    if (data is Map) {
      if (data['error'] is String) message = data['error'] as String;
      if (data['code'] is String) code = data['code'] as String?;
    } else if (data is String && data.trim().isNotEmpty) {
      message = data.trim();
    }
    if (status == 401) return UnauthorizedFailure(message);
    if (status == 403) return ServerFailure(message, code: code ?? 'FORBIDDEN');
    if (status == 404) return ServerFailure(message, code: code ?? 'NOT_FOUND');
    return ServerFailure(message, code: code);
  }

  String _friendlyNetworkMessage(DioException e) {
    final raw = '${e.message ?? ''} ${e.error ?? ''}'.toLowerCase();
    if (raw.contains('failed host lookup') || raw.contains('name not resolved')) {
      return 'Can’t reach NyumbaSearch right now (DNS / no internet). '
          'On an emulator, check Wi‑Fi or restart with DNS 8.8.8.8, then tap Retry.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond. Check your connection and try again.';
    }
    return 'No internet connection. Check your connection and try again.';
  }
}
