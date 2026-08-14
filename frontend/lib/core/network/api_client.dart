import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

/// Thin Dio wrapper that attaches the Supabase access token to every request and
/// normalises backend error payloads into [ApiException].
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        // Every backend deploy restarts the container — even on a paid Render plan that no
        // longer idles down, the first connection attempt right after a restart can still find
        // the server not yet accepting connections. 90s wasn't enough margin and caused spurious
        // DioException [connection timeout] failures for requests that landed in that window.
        connectTimeout: const Duration(seconds: 180),
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // supabase_flutter refreshes the session in the background, so the token here is
          // kept current without needing an explicit awaited refresh call per-request.
          final accessToken =
              Supabase.instance.client.auth.currentSession?.accessToken;
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(ApiException.fromDioError(error).toDioError(error));
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioError(DioException error) {
    final data = error.response?.data;
    final detail = data is Map<String, dynamic> ? data['detail'] : null;
    final message = detail is String
        ? detail
        : (error.message ?? 'Something went wrong. Please try again.');
    return ApiException(message, statusCode: error.response?.statusCode);
  }

  DioException toDioError(DioException original) {
    return original.copyWith(error: this);
  }

  @override
  String toString() => message;
}

/// Extracts a clean, user-facing message from any error caught around an API call.
///
/// The onError interceptor above always converts failures to an [ApiException], but Dio's own
/// contract means whatever propagates out of a request is still a [DioException] — the
/// [ApiException] only rides along inside its `.error` field ([ApiException.toDioError]).
/// Calling `.toString()` directly on that caught exception (as every screen used to) prints
/// Dio's own verbose diagnostic text ("This exception was thrown because...") instead of the
/// intended message — this unwraps it correctly. Use this everywhere an error caught from an
/// API call is shown to the user.
String readableApiError(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) return inner.message;
    return error.message ?? 'Something went wrong. Please try again.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}
