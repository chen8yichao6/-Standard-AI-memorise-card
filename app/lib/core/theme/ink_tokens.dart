import 'package:flutter/material.dart';

import 'app_theme_controller.dart';
import 'theme_spec.dart';

/// 「墨落」配色令牌 —— 逐字取自 v11 设计稿
/// （`.workbuddy/pack/AI记忆卡-首页设计-v11/design-mockup-home.src.html` 的 `:root`）。
///
/// ⚠ 三条纪律（design-brief.md 写死，不许稀释）：
/// 1. **三色各只有一份职责**：墨 = 黑（[ink]/[inkSoft]/[inkDrop]）、
///    印 = 朱（[seal]，只给「印」家族、只在纸上、哑光不发光）、
///    显影 = 琥珀（[progress]，只给「处理中/转写中」）。
/// 2. **同一时刻全屏只有一处发光**；待机态一处都没有。
/// 3. 红（[record]）与琥珀（[progress]）永不同屏 —— 状态色才有语义。
///
/// 2026-10-11「主题改墨落」：本类从「写死的静态常量」改为**读当前主题的门面**。
/// - 随主题变的：墨 / 纸家族（[ink]~[inkOnPaper] 及其派生）→ `getter`，
///   指向 [AppThemeController] 当前持有的 [ThemeSpec]。
/// - 恒定不变的：**语义色**（[seal] / [record] / [progress] / [glow] / [seep]…）
///   与**尺寸** → 保持 `static const`。这是纪律：换主题只换纸墨冷暖，
///   语义色换掉，印章与显影的含义就一起毁了。
///
/// 命名避让：Flutter material 已有 `Ink`（InkWell 的涟漪层）组件，
/// 故本令牌类命名为 [Inks]。
abstract final class Inks {
  static ThemeSpec get _s => AppThemeController.instance.spec;

  // ── 墨 / 底（随主题）────────────────────────────────────
  static Color get ink => _s.inkBase; // 暖中性黑（暗房底）
  static Color get inkSoft => _s.inkSoft; // 墨晕 / 盘面层次
  static Color get inkDrop => _s.inkDrop; // 墨滴本体平涂浓黑（待机）
  static Color get inkDropRec => _s.inkDropRec; // 录音态：同色相提亮

  // ── 纸（随主题）──────────────────────────────────────────
  static Color get paper => _s.paper; // 纸白：暗底上的文字
  static Color get sheetBg => _s.sheetBg; // 生宣纸底
  static Color get inkOnPaper => _s.inkOnPaper; // 纸上的墨字

  // ── 三档语义色（恒定，不随主题）──────────────────────────
  static const Color seal = Color(0xFF8F2C20); // 印泥 / 朱砂
  static const Color record = Color(0xFFFF3B21); // 只允许「正在录音」
  static const Color progress = Color(0xFFD89B4A); // 只允许「处理中 / 转写中」
  static const Color sealPaper = Color(0xFFF5EDE0); // 印上的字

  // ── 半透明派生态（随主题；避免在页面里散落 withValues）────
  static Color get paperDim => paper.withValues(alpha: 0.62);
  static Color get paperSoft => paper.withValues(alpha: 0.80);
  static Color get hair => paper.withValues(alpha: 0.12);
  static Color get inkOnPaperDim => inkOnPaper.withValues(alpha: 0.62);
  static Color get inkOnPaperSoft => inkOnPaper.withValues(alpha: 0.82);

  /// 录音态暖晕（`.glow`）：暗朱 —— 读作「纸被下面的暖光浸出来」，不是亮红球。
  static const Color glow = Color(0xFFA83A26);

  /// 渗晕色（`.bleed` / `.wet-ring` 的墨棕）。
  static const Color seep = Color(0xFF281F1A);
  static const Color seepCore = Color(0xFF201915);

  // ── 关键尺寸（390×844 目标框下的 css px；恒定）───────────
  static const double stampSize = 150; // 墨滴本体内接尺寸
  static const double bleedSize = 186; // 渗晕①
  static const double wetRingSize = 166; // 渗晕②
  static const double glowSize = 330; // 录音态暖晕
  static const double sealSize = 38; // 印章
  static const double sheetRatio = 566 / 844; // 生宣占屏高比
}
