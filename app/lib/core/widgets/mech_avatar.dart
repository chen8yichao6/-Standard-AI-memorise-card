import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_spec.dart';

/// 程序化切角头像 —— 机械感的「几何人像」。
///
/// 本 App 零图片素材（`app/assets/` 已删），头像只能用 CustomPainter 画：
/// 切角八边形底 + 主色「头 + 肩」剪影。顶栏小号（30）与个人页大号（72）复用同一组件。
class MechAvatar extends StatelessWidget {
  const MechAvatar({super.key, this.size = 40, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = SizedBox(
      width: size,
      height: size,
      // 传 spec：主题切换后 spec.id 变化触发重画（头像颜色随主题变）。
      child: CustomPaint(painter: _AvatarPainter(spec: AppTheme.spec)),
    );

    if (onTap == null) return avatar;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: avatar,
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter({required this.spec});

  final ThemeSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double cut = s * 0.22;

    // 切角八边形底（与 MechPanel 同款机械切角）。
    final Path frame = Path()
      ..moveTo(cut, 0)
      ..lineTo(s - cut, 0)
      ..lineTo(s, cut)
      ..lineTo(s, s - cut)
      ..lineTo(s - cut, s)
      ..lineTo(cut, s)
      ..lineTo(0, s - cut)
      ..lineTo(0, cut)
      ..close();

    final Paint fill = Paint()..color = spec.surfaceRaised;
    canvas.drawPath(frame, fill);
    final Paint stroke = Paint()
      ..color = spec.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(frame, stroke);

    // 头 + 肩剪影。
    final Paint fg = Paint()..color = spec.primary;
    canvas.drawCircle(Offset(s / 2, s * 0.34), s * 0.15, fg);
    final Path shoulder = Path()
      ..moveTo(s * 0.18, s * 0.96)
      ..quadraticBezierTo(s * 0.5, s * 0.52, s * 0.82, s * 0.96)
      ..close();
    canvas.drawPath(shoulder, fg);
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.spec.id != spec.id;
}
