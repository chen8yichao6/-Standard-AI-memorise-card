import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// HUD 组件集 —— 用来「补密度」的一批小零件。
///
/// 用户反馈「元素太少、太空」。科技感的本质是**信息密度感**：
/// 屏幕上要有等宽小字、刻度、状态行、坐标标注这类「看起来在报告数据」的元素，
/// 而不是空荡荡几个大标题。这批组件就是干这个的。
/// 共同原则：等宽字体、小字号、低对比色、只在需要的地方用主光色点睛。

/// 区块标题 —— `▮ 最近录音` 形式的 HUD 小标签。
class HudLabel extends StatelessWidget {
  const HudLabel(this.text, {super.key, this.trailing, this.color, this.expand = false});

  final String text;
  final Widget? trailing;
  final Color? color;

  /// 撑满可用宽度，并在右侧接一条延伸线（用于区块标题）。
  /// 注意：默认是 `min`，因为如果把它塞进另一个 Row 里（宽度约束无界），
  /// `max` 会直接触发布局异常。
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? AppTheme.primary;
    final bool grow = expand || trailing != null;
    return Row(
      mainAxisSize: grow ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Container(width: 3, height: 11, color: c),
        const SizedBox(width: AppTheme.gapXs),
        Text(
          text,
          style: AppTheme.mono.copyWith(
            color: AppTheme.textSecondary,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) ...<Widget>[
          const Spacer(),
          trailing!,
        ] else if (grow) ...<Widget>[
          const SizedBox(width: AppTheme.gapSm),
          Expanded(child: Container(height: 0.8, color: AppTheme.divider())),
        ],
      ],
    );
  }
}

/// 状态行 —— 上下细线夹一行等宽数据，像设备的诊断输出。
class HudBar extends StatelessWidget {
  const HudBar({super.key, required this.items, this.padding});

  /// 左对齐的若干「标签·值」对，会自动用间距分开。
  final List<HudItem> items;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderSoft, width: 0.8),
          bottom: BorderSide(color: AppTheme.borderSoft, width: 0.8),
        ),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppTheme.gapSm),
            items[i],
          ],
        ],
      ),
    );
  }
}

/// 状态行里的一项：`标签 值`。
class HudItem extends StatelessWidget {
  const HudItem({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: AppTheme.micro.copyWith(color: AppTheme.textTertiary)),
        const SizedBox(width: AppTheme.gapXxs),
        Text(
          value,
          style: AppTheme.micro.copyWith(
            color: valueColor ?? AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 带节点的分隔线 —— `——◆——————` ，比普通 Divider 更有机械味。
class TechDivider extends StatelessWidget {
  const TechDivider({super.key, this.label, this.color});

  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? AppTheme.border;
    if (label == null) {
      return Row(
        children: <Widget>[
          Container(width: 4, height: 4, color: c),
          Expanded(child: Container(height: 0.8, color: c)),
          Container(width: 4, height: 4, color: c),
        ],
      );
    }
    return Row(
      children: <Widget>[
        Container(width: 4, height: 4, color: c),
        Expanded(child: Container(height: 0.8, color: c)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(label!, style: AppTheme.micro.copyWith(color: AppTheme.textTertiary)),
        ),
        Expanded(child: Container(height: 0.8, color: c)),
        Container(width: 4, height: 4, color: c),
      ],
    );
  }
}

/// 刻度尺 —— 一排长短交替的刻度线，像仪表盘的量程标注。
///
/// [divisions] 是总刻度数；每 5 格一条长线。常用于卡片底部「填密度」。
class CalibrationRuler extends StatelessWidget {
  const CalibrationRuler({
    super.key,
    this.divisions = 40,
    this.height = 8,
    this.color,
  });

  final int divisions;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _RulerPainter(divisions: divisions, color: color ?? AppTheme.borderStrong),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  const _RulerPainter({required this.divisions, required this.color});

  final int divisions;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..strokeWidth = 1;
    final double step = size.width / divisions;
    for (int i = 0; i <= divisions; i++) {
      final bool major = i % 5 == 0;
      p.color = color.withValues(alpha: major ? 0.85 : 0.35);
      final double x = i * step;
      canvas.drawLine(Offset(x, 0), Offset(x, major ? size.height : size.height * 0.45), p);
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.divisions != divisions || oldDelegate.color != color;
}

/// 呼吸指示点 —— 缓慢明暗循环，让界面「活着」。
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.size = 6, this.color, this.period = const Duration(seconds: 2)});

  final double size;
  final Color? color;
  final Duration period;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color c = widget.color ?? AppTheme.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double v = 0.35 + _c.value * 0.65;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: c.withValues(alpha: v),
            boxShadow: <BoxShadow>[
              BoxShadow(color: c.withValues(alpha: 0.5 * v), blurRadius: 6, spreadRadius: 1),
            ],
          ),
        );
      },
    );
  }
}

/// 波形条 —— 一排高矮不一的竖条，录音卡 / 播放器用。
///
/// [seed] 决定静态形态（不做随机，保证每帧一致，避免抖动）；
/// [animate] 为 true 时首尾若干条高度循环变化，做出「正在采集」的感觉。
class WaveBars extends StatefulWidget {
  const WaveBars({
    super.key,
    this.count = 28,
    this.height = 22,
    this.animate = false,
    this.color,
    this.progress = 1.0,
  });

  final int count;
  final double height;
  final bool animate;
  final Color? color;
  /// 已播放比例（0~1），左侧以此着色为亮青，右侧暗淡。
  final double progress;

  @override
  State<WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<WaveBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 伪随机但确定的高度序列（用整数散列，避免 Random 每帧变化）。
  double _h(int i) {
    final int x = (i * 2654435761) % 1000;
    return 0.28 + (x % 72) / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final Color base = widget.color ?? AppTheme.primary;
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, Widget? child) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < widget.count; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.8),
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: widget.height * _barHeight(i),
                        decoration: BoxDecoration(
                          color: (i / widget.count) <= widget.progress
                              ? base.withValues(alpha: 0.9)
                              : AppTheme.borderStrong.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _barHeight(int i) {
    double h = _h(i);
    if (widget.animate && i % 7 == 0) {
      h = h * (0.55 + _c.value * 0.75);
    }
    return h.clamp(0.14, 1.0);
  }
}
