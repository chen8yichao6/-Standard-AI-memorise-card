import 'package:flutter/material.dart';

/// 一套主题 = 一个 id + 名字 + 亮度 + 全套配色。
///
/// 由**开发者**定义（本期内置两套），用户在设置页只负责选，不自己调色。
/// 将来新增主题 = 加一个 [ThemeSpec] 实例 + 塞进 [all]，App 端不改逻辑。
/// 对应 PRD §3.2 F-07 / F-08 与 §4.1 `theme_id`。
///
/// 2026-10-11「主题改墨落」：全 App 统一到 v11「墨落」母题后，主题不再是
/// 「深蓝赛博 / 宣纸」这种风格级切换，而是**同一套墨落母题下的两种氛围**
/// （[night] 夜墨 / [pine] 松烟）——只换「纸色与墨色的冷暖」，
/// **不动三档语义色**（朱砂印 / 录音红 / 显影琥珀恒定）。
/// 这是 v11 三色纪律的要求：语义色换掉，印章与显影的语义就一起毁了。
///
/// - 页面主色板（墨落层）读 [inkBase] / [paper] / [sheetBg] 等字段，
///   由 `Inks` 门面转发（`lib/core/theme/ink_tokens.dart`）。
/// - Material 层（SnackBar / Dialog / TextField 等）读 [bg] / [primary] 等字段。
class ThemeSpec {
  const ThemeSpec({
    required this.id,
    required this.name,
    required this.brightness,
    // ── 墨落调色板（页面主色）────────────────────────────────
    required this.inkBase,
    required this.inkSoft,
    required this.inkDrop,
    required this.inkDropRec,
    required this.paper,
    required this.sheetBg,
    required this.inkOnPaper,
    // ── Material 层 ─────────────────────────────────────────
    required this.bg,
    required this.bgDeep,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.borderSoft,
    required this.primary,
    required this.primaryBright,
    required this.primaryDim,
    required this.accent,
    required this.accentDim,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.danger,
    required this.success,
    required this.highlight,
    required this.panelTop,
    required this.panelBottom,
    required this.panelTopRaised,
    required this.panelBottomRaised,
  });

  final String id;
  final String name;
  final Brightness brightness;

  // ── 墨落调色板 ───────────────────────────────────────────
  /// 暗房底（墨）。
  final Color inkBase;

  /// 墨晕 / 盘面层次（比 [inkBase] 略亮）。
  final Color inkSoft;

  /// 墨滴本体平涂浓黑（待机）。
  final Color inkDrop;

  /// 录音态墨滴（同色相提亮）。
  final Color inkDropRec;

  /// 暗底上的「纸白」文字色。
  final Color paper;

  /// 生宣纸底（纸上态面板背景）。
  final Color sheetBg;

  /// 纸上的墨字。
  final Color inkOnPaper;

  // ── Material 层 ─────────────────────────────────────────
  final Color bg;
  final Color bgDeep;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;
  final Color borderSoft;
  final Color primary;
  final Color primaryBright;
  final Color primaryDim;
  final Color accent;
  final Color accentDim;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color danger;
  final Color success;
  final Color highlight;
  final Color panelTop;
  final Color panelBottom;
  final Color panelTopRaised;
  final Color panelBottomRaised;

  /// 夜墨（默认）—— 暖黑暗房 + 米宣纸，v11 原配色。
  static const ThemeSpec night = ThemeSpec(
    id: 'ink_night',
    name: '夜墨',
    brightness: Brightness.dark,
    // 墨落
    inkBase: Color(0xFF100E0C),
    inkSoft: Color(0xFF241C17),
    inkDrop: Color(0xFF0C0B09),
    inkDropRec: Color(0xFF1C1916),
    paper: Color(0xFFEDE4D3),
    sheetBg: Color(0xFFF2EBDD),
    inkOnPaper: Color(0xFF2A211C),
    // Material
    bg: Color(0xFF100E0C),
    bgDeep: Color(0xFF0C0B09),
    surface: Color(0xFF241C17),
    surfaceRaised: Color(0xFF2E241D),
    border: Color(0xFF4A3B31),
    borderStrong: Color(0xFF6B5445),
    borderSoft: Color(0xFF352A22),
    primary: Color(0xFF8F2C20),
    primaryBright: Color(0xFFB5422F),
    primaryDim: Color(0xFF6E2118),
    accent: Color(0xFFD89B4A),
    accentDim: Color(0xFFA8762F),
    textPrimary: Color(0xFFEDE4D3),
    textSecondary: Color(0xB3EDE4D3),
    textTertiary: Color(0x80EDE4D3),
    danger: Color(0xFFFF3B21),
    success: Color(0xFF4E8C5A),
    highlight: Color(0x268F2C20),
    panelTop: Color(0xFF241C17),
    panelBottom: Color(0xFF1B1510),
    panelTopRaised: Color(0xFF2E241D),
    panelBottomRaised: Color(0xFF241C17),
  );

