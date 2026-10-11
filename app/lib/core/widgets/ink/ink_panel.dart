import 'package:flutter/material.dart';

import '../../theme/ink_tokens.dart';

/// 面板色调：暗房（墨底纸字）／生宣（纸底墨字）。
enum InkTone { dark, paper }

/// 「墨落」面板 —— 方角 + 发丝边，纸上态自带生宣纸纹。
///
/// 替代旧 `MechPanel`（切角 + 机械螺栓 + 面板渐变）。这里刻意**不用圆角、不用阴影**：
/// 纸与墨之间以一条发丝线交代边界，靠留白而非厚度分层。
class InkPanel extends StatelessWidget {
  const InkPanel({
    super.key,
    required this.child,
    this.tone = InkTone.dark,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.accent = false,
  });

  final Widget child;
  final InkTone tone;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// 左缘一道朱砂竖线。**只用于「当前选中 / 进行中」这类语义**，别当纯装饰。
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final bool paper = tone == InkTone.paper;
    final Color bg = paper ? Inks.sheetBg : Inks.inkSoft;
    final Color line = paper
        ? Inks.inkOnPaper.withValues(alpha: 0.14)
        : Inks.paper.withValues(alpha: 0.10);

    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(2),
        image: paper
            ? const DecorationImage(
                image: AssetImage('assets/ink/paper.jpg'),
                fit: BoxFit.cover,
                opacity: 0.55,
              )
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (accent) {
      body = Stack(
        children: <Widget>[
          body,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 2.4, color: Inks.seal),
          ),
        ],
      );
    }

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: body,
      ),
    );
  }
}

/// 发丝分隔线 —— 墨落版 Divider。
class InkHairline extends StatelessWidget {
  const InkHairline({super.key, this.tone = InkTone.dark, this.indent = 0});

  final InkTone tone;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final Color c = tone == InkTone.paper
        ? Inks.inkOnPaper.withValues(alpha: 0.12)
        : Inks.paper.withValues(alpha: 0.10);
    return Container(
      height: 0.8,
      margin: EdgeInsets.only(left: indent),
      color: c,
    );
  }
}
