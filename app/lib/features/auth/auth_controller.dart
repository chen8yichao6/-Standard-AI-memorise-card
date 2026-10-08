import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

/// 认证状态控制器 —— 全局单例，持当前登录态，驱动根部路由分支。
///
/// `restore` 在 `runApp` 前调用（同 [AppThemeController.load]）：读 refresh token
/// 决定初始进登录页还是首页，对应「杀 App 重开仍是登录态」验收项。
class AuthController extends ValueNotifier<AuthState> {
  AuthController._(AuthRepository repo)
      : _repo = repo,
        super(const AuthUnknown());

  static final AuthController instance = AuthController._(AuthRepository());

  final AuthRepository _repo;

  /// 冷启动恢复会话。
  Future<void> restore() async {
    final bool hasSession = await _repo.hasStoredSession();
    if (!hasSession) {
      value = const AuthUnauthenticated();
      return;
    }
    try {
      final user = await _repo.me();
      value = AuthAuthenticated(user);
    } on ApiException {
      // 凭证被拒或网络故障，阶段 A 一律回登录页；refresh 仍保留，下次启动重试。
      value = const AuthUnauthenticated();
    }
  }

  /// 登录成功 → 已登录态。抛 [ApiException] 由 UI 层提示。
  Future<void> login({required String email, required String password}) async {
    final user = await _repo.login(email: email, password: password);
    value = AuthAuthenticated(user);
  }

  /// 注册成功 → 已登录态（契约：注册即登录，返回 user + tokens）。
  Future<void> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    final user =
        await _repo.register(email: email, password: password, nickname: nickname);
    value = AuthAuthenticated(user);
  }

  /// 登出 → 未登录态。
  Future<void> logout() async {
    await _repo.logout();
    value = const AuthUnauthenticated();
  }
}
