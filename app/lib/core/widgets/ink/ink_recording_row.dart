import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/mock/mock_seed.dart';
import '../../theme/ink_tokens.dart';

/// 录音列表行 —— 首页「最近」与「全部录音」页共用的一条。
///
/// 左竖墨线 + 状态符号 + 标题/元信息 + 时长 + 播放键。
/// 转写中的条目：标题在模糊 ↔ 清晰之间循环（母题第三动「显影」），
/// 状态符号换成琥珀半环、整行文字提为琥珀色。
///
/// 从 `features/home/home_page.dart` 提取上移（2026-10-11），
/// 供首页与 [RecordingsListPage] 复用，避免两处各写一份、日久走样。
class InkRecordingRow extends StatelessWidget {
  const InkRecordingRow({
    super.key,
    required this.item,
    required this.onTap,
    this.first = false,
  });

  final RecordingItem item;

  /// 是否是列表第一条（第一条不画上方的行分隔线）。
  final bool first;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool tc = item.isTranscribing;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          // 行与行之间也是墨线（两端淡出），而不是靠留白分隔
          if (!first)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Inks.paper.withValues(alpha: 0.10),
                    Inks.paper.withValues(alpha: 0.05),
                    const Color(0x00000000),
                  ],
                  stops: const <double>[0, 0.45, 1],
                ),
              ),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                // 每行左侧一道短竖墨线：把这一行「挂」在纸上
                Container(
                  width: 2,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Inks.paper.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 9),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CustomPaint(
                    painter: _StatusMarkPainter(
                      transcribing: tc,
                      color: tc ? Inks.progress : Inks.paper,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _title(tc),
                      const SizedBox(height: 4),
                      Text(
                        item.date,
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.3,
                          color: tc ? Inks.progress : Inks.paperDim,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.duration,
                  style: TextStyle(
                    fontSize: 13,
                    color: tc ? Inks.progress : Inks.paperSoft,
                    fontFeatures: const <ui.FontFeature>[
                      ui.FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                if (!tc) ...<Widget>[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(
                      painter: _PlayPainter(color: Inks.paperSoft),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(bool tc) {
    final TextStyle base = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Inks.paper,
      letterSpacing: 0,
    );
    if (!tc) return Text(item.title, style: base);
    // 转写中 = 正在显影：标题由模糊浮到清晰、再退回。
    return _DevelopText(text: item.title, style: base);
  }
}

/// 「显影」文字：模糊 ↔ 清晰循环（母题第三个动作）。
///
/// ⚠ 用负相位起步（从周期的「清晰段」开始）—— 否则页面刚加载就被看到，
/// 正好停在最模糊的一帧。
class _DevelopText extends StatefulWidget {
  const _DevelopText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_DevelopText> createState() => _DevelopTextState();
}

class _DevelopTextState extends State<_DevelopText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  @override
  void initState() {
    super.initState();
    _c.value = 0.5; // 负 delay 等价：从周期中点（清晰段）起步
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double p = _c.value;
        double blur = 0;
        double op = 1;
        if (p < 0.12) {
          final double t = p / 0.12;
          blur = 0.9 * (1 - t);
          op = 0.86 + 0.14 * t;
        } else if (p > 0.88) {
          final double t = (p - 0.88) / 0.12;
          blur = 0.9 * t;
          op = 1 - 0.14 * t;
        }
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Opacity(opacity: op, child: child),
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}

/// 状态符号：已生成 = 实心墨点；转写中 = 半显影的琥珀环。
class _StatusMarkPainter extends CustomPainter {
  const _StatusMarkPainter({required this.transcribing, required this.color});

  final bool transcribing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    if (!transcribing) {
      canvas.drawCircle(c, 4, Paint()..color = color);
      return;
    }
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.22);
    canvas.drawCircle(c, size.width / 2 - 1, ring);
    // 停在「半显影」的一段弧
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: size.width / 2 - 1),
      -math.pi / 2,
      math.pi,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _StatusMarkPainter old) =>
      old.transcribing != transcribing || old.color != color;
}

/// 播放三角。
class _PlayPainter extends CustomPainter {
  const _PlayPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(size.width * 0.18, size.height * 0.12)
      ..lineTo(size.width * 0.86, size.height * 0.5)
      ..lineTo(size.width * 0.18, size.height * 0.88)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PlayPainter old) => old.color != color;
}
