import 'package:dio/dio.dart';

import '../api_exception.dart';

/// 错误兜底映射：`DioException → ApiException`（契约 §0.2/§7，§4.1）。
///
/// 这是拦截器链的**最后一个 onError 处理器**（见 `dio_client.dart` 装配注释），
/// 到达这里说明 401 刷新与退避重试都已放弃，把它统一转成 [ApiException]。
/// 转换结果塞进 `DioException.error`，由业务层的 `guard` 解包。
class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: _toApiException(err),
      ),
    );
  }

  ApiException _toApiException(DioException err) {
    final Response<dynamic>? response = err.response;
    final int? status = response?.statusCode;

    String? code;
    String? message;
    String? requestId;
    Map<String, dynamic> details = const <String, dynamic>{};

    if (response?.data is Map) {
      final Object? data = response!.data;
      final Object? error = (data as Map)['error'];
      if (error is Map) {
        code = error['code'] as String?;
        message = error['message'] as String?;
        requestId = error['request_id'] as String?;
        details = (error['details'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
      }
    }

    // 无响应体（超时/断连）→ 网络错误，可重试。
    if (code == null && status == null) {
      return ApiException(
        code: 'NETWORK_ERROR',
        message: '网络连接失败，请检查网络后重试',
        requestId: '',
      );
    }

    // 未知 code 不崩，按 HTTP 状态兜底（4xx 展示 message、5xx 视为可重试）。
    return ApiException(
      code: code ?? _fallbackCode(status),
      message: message ?? _fallbackMessage(status),
      requestId: requestId ?? '',
      details: details,
      httpStatus: status,
      retryAfterS: _retryAfter(response),
    );
  }

  String _fallbackCode(int? status) {
    if (status == null) {
      return 'NETWORK_ERROR';
    }
    if (status >= 500) {
      return 'INTERNAL_ERROR';
    }
    return 'HTTP_$status';
  }

  String _fallbackMessage(int? status) {
    if (status == null) {
      return '网络连接失败';
    }
    if (status >= 500) {
      return '服务暂时不可用，请稍后重试';
    }
    return '请求失败（$status）';
  }

  int? _retryAfter(Response<dynamic>? response) {
    final String? ra = response?.headers.value('Retry-After');
    return ra == null ? null : int.tryParse(ra);
  }
}