  /// 松烟（冷调）—— 冷墨暗房 + 冷宣纸，纸墨偏青灰，语义色不变。
  static const ThemeSpec pine = ThemeSpec(
    id: 'ink_pine',
    name: '松烟',
    brightness: Brightness.dark,
    // 墨落
    inkBase: Color(0xFF10161A),
    inkSoft: Color(0xFF1D262C),
    inkDrop: Color(0xFF0C1114),
    inkDropRec: Color(0xFF182026),
    paper: Color(0xFFE2EAEC),
    sheetBg: Color(0xFFE9F0F1),
    inkOnPaper: Color(0xFF1C262B),
    // Material
    bg: Color(0xFF10161A),
    bgDeep: Color(0xFF0C1114),
    surface: Color(0xFF1D262C),
    surfaceRaised: Color(0xFF27323A),
    border: Color(0xFF3B4A53),
    borderStrong: Color(0xFF57707C),
    borderSoft: Color(0xFF2A353C),
    primary: Color(0xFF8F2C20),
    primaryBright: Color(0xFFB5422F),
    primaryDim: Color(0xFF6E2118),
    accent: Color(0xFFD89B4A),
    accentDim: Color(0xFFA8762F),
    textPrimary: Color(0xFFE2EAEC),
    textSecondary: Color(0xB3E2EAEC),
    textTertiary: Color(0x80E2EAEC),
    danger: Color(0xFFFF3B21),
    success: Color(0xFF4E8C5A),
    highlight: Color(0x268F2C20),
    panelTop: Color(0xFF1D262C),
    panelBottom: Color(0xFF151D22),
    panelTopRaised: Color(0xFF27323A),
    panelBottomRaised: Color(0xFF1D262C),
  );

  static const List<ThemeSpec> all = <ThemeSpec>[night, pine];

  static ThemeSpec byId(String id) =>
      all.firstWhere((ThemeSpec s) => s.id == id, orElse: () => night);

  // ===== 面板斜向金属渐变（左上受光 → 右下背光）=====
  LinearGradient panelGradient({bool raised = false}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: raised
          ? <Color>[panelTopRaised, panelBottomRaised]
          : <Color>[panelTop, panelBottom],
    );
  }

  /// 主色发光投影（用于激活态面板）。
  List<BoxShadow> glow({Color? color, double opacity = 0.16}) {
    final Color c = color ?? primary;
    return <BoxShadow>[
      BoxShadow(color: c.withValues(alpha: opacity), blurRadius: 12, spreadRadius: -2),
    ];
  }

  // ===== 字阶（type scale）=====
  TextStyle get display => TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        height: 1.25,
      );

  TextStyle get numeral => TextStyle(
        color: primary,
        fontSize: 17,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        height: 1.1,
      );

  TextStyle get numeralLarge => TextStyle(
        color: primary,
        fontSize: 46,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        height: 1.0,
      );

  TextStyle get title => TextStyle(
        color: textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        height: 1.3,
      );

  TextStyle get body => TextStyle(
        color: textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );

  TextStyle get caption => TextStyle(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  TextStyle get mono => TextStyle(
        color: textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        fontFamily: 'monospace',
        letterSpacing: 0.8,
        height: 1.4,
      );

  TextStyle get micro => TextStyle(
        color: textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        fontFamily: 'monospace',
        letterSpacing: 1.2,
        height: 1.4,
      );

  /// 组装成 Material 的 [ThemeData]。
  ThemeData toThemeData() {
    final ColorScheme scheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: primary,
            onPrimary: paper,
            secondary: accent,
            onSecondary: inkBase,
            surface: surface,
            onSurface: textPrimary,
            error: danger,
            onError: Colors.white,
          )
        : ColorScheme.light(
            primary: primary,
            onPrimary: Colors.white,
            secondary: accent,
            onSecondary: Colors.white,
            surface: surface,
            onSurface: textPrimary,
            error: danger,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
        centerTitle: false,
        titleTextStyle: title,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceRaised,
        contentTextStyle: TextStyle(color: textPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primaryDim),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.3),
        selectionHandleColor: primary,
      ),
    );
  }
}
