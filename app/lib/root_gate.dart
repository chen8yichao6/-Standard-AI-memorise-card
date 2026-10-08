import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/mech_background.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

/// 根路由门 —— 根据登录态决定进登录页还是首页。
///
/// Splash 播完动画后 `pushReplacement` 到这里；本组件触发冷启动会话恢复，
/// 然后监听 [AuthController] 状态切换子树（不是 push，是同一层替换）：
/// - [AuthUnknown]：恢复中，显示 loading；
/// - [AuthUnauthenticated]：登录页；
/// - [AuthAuthenticated]：首页。
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  void initState() {
    super.initState();
    // 冷启动会话恢复：读 refresh token → 有则拉 /users/me（401 自动刷新）。
    AuthController.instance.restore();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthController.instance,
      builder: (BuildContext context, AuthState state, Widget? child) {
        switch (state) {
          case AuthUnknown():
            return const _AuthLoading();
          case AuthUnauthenticated():
            return const LoginPage();
          case AuthAuthenticated():
            return const HomePage();
        }
      },
    );
  }
}

/// 会话恢复中的过渡页（冷启动有 refresh token 时，拉 /users/me 需要网络往返）。
class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MechBackground()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('AI 记忆卡', style: AppTheme.display),
                const SizedBox(height: AppTheme.gapMd),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
