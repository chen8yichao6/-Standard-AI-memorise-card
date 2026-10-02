import 'package:flutter/material.dart';

/// 彩墨国风主题 —— 本期第 3 套主题（theme_caimei），并设为默认。
///
/// 按 Day 5 定的规则：主题由开发者上传、用户只负责选。
/// 这里的七色取自中国传统色，按「适中、较为分开」降饱和、加留白。
class AppTheme {
  AppTheme._(); // 禁止实例化

  // —— 七色 ——
  static const Color cinnabar = Color(0xFFC3272B); // 朱砂（红）
  static const Color gamboge = Color(0xFFE0A52E); // 藤黄（黄）
  static const Color azurite = Color(0xFF1685A9); // 石青（青蓝）
  static const Color malachite = Color(0xFF2E9E6B); // 石绿（绿）
  static const Color rouge = Color(0xFFA63A50); // 胭脂（深红）
  static const Color purple = Color(0xFF5B4BA1); // 黛紫（紫）
  static const Color ochre = Color(0xFF96603C); // 赭石（棕）

  // —— 底与墨 ——
  static const Color ricePaper = Color(0xFFF7F2EA); // 宣纸（页面背景）
  static const Color cardWhite = Color(0xFFFEFCF7); // 卡片白
  static const Color ink = Color(0xFF2B2620); // 墨色（主文字）

  /// 七色列表，供需要轮换配色的场景使用。
  static const List<Color> sevenColors = <Color>[
    cinnabar,
    gamboge,
    azurite,
    malachite,
    rouge,
    purple,
    ochre,
  ];

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: cinnabar,
      primary: cinnabar,
      secondary: azurite,
      tertiary: gamboge,
      surface: cardWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ricePaper,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
