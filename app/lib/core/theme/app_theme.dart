import 'package:flutter/material.dart';

/// 「深蓝赛博」科技主题（2026-10-03 重定，方向 B）。
///
/// 从「近黑 + 亮绿」（深黑机甲）换向而来，三处修正：
/// 1. **底色提亮**：`#0A0F1A`（近黑）→ `#0E1C30`（深蓝）。用户原话「背景先不深」，
///    上一版做反了，整屏发闷。
/// 2. **主光改青**：亮绿 `#00E676`（终端绿）→ 青色 `#22D3EE`（HUD 青）。
///    结构色另用蓝 `#3B82F6`，两色分工：青=激活/数据，蓝=框架/次级。
/// 3. **补质感**：新增 `panelGradient()` 斜向金属渐变与 `highlight` 受光边，
///    面板不再是「一块死平的色块」。
class AppTheme {
  AppTheme._(); // 禁止实例化

  // ===== 背景四层（从深到浅）=====
  /// 页面底：深蓝。
  static const Color bg = Color(0xFF0E1C30);
  /// 凹陷/缝隙：比页面底更深，用于轨道、内嵌槽。
  static const Color bgDeep = Color(0xFF081220);
  /// 面板底。
  static const Color surface = Color(0xFF152842);
  /// 浮起面板（弹层 / 高亮卡片）。
  static const Color surfaceRaised = Color(0xFF1D3555);

  // ===== 描边三档（2026-10-06 Day 9 提亮：原值对比度不足，等于没画）=====
  //
  // 【组件约束 · 描边对比度】（凡新增面板/卡片/输入框/芯片必须遵守）
  //   描边分"对外"与"对内"两套标准，判定前必须先确认该前后景组合在
  //   代码里真实出现，不得为不存在的场景调色：
  //   R2  对外（勾在页面底 bg 上，负责轮廓）        ≥ 3.0
  //   R5  对内（贴自身填充，负责立体感）              ≥ 1.3
  //   R3  纯装饰分隔线（borderSoft / HudBar 细线）    ≥ 2.0
  //   R4  面板填充 vs 页面底（无描边时靠色阶成形）    ≥ 1.5
  //   文字一律 R1：正文 ≥ 4.5，大字/图标 ≥ 3.0。
  //   验收方式：跑 `.workbuddy/verify_tokens.py`，全部通过才算完。
  /// 常规描边。原 `#24466B` 对页面底只有 1.76（合格线 3.0），提亮到达标线。
  static const Color border = Color(0xFF4E6987);
  /// 强调描边（hover / 选中）。原 `#3273A8` 为 3.38，提到可读级 4.5。
  static const Color borderStrong = Color(0xFF5188B5);
  /// 极淡描边（分隔、网格）。原 `#1B3A5C` 仅 1.20（肉眼不可辨），提到 2.0。
  static const Color borderSoft = Color(0xFF2C4F72);

  // ===== 主光（青）=====
  /// 青色主光：激活态、关键数字、进度、焦点。
  static const Color primary = Color(0xFF22D3EE);
  /// 亮青：发光边、高光、hover。
  static const Color primaryBright = Color(0xFF7DD3FC);
  /// 暗青：描边、次级强调。原 `#0E7490` 对面板底仅 2.77，提亮到 3.0 达标线。
  static const Color primaryDim = Color(0xFF187A94);

  // ===== 结构色（蓝）=====
  /// 蓝色：框架、次级强调、图标底。
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentDim = Color(0xFF1D4ED8);

  // ===== 文本 =====
  static const Color textPrimary = Color(0xFFE3F2FD);
  static const Color textSecondary = Color(0xFF82A8CC);
  /// 三级文字（说明 / 元信息小字）。
  /// 原值 `#50708F` 对页面底仅 **3.30**、对浮起面板仅 **2.40**，
  /// 都低于正文合格线 4.5 —— 小字在深色底上基本读不清。
  /// 提亮到「最苛刻背景（浮起面板）上也有 4.55」为止，色相不变。
  static const Color textTertiary = Color(0xFF8A9FB4);

  // ===== 语义 =====
  static const Color danger = Color(0xFFFF5A6A);
  static const Color success = Color(0xFF34D399);

  /// 金属受光边（叠在面板顶边，做出立体感）。
  static const Color highlight = Color(0x2EA5E8FF);

  /// 分隔线（比 border 更淡）。
  static Color divider() => border.withValues(alpha: 0.55);

