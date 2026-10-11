import 'package:flutter/material.dart';

import '../../core/theme/ink_tokens.dart';
import '../../core/widgets/ink/ink.dart';
import '../../root_gate.dart';

/// 启动页（Splash）—— v11「墨落」开场。
///
/// 母题「按下 → 墨落 → 渗开 → 显影」的**第 0 帧**：
/// 朱砂印章像被按下纸张一样落定（scale 回弹），外圈纸色渗开环一圈圈漾开，
/// 随后品牌题字浮上，整屏淡出接入 [RootGate]。
///
/// 动画时序（总 1.9s，单 AnimationController 分段驱动）：
///   0.00–0.50s  印章 scale 0.72→1.0（easeOutBack，带一点"盖下"的回弹）
///   0.00–0.22s  印章淡入
///   0.08–1.00s  纸色渗开环（两圈错相位）持续扩散淡出
///   0.34–0.74s  品牌名 + 题字淡入
///   0.88–1.00s  整屏淡出 → [RootGate]
///
/// 只跑 opacity / transform（合成器层动画，不触发重排）。
/// 无障碍：系统开「减弱动态效果」时直接跳根门。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 1900);

  late final AnimationController _controller;
  late final Animation<double> _sealScale;
  late final Animation<double> _sealOpacity;
  late final Animation<double> _bleed;
  late final Animation<double> _title;
  late final Animation<double> _screenOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total);

    _sealScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutBack),
      ),
    );
    _sealOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );
    _bleed = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 1.0, curve: Curves.easeOut),
    );
    _title = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.74, curve: Curves.easeOut),
    );
    _screenOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 1.0, curve: Curves.easeIn),
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
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, _, _) => const RootGate(),
        transitionsBuilder: (_, Animation<double> anim, _, Widget child) =>
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

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
      return const ColoredBox(color: Inks.ink);
    }

    return Scaffold(
      backgroundColor: Inks.ink,
      body: FadeTransition(
        opacity: _screenOpacity,
        child: InkSurface(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 268,
                  height: 268,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      // 渗开环：纸色的涟漪，从印心一圈圈漾开。
                      AnimatedBuilder(
                        animation: _bleed,
                        builder: (BuildContext context, Widget? child) {
                          return CustomPaint(
                            size: const Size.square(268),
                            painter: _BleedPainter(
                              t: _bleed.value,
                              color: Inks.paper,
                            ),
                          );
                        },
                      ),
                      // 朱砂印章：像被按下纸张一样落定。
                      FadeTransition(
                        opacity: _sealOpacity,
                        child: ScaleTransition(
                          scale: _sealScale,
                          child: const InkSeal(size: 86),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _title,
                  child: Text(
                    'AI 记忆卡',
                    style: TextStyle(
                      fontFamily: kSerif,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: Inks.paper,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _title,
                  child: Text(
                    '把每段声音，收进记忆',
                    style: TextStyle(
                      fontFamily: kMono,
                      fontSize: 11,
                      letterSpacing: 3,
                      color: Inks.paperDim,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 渗开环：两圈错相位纸色细环，随时间向外扩散并淡出。
class _BleedPainter extends CustomPainter {
  const _BleedPainter({required this.t, required this.color});

  /// 总进度 0~1。
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double maxR = size.width / 2;
    for (int i = 0; i < 2; i++) {
      final double p = (t * 1.35 + i * 0.46) % 1.0;
      final double r = maxR * (0.26 + p * 0.72);
      final double o = (1.0 - p) * (1.0 - p) * 0.40;
      if (o <= 0.01) continue;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = color.withValues(alpha: o),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BleedPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
