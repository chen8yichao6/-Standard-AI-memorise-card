import 'dart:async';

import 'package:dio/dio.dart';

import '../token_store.dart';

/// 401 单飞刷新拦截器（契约 §3.2）。
///
/// 三条铁律：
/// ① `_inFlight` 的赋值与清理在**同步路径**完成（`whenComplete` + `identical`
///    防旧 Future 清掉新 Future）；
/// ② 刷新用**独立 Dio**（[refreshDio]），不带本拦截器，否则刷新自身 401 会递归；
/// ③ 只有「服务端明确拒绝该 refresh」才清凭证，纯网络故障不清（地铁/电梯断网不被登出）。
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.refreshDio,
    required this.apiDio,
    required this.tokens,
  });

  /// 独立实例：只用于 `POST /auth/refresh`，不带 AuthInterceptor。
  final Dio refreshDio;

  /// 业务 Dio：用于重放原始请求（重新走完整拦截器链）。
  final Dio apiDio;

  final TokenStore tokens;

  /// 同一时刻最多一个刷新在飞，其余并发 401 复用同一个 Future。
  Future<TokenPair>? _inFlight;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skip_auth'] != true) {
      final String? a = await tokens.access();
      if (a != null && a.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $a';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final RequestOptions options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra['skip_auth'] == true ||
        options.extra['auth_retried'] == true) {
      // 非 401 / 已重放过：交给重试或错误映射层。
      return handler.next(err);
    }

    final TokenPair pair;
    try {
      pair = await _refreshSingleFlight();
    } catch (_) {
      // 刷新失败：把原始 401 继续往下传（错误映射层兜底）。
      return handler.next(err);
    }

    final RequestOptions replay = options
      ..headers['Authorization'] = 'Bearer ${pair.accessToken}'
      ..extra['auth_retried'] = true; // 只重放一次，防死循环
    try {
      final Response<dynamic> response = await apiDio.fetch<dynamic>(replay);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<TokenPair> _refreshSingleFlight() {
    final Future<TokenPair>? existing = _inFlight;
    if (existing != null) {
      return existing;
    }
    late final Future<TokenPair> f;
    f = _doRefresh().whenComplete(() {
      if (identical(_inFlight, f)) {
        _inFlight = null;
      }
    });
    _inFlight = f; // 赋值与清理都在同步路径上完成
    return f;
  }

  Future<TokenPair> _doRefresh() async {
    final StoredTokens? stored = await tokens.read();
    if (stored == null || stored.refreshToken.isEmpty) {
      await tokens.clear();
      throw StateError('no refresh token');
    }
    try {
      // 契约 §1.3：请求体 {"refresh_token": "..."}；响应只有新令牌，没有 user。
      final Response<Map<String, dynamic>> r =
          await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: <String, dynamic>{'refresh_token': stored.refreshToken},
        options: Options(extra: <String, dynamic>{'skip_auth': true}),
      );
      final Map<String, dynamic> d = r.data!;
      final TokenPair pair = TokenPair(
        accessToken: d['access_token'] as String,
        refreshToken: d['refresh_token'] as String,
        accessExpiresIn: d['access_expires_in'] as int,
        userId: stored.userId,
      );
      await tokens.save(pair); // 轮换：立刻覆盖旧 refresh
      tokens.setAccess(pair.accessToken); // 同步更新内存 access
      return pair;
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      final Object? body = e.response?.data;
      final Object? code = (body is Map && body['error'] is Map)
          ? (body['error'] as Map)['code']
          : null;
      // 只有「服务端明确拒绝该 refresh」才清凭证；纯网络故障（无响应/超时）不清。
      final bool rejected = status == 401 ||
          status == 403 ||
          const <String>{'INVALID_TOKEN', 'TOKEN_REUSED', 'USER_DISABLED'}
              .contains(code);
      if (rejected) {
        await tokens.clear();
      }
      rethrow; // 调用方把异常交给错误映射层：网络错误只是可重试失败
    }
  }
}
