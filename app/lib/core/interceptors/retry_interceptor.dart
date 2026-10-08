import 'package:dio/dio.dart';

import '../backoff.dart';

/// 退避重试拦截器（契约 §0.6 / §4.4）—— 只重试幂等操作，不全局重试。
///
/// 白名单为 `method + path 前缀`；不重试：`POST /auth/login|register|refresh`
/// （须单飞串行）、`PUT /users/me/password`、WS 音频帧（由 resume 保证）。
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, this.maxRetries = 2});

  final Dio dio;
  final int maxRetries;

  /// method + path 前缀白名单（契约 §4.4）。
  static const Set<String> _retryable = <String>{
    'GET', // 所有 GET 天然幂等
    'POST /files/multipart/initiate', // 必须带同一 Idempotency-Key
    'POST /files/multipart', // sign-part / complete / abort
    'POST /recordings', // object_key 去重
    'POST /recordings/', // transcribe / realtime-sessions stop
    'PATCH /', // 更新类
    'DELETE /', // 删除类
  };

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final RequestOptions options = err.requestOptions;
    final int attempt = (options.extra['retry_count'] as int?) ?? 0;
    if (attempt >= maxRetries || !_shouldRetry(options, err)) {
      return handler.next(err);
    }

    await Future<void>.delayed(backoff(attempt, retryAfterS: _retryAfter(err)));

    final RequestOptions replay = options
      ..extra['retry_count'] = attempt + 1;
    try {
      final Response<dynamic> response = await dio.fetch<dynamic>(replay);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(RequestOptions options, DioException err) {
    if (!_inWhitelist(options.method, options.path)) {
      return false;
    }
    final int? status = err.response?.statusCode;
    final bool network = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
    final bool retryableStatus =
        status == 429 || status == 503 || (status != null && status >= 500);
    return network || retryableStatus;
  }

  bool _inWhitelist(String method, String path) {
    final String key = '$method $path';
    for (final String prefix in _retryable) {
      if (prefix == 'GET') {
        if (method == 'GET') {
          return true;
        }
      } else if (key.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  int? _retryAfter(DioException err) {
    final String? ra = err.response?.headers.value('Retry-After');
    return ra == null ? null : int.tryParse(ra);
  }
}
