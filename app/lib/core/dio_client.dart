import 'package:dio/dio.dart';

import 'env.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_mapping_interceptor.dart';
import 'interceptors/request_id_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'token_store.dart';

/// 全局装配业务 Dio 实例（单例）。
///
/// ⚠️ 拦截器顺序是**关键**，勿动：
/// dio 的 `onRequest`/`onResponse` 按 addAll **正序**执行，但 `onError` 按
/// **逆序**执行（后添加的先执行）。要让「401 刷新 → 退避重试 → 错误兜底」按
/// 正确逻辑顺序生效，addAll 采用：
///
///     [ErrorMapping, Retry, Auth, RequestId]
///
/// 对应 onError 逆序 = RequestId → Auth → Retry → ErrorMapping，
/// 即：先记账 → 401 单飞刷新并重放一次 → 幂等白名单退避重试 → 最终兜底转 ApiException。
class ApiClient {
  ApiClient._() {
    tokens = TokenStore();
    refreshDio = _buildRefresh();
    dio = _build(refreshDio);
  }

  static final ApiClient instance = ApiClient._();

  late final TokenStore tokens;
  late final Dio dio;
  late final Dio refreshDio;

  Dio _build(Dio refresh) {
    final Dio api = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: Env.connectTimeout,
        receiveTimeout: Env.receiveTimeout,
        headers: <String, dynamic>{'Accept': 'application/json'},
        // 不要设全局 Content-Type: application/json——OSS 直传与表单上传会因此签名不匹配。
      ),
    );
    api.interceptors.addAll(<Interceptor>[
      ErrorMappingInterceptor(),
      RetryInterceptor(dio: api),
      AuthInterceptor(refreshDio: refresh, apiDio: api, tokens: tokens),
      RequestIdInterceptor(),
    ]);
    return api;
  }

  /// 独立实例：只用于 `POST /auth/refresh`，不带 AuthInterceptor（避免递归）。
  Dio _buildRefresh() {
    final Dio d = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: Env.connectTimeout,
        receiveTimeout: Env.receiveTimeout,
        headers: <String, dynamic>{'Accept': 'application/json'},
      ),
    );
    d.interceptors.add(RequestIdInterceptor());
    return d;
  }
}
