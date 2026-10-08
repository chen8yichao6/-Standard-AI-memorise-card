import 'package:flutter/material.dart';

import 'core/theme/app_theme_controller.dart';
import 'features/splash/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 启动前读本地保存的 theme_id，装配到控制器（PRD F-08「重启仍生效」）。
  await AppThemeController.instance.load();
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
    // 监听主题控制器：设置页切主题后这里重建，全 App 立即换色。
    return ListenableBuilder(
      listenable: AppThemeController.instance,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          // ⭐ 主题切换强制整树重建：页面里大量组件是 const 构造（如 const _TopBar()），
          // 同一 const 表达式返回同一实例，Flutter 判定 identical 会跳过重建，
          // 导致切主题后这些子树的 build 不重跑、颜色不变。key 换成新主题 id，
          // 整棵树（含 const 子树）全部重新 inflate —— 代价是切换瞬间整屏重刷，可接受。
          key: ValueKey<String>(AppThemeController.instance.spec.id),
          title: 'AI 记忆卡',
          debugShowCheckedModeBanner: false,
          theme: AppThemeController.instance.themeData,
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
      },
    );
  }
}