  /// 面板斜向金属渐变（左上受光 → 右下背光）。
  ///
  /// [raised] 为 true 时整体提亮一档，用于浮起卡片。
  static LinearGradient panelGradient({bool raised = false}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      // 2026-10-06 Day 9：原填充对页面底只有 1.07~1.29（几乎同色，面板"糊"进背景），
      // 提亮后两端均 ≥ 1.5，面板才能被看成"一块"。
      colors: raised
          ? const <Color>[Color(0xFF33567A), Color(0xFF2A4568)]
          : const <Color>[Color(0xFF2B4A6C), Color(0xFF243C5E)],
    );
  }

  /// 青色发光投影（用于激活态面板；不用 blur 过重，保持机械感）。
  static List<BoxShadow> glow({Color? color, double opacity = 0.16}) {
    final Color c = color ?? primary;
    return <BoxShadow>[
      BoxShadow(color: c.withValues(alpha: opacity), blurRadius: 12, spreadRadius: -2),
    ];
  }

  // ===== 字阶（type scale）=====
  /// 大号展示字（启动页 / 详情大标题）。
  static const TextStyle display = TextStyle(
    color: textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 3,
    height: 1.25,
  );

  /// 数字（录音时长 / 计量）：等宽 + 表格数字，机械仪表感。
  /// 2026-10-06 Day 9：原值 20 从未被真实使用（首页/详情都硬压到 17/18），
  /// 收口到实际使用的 17，让「列表/详情里的时长」直接引用本档、不再 copyWith。
  static const TextStyle numeral = TextStyle(
    color: primary,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    fontFamily: 'monospace',
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    height: 1.1,
  );

  /// 超大数字（启动页进度）。
  static const TextStyle numeralLarge = TextStyle(
    color: primary,
    fontSize: 46,
    fontWeight: FontWeight.w500,
    fontFamily: 'monospace',
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    height: 1.0,
  );

  /// 标题（区块 / 卡片标题）。
  static const TextStyle title = TextStyle(
    color: textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 1.3,
  );

  /// 正文。
  static const TextStyle body = TextStyle(
    color: textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  /// 说明 / 元信息。
  static const TextStyle caption = TextStyle(
    color: textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// 小标签 / 数据标注（等宽，HUD 感）。
  static const TextStyle mono = TextStyle(
    color: textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFamily: 'monospace',
    letterSpacing: 0.8,
    height: 1.4,
  );

  /// 微标签（角标 / HUD 极小编码）：本 App 的**最小合法字号**。
  /// 2026-10-06 Day 9：原代码大量 `mono.copyWith(fontSize: 9)`，9px 在 1080 屏上
  /// 几乎不可读。统一收口到 10px，9px 及更小从此废弃。
  static const TextStyle micro = TextStyle(
    color: textSecondary,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    fontFamily: 'monospace',
    letterSpacing: 1.2,
    height: 1.4,
  );

  // ===== 间距阶梯（4pt 基线）=====
  // 2026-10-06 Day 9：原代码竖向用了 18 个不同数值（2,3,4,5,6,8,9,10,11,12,
  // 14,16,18,20,22,24,26,28），区块亲疏读不出来。统一收口到 7 档，
  // 间距只准从这里取，禁止再写魔法数字。映射：2~6→xxs / 7~10→xs /
  // 11~14→sm / 16,18→md / 20,22→lg / 24,26→xl / 28→xxl。
  /// 4 —— 组件内部微调（图标与文字、堆叠文字行间）。
  static const double gapXxs = 4;
  /// 8 —— 紧密元素之间。
  static const double gapXs = 8;
  /// 12 —— 组内元素之间。
  static const double gapSm = 12;
  /// 16 —— 组与组之间 / 面板内边距基准。
  static const double gapMd = 16;
  /// 20 —— 区块之间。
  static const double gapLg = 20;
  /// 24 —— 大区块之间。
  static const double gapXl = 24;
  /// 28 —— 页面级分隔。
  static const double gapXxl = 28;

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.dark(
      primary: primary,
      onPrimary: bgDeep,
      secondary: accent,
      onSecondary: textPrimary,
      surface: surface,
      onSurface: textPrimary,
      error: danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
        centerTitle: false,
        titleTextStyle: title,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceRaised,
        contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primaryDim),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.3),
        selectionHandleColor: primary,
      ),
    );
  }
}
