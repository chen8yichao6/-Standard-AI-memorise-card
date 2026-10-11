import 'package:flutter/material.dart';

import '../../theme/ink_tokens.dart';
import 'ink_fonts.dart';
import 'ink_panel.dart';

/// 「墨落」顶栏 —— 返回笔触 + 衬线标题 + 等宽副标，底部压一条发丝墨线。
///
/// 替代旧顶栏的「返回箭头 + 标题 + 竖分隔 + 等宽科目标」。
class InkAppBar extends StatelessWidget {
  const InkAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.tone = InkTone.dark,
    this.trailing,
    this.showDivider = true,
  });

  final String title;

  /// 右侧等宽小字（如 `PROFILE` / `SETTINGS`）。
  final String? subtitle;

  final VoidCallback? onBack;
  final InkTone tone;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final bool paper = tone == InkTone.paper;
    final Color fg = paper ? Inks.inkOnPaper : Inks.paper;
    final Color dim = paper ? Inks.inkOnPaperDim : Inks.paperDim;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 10),
          child: Row(
            children: <Widget>[
              if (onBack != null) ...<Widget>[
                InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(2),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: dim,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: fg,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 12,
                  color: dim.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: kMono,
                    fontSize: 10.5,
                    letterSpacing: 1.4,
                    color: dim,
                  ),
                ),
              ],
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkHairline(tone: tone),
          ),
      ],
    );
  }
}
