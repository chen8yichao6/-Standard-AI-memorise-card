import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_spec.dart';

/// 程序化切角头像 —— 机械感的「几何人像」。
///
/// 本 App 零图片素材（`app/assets/` 已删），**无头像时**用 CustomPainter 画：
/// 切角八边形底 + 主色「头 + 肩」剪影。顶栏小号（30）与个人页大号（72）复用同一组件。
///
/// 传了 [imageUrl] 则显示真实头像（`avatar_url`），加载失败仍降级为几何人像。
class MechAvatar extends StatelessWidget {
  const MechAvatar({super.key, this.size = 40, this.onTap, this.imageUrl});

  final double size;
  final VoidCallback? onTap;

  /// 网络头像地址（契约 §1.5/§1.7：`avatar_url` 为 presigned，**15 分钟有效**）。
  /// 契约明确要求前端不得缓存超过 15 分钟，故本组件不做任何缓存。
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final Widget painted = SizedBox(
      width: size,
      height: size,
      // 传 spec：主题切换后 spec.id 变化触发重画（头像颜色随主题变）。
      child: CustomPaint(painter: _AvatarPainter(spec: AppTheme.spec)),
    );

    final String? url = imageUrl;
    final Widget avatar;
    if (url != null && url.isNotEmpty) {
      avatar = ClipPath(
        clipper: const _OctagonClipper(),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // presigned 过期 / 网络故障 → 回退几何人像，不留白块。
          errorBuilder: (_, __, ___) => painted,
        ),
      );
    } else {
      avatar = painted;
    }

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

/// 与 [_AvatarPainter] 同款切角八边形，用于裁剪网络头像图。
class _OctagonClipper extends CustomClipper<Path> {
  const _OctagonClipper();

  @override
  Path getClip(Size size) {
    final double s = size.width;
    final double cut = s * 0.22;
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(s - cut, 0)
      ..lineTo(s, cut)
      ..lineTo(s, s - cut)
      ..lineTo(s - cut, s)
      ..lineTo(cut, s)
      ..lineTo(0, s - cut)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  bool shouldReclip(covariant _OctagonClipper oldClipper) => false;
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
