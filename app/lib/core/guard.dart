import 'package:dio/dio.dart';

import 'api_exception.dart';

/// 统一解包拦截器链抛出的异常，把 `DioException` 转成 [ApiException]。
///
/// 拦截器链的 `ErrorMappingInterceptor` 已把业务错误构造成 `ApiException`
/// 并塞进 `DioException.error`，这里负责取回并重新抛出，让业务层
/// 只面对 [ApiException] 一种异常类型。
Future<T> guard<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on DioException catch (e) {
    if (e.error is ApiException) {
      throw e.error! as ApiException;
    }
    // 兜底：理论上不该走到这里（ErrorMapping 已转换）。
    throw ApiException(
      code: 'NETWORK_ERROR',
      message: e.message ?? '请求失败',
      requestId: '',
    );
  }
}
