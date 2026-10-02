import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

void main() {
  runApp(const AiMemoryCardApp());
}

/// 应用根组件。
/// 只负责：挂主题 + 指定首页。不接路由、不接网络、不接登录（本期不做）。
class AiMemoryCardApp extends StatelessWidget {
  const AiMemoryCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 记忆卡',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomePage(),
    );
  }
}
