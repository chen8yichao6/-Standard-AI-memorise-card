import 'models/user.dart';

/// 认证状态机（三种互斥状态）。
sealed class AuthState {
  const AuthState();
}

/// 启动中，尚未判断本地会话。
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

/// 未登录（无本地会话，或会话已失效）。
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// 已登录，持有当前用户。
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;
}
