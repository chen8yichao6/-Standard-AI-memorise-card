import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// 注入 `X-Request-Id`（契约 §4.2）。
///
/// 报障必须带 `request_id`：后端日志按该字段贯穿定位。这里：
/// - 请求前注入（服务端会透传回显）；
/// - 响应后用响应头回显值覆盖（服务端可能自生成）。
class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final Object? existing = options.headers['X-Request-Id'];
    final String id = existing is String && existing.isNotEmpty
        ? existing
        : const Uuid().v4();
    options.headers['X-Request-Id'] = id;
    options.extra['request_id'] = id; // 供日志/报障使用
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    // 服务端会在响应头回显；优先用响应头的值。
    response.requestOptions.extra['request_id'] =
        response.headers.value('X-Request-Id') ??
            response.requestOptions.extra['request_id'];
    handler.next(response);
  }
}
