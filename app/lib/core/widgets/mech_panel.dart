import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 切角矩形裁剪 —— 机械感标志性的四角切角（45°，形成八边形）。
///
/// 用于「无点击」的展示面板（启动页中央框、雷达占位等），
/// 因为 ClipPath 会裁掉 InkWell 的水波纹，点击类卡片请用 [MechPanel]。
class ChamferClipper extends CustomClipper<Path> {
  const ChamferClipper({this.cut = 10});

  final double cut;

  @override
  Path getClip(Size size) {
    final double c = cut.clamp(0.0, size.shortestSide / 2);
    return Path()
      ..moveTo(c, 0)
      ..lineTo(size.width - c, 0)
      ..lineTo(size.width, c)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(c, size.height)
      ..lineTo(0, size.height - c)
      ..lineTo(0, c)
      ..close();
  }

  @override
  bool shouldReclip(ChamferClipper oldDelegate) => oldDelegate.cut != cut;
}

/// 机械面板 —— 直角描边 + 斜向金属渐变 + 顶部受光边 + 可选装饰。
///
/// 2026-10-03 升级（用户反馈「质感太平、不机械」）：
/// 上一版只是「深色填充 + 一圈边框」，看着像贴纸。现在加三样东西做出厚度：
/// 1. `panelGradient` 斜向渐变（左上受光 → 右下背光）；
/// 2. 顶边 1px 高光线（模拟金属受光的锐利边缘）；
/// 3. 可选的左侧装甲槽 / 角标 / 铆钉点。
class MechPanel extends StatelessWidget {
  const MechPanel({
    super.key,
    required this.child,
    this.onTap,
    this.accentBar = false,
    this.cornerTag = false,
    this.raised = false,
    this.active = false,
    this.padding = const EdgeInsets.all(16),
    this.bolts = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  /// 左侧一条青色竖条（标记「当前项」）。
  final bool accentBar;
  /// 左上角青色切角三角。
  final bool cornerTag;
  /// 浮起一档（更亮的渐变）。
  final bool raised;
  /// 激活态：描边转亮 + 外发光。
  final bool active;
  final EdgeInsetsGeometry padding;
  /// 左上 / 右下各加一颗铆钉点。
  final bool bolts;

  @override
  Widget build(BuildContext context) {
    final Widget inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient(raised: raised || active),
        border: Border.all(color: active ? AppTheme.borderStrong : AppTheme.border),
        boxShadow: active ? AppTheme.glow() : null,
      ),
      child: Stack(
        children: <Widget>[
          // 顶部受光边
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 1, color: AppTheme.highlight),
          ),
          if (bolts) ...<Widget>[
            const Positioned(top: 6, right: 6, child: MechBolt()),
            const Positioned(bottom: 6, left: 6, child: MechBolt()),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (accentBar) ...<Widget>[
                Container(
                  width: 3,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[AppTheme.primaryBright, AppTheme.primaryDim],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.gapSm),
              ],
              Expanded(child: child),
            ],
          ),
        ],
      ),
    );

    final Widget panel = cornerTag
        ? Stack(
            children: <Widget>[
              inner,
              const Positioned(top: 0, left: 0, child: MechCornerTag()),
            ],
          )
        : inner;

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: panel),
      );
    }
    return panel;
  }
}

/// 左上角青色切角三角 —— 面板角标（等腰直角三角，直角在左上）。
class MechCornerTag extends StatelessWidget {
  const MechCornerTag({super.key, this.size = 12});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CornerTagPainter()),
    );
  }
}

class _CornerTagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppTheme.primary;
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 铆钉点 —— 4px 小圆 + 内高光，做金属细节。
class MechBolt extends StatelessWidget {
  const MechBolt({super.key, this.size = 4});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.borderStrong,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35), width: 0.5),
      ),
    );
  }
}
