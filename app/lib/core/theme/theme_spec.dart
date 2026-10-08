import 'package:flutter/material.dart';

/// 一套主题 = 一个 id + 名字 + 亮度 + 全套配色。
///
/// 由**开发者**定义（本期内置两套），用户在设置页只负责选，不自己调色。
/// 将来新增主题 = 加一个 [ThemeSpec] 实例 + 塞进 [all]，App 端不改逻辑。
/// 对应 PRD §3.2 F-07 / F-08 与 §4.1 `theme_id`。
class ThemeSpec {
  const ThemeSpec({
    required this.id,
    required this.name,
    required this.brightness,
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

  /// 深蓝赛博（默认）—— 现有配色原样收口。
  static const ThemeSpec dark = ThemeSpec(
    id: 'theme_dark',
    name: '深蓝赛博',
    brightness: Brightness.dark,
    bg: Color(0xFF0E1C30),
    bgDeep: Color(0xFF081220),
    surface: Color(0xFF152842),
    surfaceRaised: Color(0xFF1D3555),
    border: Color(0xFF4E6987),
    borderStrong: Color(0xFF5188B5),
    borderSoft: Color(0xFF2C4F72),
    primary: Color(0xFF22D3EE),
    primaryBright: Color(0xFF7DD3FC),
    primaryDim: Color(0xFF187A94),
    accent: Color(0xFF3B82F6),
    accentDim: Color(0xFF1D4ED8),
    textPrimary: Color(0xFFE3F2FD),
    textSecondary: Color(0xFF82A8CC),
    textTertiary: Color(0xFF8A9FB4),
    danger: Color(0xFFFF5A6A),
    success: Color(0xFF34D399),
    highlight: Color(0x2EA5E8FF),
    panelTop: Color(0xFF2B4A6C),
    panelBottom: Color(0xFF243C5E),
    panelTopRaised: Color(0xFF33567A),
    panelBottomRaised: Color(0xFF2A4568),
  );

  /// 宣纸浅色（示例）—— 米宣纸底 + 松烟墨 + 朱砂印。
  static const ThemeSpec light = ThemeSpec(
    id: 'theme_light',
    name: '宣纸浅色',
    brightness: Brightness.light,
    bg: Color(0xFFF5F1E8),
    bgDeep: Color(0xFFE9E3D5),
    surface: Color(0xFFFBF8F0),
    surfaceRaised: Color(0xFFFFFFFF),
    border: Color(0xFFC9BFAA),
    borderStrong: Color(0xFFA79777),
    borderSoft: Color(0xFFD9D1BF),
    primary: Color(0xFFC0392B),
    primaryBright: Color(0xFFD9554A),
    primaryDim: Color(0xFFA62F24),
    accent: Color(0xFF8B5E34),
    accentDim: Color(0xFF6B4A28),
    textPrimary: Color(0xFF2B2620),
    textSecondary: Color(0xFF6E6357),
    textTertiary: Color(0xFF8D8172),
    danger: Color(0xFFC0392B),
    success: Color(0xFF3E7B4E),
    highlight: Color(0x26FFFFFF),
    panelTop: Color(0xFFFFFFFF),
    panelBottom: Color(0xFFF0E9DA),
    panelTopRaised: Color(0xFFFFFFFF),
    panelBottomRaised: Color(0xFFF6F0E2),
  );

  static const List<ThemeSpec> all = <ThemeSpec>[dark, light];

  static ThemeSpec byId(String id) =>
      all.firstWhere((ThemeSpec s) => s.id == id, orElse: () => dark);

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
            onPrimary: bgDeep,
            secondary: accent,
            onSecondary: textPrimary,
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
