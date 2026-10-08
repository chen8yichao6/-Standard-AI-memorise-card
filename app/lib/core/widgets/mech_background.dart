import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_spec.dart';

/// 「深蓝赛博」背景 —— 全 App 统一的底。
///
/// 四层叠加（全部程序化绘制，不依赖图片素材）：
/// 1. 深蓝纯底 `#0E1C30`；
/// 2. 左上青 / 右下蓝两枚径向光晕（制造纵深，替代死平的黑）；
/// 3. 极淡的横向扫描线（CRT / HUD 质感）—— 上一版是 45° 斜网格且透明度过低，
///    肉眼看不见等于没画，这次改横向且让它可以被看见；
/// 4. 四角机械角标（切角框，红魔那类硬件的边角语言）。
///
/// 注意：本组件是**静态**的（`shouldRepaint => false`），只画一次。
/// 会动的部分（扫描光带）单独放在 [ScanSweep] 里，避免每帧重绘几百条线导致卡顿。
class MechBackground extends StatelessWidget {
  const MechBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // 传 spec 给 painter：主题切换后 spec.id 变化，shouldRepaint 返回 true 才会重画，
    // 否则「底色变了、光晕还停在旧主题色」画面发脏（2026-10-08 主题层改造发现）。
    return ColoredBox(
      color: AppTheme.bg,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BgPainter(spec: AppTheme.spec),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  const _BgPainter({required this.spec});

  final ThemeSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect full = Rect.fromLTWH(0, 0, size.width, size.height);
    _paintGlow(canvas, size, full);
    _paintScanLines(canvas, size);
    _paintEdgeVignette(canvas, size, full);
    _paintCornerMarks(canvas, size);
  }

  /// 两枚径向光晕：左上主色、右下结构色。
  void _paintGlow(Canvas canvas, Size size, Rect full) {
    final Paint topLeft = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          spec.primary.withValues(alpha: 0.13),
          spec.primary.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.10, -size.height * 0.02),
          radius: size.width * 0.95,
        ),
      );
    canvas.drawRect(full, topLeft);

    final Paint bottomRight = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          spec.accent.withValues(alpha: 0.14),
          spec.accent.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.95, size.height * 0.98),
          radius: size.width * 1.0,
        ),
      );
    canvas.drawRect(full, bottomRight);
  }

  /// 横向扫描线。每 5px 一条，透明度控制在「看得见但不抢戏」。
  void _paintScanLines(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = spec.primary.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    const double step = 5.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  /// 四周压暗，把视线收到中间（不用 blur，纯线性渐变）。
  void _paintEdgeVignette(Canvas canvas, Size size, Rect full) {
    final Paint v = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          spec.bgDeep.withValues(alpha: 0.55),
          spec.bgDeep.withValues(alpha: 0.0),
          spec.bgDeep.withValues(alpha: 0.0),
          spec.bgDeep.withValues(alpha: 0.65),
        ],
        stops: const <double>[0.0, 0.16, 0.72, 1.0],
      ).createShader(full);
    canvas.drawRect(full, v);
  }

  /// 四角机械角标（每角两条短线，形成不闭合的切角框）。
  void _paintCornerMarks(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = spec.primary.withValues(alpha: 0.34)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square;
    const double len = 20;
    const double pad = 12;
    final double w = size.width;
    final double h = size.height;

    // 左上
    canvas.drawLine(Offset(pad, pad), Offset(pad + len, pad), paint);
    canvas.drawLine(Offset(pad, pad), Offset(pad, pad + len), paint);
    // 右上
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad - len, pad), paint);
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad, pad + len), paint);
    // 左下
    canvas.drawLine(Offset(pad, h - pad), Offset(pad + len, h - pad), paint);
    canvas.drawLine(Offset(pad, h - pad), Offset(pad, h - pad - len), paint);
    // 右下
    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad - len, h - pad), paint);
    canvas.drawLine(Offset(w - pad, h - pad), Offset(w - pad, h - pad - len), paint);
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) =>
      oldDelegate.spec.id != spec.id;
}

/// 扫描光带 —— 一条青色亮线自上而下循环扫过，制造「设备正在运行」的动感。
///
/// 只画一条线 + 一层薄尾迹，成本极低（对比每帧重绘几百条扫描线）。
/// [period] 是一次完整往返的时长；[opacity] 控制存在感。
class ScanSweep extends StatefulWidget {
  const ScanSweep({
    super.key,
    this.period = const Duration(seconds: 4),
    this.opacity = 0.55,
  });

  final Duration period;
  final double opacity;

  @override
  State<ScanSweep> createState() => _ScanSweepState();
}

class _ScanSweepState extends State<ScanSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              painter: _SweepPainter(t: _c.value, opacity: widget.opacity),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  const _SweepPainter({required this.t, required this.opacity});

  final double t;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height * t;
    const double tail = 90;

    // 尾迹：从亮线往上渐隐的一段
    final Paint trail = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          AppTheme.primary.withValues(alpha: 0.0),
          AppTheme.primary.withValues(alpha: 0.10 * opacity),
        ],
      ).createShader(Rect.fromLTWH(0, y - tail, size.width, tail));
    canvas.drawRect(Rect.fromLTWH(0, y - tail, size.width, tail), trail);

    // 主线
    final Paint line = Paint()
      ..color = AppTheme.primaryBright.withValues(alpha: 0.42 * opacity)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.opacity != opacity;
}
