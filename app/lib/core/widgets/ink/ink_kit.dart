import 'package:flutter/material.dart';

import '../../theme/ink_tokens.dart';
import 'ink_fonts.dart';
import 'ink_panel.dart';

/// 朱砂印章 —— 全 App 的品牌印记。默认「记」，方角微旋，像真盖上去的。
class InkSeal extends StatelessWidget {
  const InkSeal({super.key, this.size = 38, this.text = '记'});

  final double size;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.035, // ≈ -2deg
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Inks.seal,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(3),
            bottomLeft: Radius.circular(1),
            bottomRight: Radius.circular(3),
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: Inks.sealPaper.withValues(alpha: 0.85)),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: size * 0.52,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: Inks.sealPaper,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 区块小标题 —— 一道短墨线 + 衬线小字（替代旧 `HudLabel`）。
class InkSectionLabel extends StatelessWidget {
  const InkSectionLabel(
    this.text, {
    super.key,
    this.tone = InkTone.dark,
    this.trailing,
    this.expand = false,
  });

  final String text;
  final InkTone tone;
  final Widget? trailing;

  /// 撑满宽度并在右侧接一条延伸发丝线（区块标题用）。
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bool paper = tone == InkTone.paper;
    final Color fg = paper ? Inks.inkOnPaperSoft : Inks.paperSoft;
    final Color line = paper
        ? Inks.inkOnPaper.withValues(alpha: 0.16)
        : Inks.paper.withValues(alpha: 0.14);
    final bool grow = expand || trailing != null;

    return Row(
      mainAxisSize: grow ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Container(width: 2.4, height: 12, color: fg),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: fg,
          ),
        ),
        if (trailing != null) ...<Widget>[
          const Spacer(),
          trailing!,
        ] else if (grow) ...<Widget>[
          const SizedBox(width: 10),
          Expanded(child: Container(height: 0.8, color: line)),
        ],
      ],
    );
  }
}

/// 主按钮 —— 朱砂底 + 印上字（方角，无圆角无阴影）。
class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null && !loading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? Inks.seal : Inks.inkSoft,
            border: Border.all(
              color: enabled
                  ? Inks.seal
                  : Inks.paper.withValues(alpha: 0.16),
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Inks.sealPaper,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontFamily: kSerif,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: enabled ? Inks.sealPaper : Inks.paperDim,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 输入框 —— 标签（等宽小字）+ 下划线墨线（不用圆角描边框）。
class InkTextField extends StatelessWidget {
  const InkTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.tone = InkTone.paper,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final InkTone tone;

  @override
  Widget build(BuildContext context) {
    final bool paper = tone == InkTone.paper;
    final Color fg = paper ? Inks.inkOnPaper : Inks.paper;
    final Color dim = paper ? Inks.inkOnPaperDim : Inks.paperDim;
    final Color line = paper
        ? Inks.inkOnPaper.withValues(alpha: 0.20)
        : Inks.paper.withValues(alpha: 0.18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontFamily: kMono,
            fontSize: 10.5,
            letterSpacing: 1.6,
            color: dim,
          ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: TextStyle(fontFamily: kSerif, fontSize: 15, color: fg),
          cursorColor: Inks.seal,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: kSerif, fontSize: 14, color: dim),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: line),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Inks.seal, width: 1.4),
            ),
            border: UnderlineInputBorder(borderSide: BorderSide(color: line)),
          ),
        ),
      ],
    );
  }
}

/// 元信息标签 —— `DATE / 09-28` 小框（替代旧 `_MetaChip`）。
class InkTag extends StatelessWidget {
  const InkTag({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.tone = InkTone.dark,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final InkTone tone;

  @override
  Widget build(BuildContext context) {
    final bool paper = tone == InkTone.paper;
    final Color fg = paper ? Inks.inkOnPaper : Inks.paper;
    final Color dim = paper ? Inks.inkOnPaperDim : Inks.paperDim;
    final Color line = paper
        ? Inks.inkOnPaper.withValues(alpha: 0.16)
        : Inks.paper.withValues(alpha: 0.14);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontFamily: kMono,
              fontSize: 9.5,
              letterSpacing: 1.2,
              color: dim,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: kMono,
              fontSize: 11.5,
              color: valueColor ?? fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// 圆形墨印头像 —— 有图显示图，无图显示首字。替代旧的切角八边形 `MechAvatar`。
class InkAvatar extends StatelessWidget {
  const InkAvatar({
    super.key,
    this.size = 40,
    this.onTap,
    this.imageUrl,
    this.fallbackText,
  });

  final double size;
  final VoidCallback? onTap;

  /// 网络头像地址（契约 §1.5/§1.7：`avatar_url` 为 presigned，**15 分钟有效**，不做缓存）。
  final String? imageUrl;

  /// 无图时的兜底首字（通常取昵称/邮箱首字）。
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    final Widget core;
    if (url != null && url.isNotEmpty) {
      core = ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // presigned 过期 / 网络故障 → 回退首字态，不留白块。
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    } else {
      core = _fallback();
    }

    final Widget framed = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Inks.paper.withValues(alpha: 0.22)),
      ),
      child: core,
    );

    if (onTap == null) return framed;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: framed,
      ),
    );
  }

  Widget _fallback() {
    final String t = (fallbackText ?? '').trim();
    return Container(
      width: size,
      height: size,
      color: Inks.inkSoft,
      alignment: Alignment.center,
      child: t.isEmpty
          ? Icon(Icons.person_outline, size: size * 0.44, color: Inks.paperDim)
          : Text(
              t[0],
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: size * 0.40,
                fontWeight: FontWeight.w700,
                color: Inks.paperSoft,
              ),
            ),
    );
  }
}
