import 'package:flutter/material.dart';

import 'app_theme_controller.dart';
import 'theme_spec.dart';

/// 「门面」—— 全 App 统一从这里取颜色 / 字阶 / 间距。
///
/// 2026-10-08 主题层改造：本类从「写死的静态常量」改为「读当前主题」的门面。
/// - **间距**（[gapXxs] ~ [gapXxl]）与主题无关，保持 `static const`，不随主题变；
/// - **颜色 / 字阶 / 渐变**改为 getter，指向 [AppThemeController] 当前持有的 [ThemeSpec]，
///   切换主题后 getter 返回新值，配合根部 ListenableBuilder 重建，全 App 立即换色。
///
/// 具体配色定义在 `theme_spec.dart`（开发者上传，用户只选）。
class AppTheme {
  AppTheme._(); // 禁止实例化

  static ThemeSpec get _spec => AppThemeController.instance.spec;

  /// 当前主题（供 CustomPainter 等需要感知主题变化、但非 build 上下文的地方用）。
  static ThemeSpec get spec => _spec;

  // ===== 颜色（getter，随主题变）=====
  static Color get bg => _spec.bg;
  static Color get bgDeep => _spec.bgDeep;
  static Color get surface => _spec.surface;
  static Color get surfaceRaised => _spec.surfaceRaised;
  static Color get border => _spec.border;
  static Color get borderStrong => _spec.borderStrong;
  static Color get borderSoft => _spec.borderSoft;
  static Color get primary => _spec.primary;
  static Color get primaryBright => _spec.primaryBright;
  static Color get primaryDim => _spec.primaryDim;
  static Color get accent => _spec.accent;
  static Color get accentDim => _spec.accentDim;
  static Color get textPrimary => _spec.textPrimary;
  static Color get textSecondary => _spec.textSecondary;
  static Color get textTertiary => _spec.textTertiary;
  static Color get danger => _spec.danger;
  static Color get success => _spec.success;
  static Color get highlight => _spec.highlight;

  /// 分隔线（比 border 更淡）。
  static Color divider() => border.withValues(alpha: 0.55);

  /// 面板斜向金属渐变。
  static LinearGradient panelGradient({bool raised = false}) =>
      _spec.panelGradient(raised: raised);

  /// 青色发光投影。
  static List<BoxShadow> glow({Color? color, double opacity = 0.16}) =>
      _spec.glow(color: color, opacity: opacity);

  // ===== 字阶（getter，随主题变）=====
  static TextStyle get display => _spec.display;
  static TextStyle get numeral => _spec.numeral;
  static TextStyle get numeralLarge => _spec.numeralLarge;
  static TextStyle get title => _spec.title;
  static TextStyle get body => _spec.body;
  static TextStyle get caption => _spec.caption;
  static TextStyle get mono => _spec.mono;
  static TextStyle get micro => _spec.micro;

  // ===== 间距阶梯（4pt 基线，与主题无关，保持 const）=====
  static const double gapXxs = 4;
  static const double gapXs = 8;
  static const double gapSm = 12;
  static const double gapMd = 16;
  static const double gapLg = 20;
  static const double gapXl = 24;
  static const double gapXxl = 28;
}
