import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/ink_tokens.dart';

/// 录音键 = 一滴生墨（v11 的唯一签名元素，也是首页最容易被做烂的地方）。
///
/// 三层结构（自下而上）：
/// - **暖晕** `.glow`：录音态**全屏唯一**的发光物 —— 暖光从纸背透上来的一块晕，
///   没有边缘、没有高光点。待机 `opacity:0`（全屏零发光）。
/// - **渗晕①** `.bleed`：远而极淡（纸被浸湿的潮意）。有它才是「墨进了纸」。
/// - **渗晕②** `.wet-ring`：紧贴核外的窄湿痕。按下外扩 / 录音 `seep` 循环。
/// - **墨滴本体**：平涂浓色 + 真墨迹 alpha 蒙版（`ink-blot.png`），
///   **不做假高光**（一旦有受光面，就从「渗进纸的墨」变成「摆在纸上的球」）。
///
/// 四态：
/// - 待机：纯黑墨、零发光、无投影。
/// - 按下：墨 `scale(.92)` + 洇痕外扩 `1.09`（240ms）。
/// - 录音：墨在同色相内**提亮**（不换色）、换 `ink-wave.png` 毛刺蒙版、
///   洇痕 `seep` 循环外扩、暖晕呼吸。
///
/// 命中区刻意只有 [Inks.stampSize]（约 150），暖晕与渗晕都 `IgnorePointer`，
/// 不参与命中。
class InkStamp extends StatefulWidget {
  const InkStamp({super.key, required this.recording, required this.onTap});

  final bool recording;
  final VoidCallback onTap;

  @override
  State<InkStamp> createState() => _InkStampState();
}

class _InkStampState extends State<InkStamp>
    with SingleTickerProviderStateMixin {
  static const Duration _seepDur = Duration(milliseconds: 2600);

  late final AnimationController _seep =
      AnimationController(vsync: this, duration: _seepDur);
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.recording) _seep.repeat();
  }

  @override
  void didUpdateWidget(covariant InkStamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording && !_seep.isAnimating) {
      _seep.repeat();
    } else if (!widget.recording && _seep.isAnimating) {
      _seep.stop();
      _seep.value = 0;
    }
  }

  @override
  void dispose() {
    _seep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Inks.glowSize,
      height: Inks.glowSize,
      child: AnimatedBuilder(
        animation: _seep,
        builder: (BuildContext context, Widget? _) {
          final double v = _seep.value;
          // 呼吸：0.70 ↔ 1.0，与 seep 同步（2.6s）。
          final double breathe =
              0.70 + 0.30 * (0.5 - 0.5 * math.cos(v * 2 * math.pi));
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              // ① 暖晕（录音态唯一发光物；待机 0）
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: widget.recording ? 1 : 0,
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOut,
                  child: _glow(breathe),
                ),
              ),
              // ② 交互区（仅 stampSize 命中）
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                onTap: widget.onTap,
                child: SizedBox(
                  width: Inks.stampSize,
                  height: Inks.stampSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      // 渗晕①：远而极淡
                      IgnorePointer(
                        child: _seepAura(
                          size: Inks.bleedSize,
                          blur: 8,
                          color: Inks.seep,
                          opacity: 0.30,
                        ),
                      ),
                      // 渗晕②：紧贴核的湿痕（按下外扩 / 录音循环）
                      IgnorePointer(
                        child: Transform.scale(
                          scale: widget.recording
                              ? 1 + 0.17 * Curves.easeOut.transform(v)
                              : (_pressed ? 1.09 : 1.0),
                          child: Opacity(
                            opacity: widget.recording ? 0.9 * (1 - v) : 1.0,
                            child: _seepAura(
                              size: Inks.wetRingSize,
                              blur: 3,
                              color: Inks.seepCore,
                              opacity: 0.55,
                            ),
                          ),
                        ),
                      ),
                      // 墨滴本体
                      AnimatedScale(
                        scale: _pressed ? 0.92 : 1.0,
                        duration: const Duration(milliseconds: 240),
                        curve: const Cubic(0.2, 0.8, 0.2, 1),
                        child: _drop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  /// 暖晕：径向渐变（`closest-side` ≈ `radius: 0.5`）+ 模糊 7。
  /// **中心不是高光点**，是一个由内向外淡出的椭圆暖块 —— 读作「纸背透光」。
  Widget _glow(double breathe) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
      child: Container(
        width: Inks.glowSize,
        height: Inks.glowSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            radius: 0.5,
            stops: const <double>[0, 0.24, 0.44, 0.64, 0.84, 1],
            colors: <Color>[
              Inks.glow.withValues(alpha: 0.22 * breathe),
              Inks.glow.withValues(alpha: 0.22 * breathe),
              Inks.glow.withValues(alpha: 0.10 * breathe),
              Inks.glow.withValues(alpha: 0.024 * breathe),
              Inks.glow.withValues(alpha: 0),
              Inks.glow.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  /// 渗晕：同一墨迹蒙版放大 + 模糊 + 染色（形状跟着墨滴，天然不是同心圆）。
  Widget _seepAura({
    required double size,
    required double blur,
    required Color color,
    required double opacity,
  }) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Opacity(
        opacity: opacity,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: Image.asset(
            'assets/ink/ink-blot.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// 墨滴本体：待机 `ink-blot` ↔ 录音 `ink-wave`（毛刺），并在同色相内提亮。
  Widget _drop() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.recording ? 1 : 0),
      duration: const Duration(milliseconds: 240),
      builder: (BuildContext context, double t, Widget? child) {
        final Color c =
            Color.lerp(Inks.inkDrop, Inks.inkDropRec, t) ?? Inks.inkDrop;
        return ColorFiltered(
          colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
          child: child,
        );
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: Image.asset(
          widget.recording
              ? 'assets/ink/ink-wave.png'
              : 'assets/ink/ink-blot.png',
          key: ValueKey<bool>(widget.recording),
          width: Inks.stampSize,
          height: Inks.stampSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
