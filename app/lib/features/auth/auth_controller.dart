import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../core/token_store.dart';
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
  ///
  /// 免登录策略（产品要求「3 天没登录就重登」）：
  /// 1. 无本地凭证 → 回登录页；
  /// 2. 有凭证但距上次登录超 3 天 → 回登录页；
  /// 3. 有凭证且 3 天内 → **直接信任进首页**（用本地 user_id 构造最小 User），
  ///    再后台静默拉 `/users/me` 补齐完整信息并刷新锚点；
  ///    - 静默拉取因「凭证被拒」（401 系）失败 → 真正登出；
  ///    - 因「断网」失败 → 保持登录态（离线也能用），下次联网自动补。
  Future<void> restore() async {
    final StoredTokens? stored = await _repo.hasStoredSession();
    if (stored == null) {
      value = const AuthUnauthenticated();
      return;
    }
    // 超 3 天未登录 → 重新登录。
    if (!stored.withinTrustWindow) {
      value = const AuthUnauthenticated();
      return;
    }
    // 3 天内：先用本地 user_id 兜底进首页，再后台静默补全。
    if (stored.userId != null && stored.userId!.isNotEmpty) {
      value = AuthAuthenticated(_repo.localUser(stored.userId!));
    }
    try {
      final User user = await _repo.me();
      await _repo.touchSession();
      value = AuthAuthenticated(user);
    } on ApiException catch (e) {
      // 凭证被拒（401 系）→ 真登出；断网（NETWORK_ERROR）→ 保持登录态。
      if (!e.retryable && e.code != 'NETWORK_ERROR') {
        await _repo.clearSession();
        value = const AuthUnauthenticated();
      }
      // 其余（网络问题）保持当前已登录态，下次联网自动补全。
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

  /// 上传头像成功 → 用服务端返回的新 user 刷新登录态（头像立即生效）。
  Future<void> uploadAvatar(String filePath) async {
    final user = await _repo.uploadAvatar(filePath);
    value = AuthAuthenticated(user);
  }

  /// 登出 → 未登录态。
  Future<void> logout() async {
    await _repo.logout();
    value = const AuthUnauthenticated();
  }
}
