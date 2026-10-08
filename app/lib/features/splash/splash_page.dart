import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/mech_background.dart';
import '../../root_gate.dart';

/// 启动页（Splash）—— 深蓝赛博 · 自检过场。
///
/// 2026-10-03 重做（用户反馈「动画不够动感」）。上一版只有「框淡入 + 一条线扫过 + 文字淡入」，
/// 信息量太少、不像设备在启动。这一版加了**进度回读**：
///
/// 动画时序（总时长 1.6s，单 AnimationController 分段驱动）：
///   0.00–0.18s  中央切角框淡入 + 轻微缩放
///   0.06–0.86s  青色扫描线自上而下扫过框内
///   0.08–0.88s  进度数字 0→100 跳动 + 进度条推进 + 状态文字三段切换
///   0.86–1.00s  整屏淡出 → 切首页
///
/// 只用 opacity / transform / 一个数字重绘（合成器层动画，不触发重排）。
/// 无障碍：系统开「减弱动态效果」时直接跳首页。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 1600);

  late final AnimationController _controller;
  late final Animation<double> _frameOpacity;
  late final Animation<double> _frameScale;
  late final Animation<double> _scan;
  late final Animation<double> _progress;
  late final Animation<double> _screenOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total);

    _frameOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
    );
    _frameScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOutCubic),
      ),
    );
    _scan = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.06, 0.86, curve: Curves.easeInOut),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.88, curve: Curves.easeOutCubic),
    );
    _screenOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.86, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _goHome();
  }

  /// 切根路由门。用 pushReplacement —— 启动页不留在返回栈里。
  /// 后续进登录页还是首页，由 [RootGate] 按登录态决定。
  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => const RootGate(),
        transitionsBuilder: (_, Animation<double> anim, __, Widget child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  /// 三段状态文字，随进度切换 —— 模拟设备自检的输出。
  String _stage(double v) {
    if (v < 0.35) return '初始化本地存储';
    if (v < 0.72) return '装载录音索引';
    return '就绪';
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
      return ColoredBox(color: AppTheme.bg);
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FadeTransition(
        opacity: _screenOpacity,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: MechBackground()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ScaleTransition(
                    scale: _frameScale,
                    child: FadeTransition(
                      opacity: _frameOpacity,
                      child: _LogoFrame(scan: _scan),
                    ),
                  ),
                  const SizedBox(height: AppTheme.gapXl),
                  _ProgressBlock(progress: _progress, stage: _stage),
                ],
              ),
            ),
            // 左下角：品牌 + 版本（HUD 角标）
            Positioned(
              left: 20,
              bottom: 22,
              child: Text(
                'MEMORY UNIT · v0.1.0',
                style: AppTheme.micro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 中央 logo 框：切角描边 + 青色扫描线 + 品牌文案。
class _LogoFrame extends StatelessWidget {
  const _LogoFrame({required this.scan});

  final Animation<double> scan;

  static const double _w = 244;
  static const double _h = 152;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _w,
      height: _h,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: const _ChamferBorderPainter()),
          ),
          // 扫描线
          AnimatedBuilder(
            animation: scan,
            builder: (BuildContext context, Widget? child) {
              return Positioned(
                top: scan.value * _h,
                left: 2,
                right: 2,
                child: Container(
                  height: 1.6,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    boxShadow: AppTheme.glow(color: AppTheme.primary, opacity: 0.5),
                  ),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'AI 记忆卡',
                  style: AppTheme.display,
                ),
                const SizedBox(height: AppTheme.gapSm),
                Text(
                  '把每段声音，收进记忆',
                  style: AppTheme.mono.copyWith(
                    color: AppTheme.textSecondary,
                    letterSpacing: 2.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 进度块：大号等宽百分比 + 进度条 + 状态文字。
class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.progress, required this.stage});

  final Animation<double> progress;
  final String Function(double) stage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 244,
      child: AnimatedBuilder(
        animation: progress,
        builder: (BuildContext context, Widget? child) {
          final double v = progress.value;
          final int pct = (v * 100).round();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    pct.toString().padLeft(3, '0'),
                    style: AppTheme.numeralLarge.copyWith(fontSize: 40),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '%',
                      style: AppTheme.mono.copyWith(
                        color: AppTheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      stage(v),
                      style: AppTheme.micro,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.gapXs),
              // 进度条：暗槽 + 青色已推进段
              Container(
                height: 3,
                color: AppTheme.bgDeep,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: v.clamp(0.0, 1.0),
                    child: Container(color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 切角描边（只描边，不填充）+ 四角小刻度。
class _ChamferBorderPainter extends CustomPainter {
  const _ChamferBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double c = 16.0;
    final Path p = Path()
      ..moveTo(c, 0)
      ..lineTo(size.width - c, 0)
      ..lineTo(size.width, c)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(c, size.height)
      ..lineTo(0, size.height - c)
      ..lineTo(0, c)
      ..close();
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppTheme.primary.withValues(alpha: 0.85),
    );

    // 四角外扩的小刻度（机械角标）
    final Paint tick = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.45)
      ..strokeWidth = 1.4;
    const double pad = 6;
    const double len = 9;
    canvas.drawLine(Offset(pad, pad), Offset(pad + len, pad), tick);
    canvas.drawLine(Offset(pad, pad), Offset(pad, pad + len), tick);
    canvas.drawLine(
        Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad - len, size.height - pad),
        tick);
    canvas.drawLine(
        Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad, size.height - pad - len),
        tick);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
