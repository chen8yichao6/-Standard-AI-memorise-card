import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';

void main() {
  runApp(const AiMemoryCardApp());
}

/// 应用根组件。
/// 只负责：挂主题 + 指定入口页。不接路由、不接网络、不接登录（本期不做）。
///
/// 入口是启动页（Splash），播完 1.6s 动画后自己 `pushReplacement` 到首页。
class AiMemoryCardApp extends StatelessWidget {
  const AiMemoryCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 记忆卡',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      // 2026-10-06 Day 9 修复（移动端溢出）：系统「字体大小」调大时，
      // 顶栏 HUD 行会横向挤爆。全局把文字缩放钳制在 0.85~1.15：
      // 既保留一定的无障碍放大能力，又保证 HUD 单行布局不被撑破。
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: data.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashPage(),
    );
  }
}
