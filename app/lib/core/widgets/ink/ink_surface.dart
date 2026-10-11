import 'package:flutter/material.dart';

import '../../theme/ink_tokens.dart';

/// 「墨落」全屏底 —— 暗房：墨黑底 + 胶片颗粒 + 镜头暗角。
///
/// 替代旧「深蓝赛博」的 `MechBackground`（网格 + 扫描线 + 青光）。
/// 约定：**颗粒与暗角只属于暗房**。生宣（纸上）内容请自带
/// `InkPanel(tone: InkTone.paper)`，不要把颗粒铺到纸上。
class InkSurface extends StatelessWidget {
  const InkSurface({
    super.key,
    required this.child,
    this.grainOpacity = 0.08,
    this.vignette = true,
  });

  /// 页内容。会铺满全屏（内部自行 SafeArea）。
  final Widget child;

  /// 颗粒强度。默认与首页暗房一致（1:1 tile + 低透明度）。
  final double grainOpacity;

  /// 是否叠镜头暗角（中心透、四角沉）。
  final bool vignette;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: Inks.ink)),
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: grainOpacity,
              child: Image.asset(
                'assets/ink/film-grain-dark.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        ),
        if (vignette)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.95,
                    center: const Alignment(0, -0.1),
                    stops: const <double>[0, 0.5, 1],
                    colors: <Color>[
                      const Color(0x00000000),
                      const Color(0x00000000),
                      Colors.black.withValues(alpha: 0.36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(child: child),
      ],
    );
  }
}
