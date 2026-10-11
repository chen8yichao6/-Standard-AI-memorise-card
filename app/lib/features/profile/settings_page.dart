import 'package:flutter/material.dart';

import '../../core/theme/app_theme_controller.dart';
import '../../core/theme/ink_tokens.dart';
import '../../core/theme/theme_spec.dart';
import '../../core/widgets/ink/ink.dart';

/// 设置页（P1a）—— 从个人页「设置」进入。v11「墨落」换装。
///
/// 本期只做一项：**主题更换**（PRD §3.2 F-06 / F-07 / F-08）。
/// - 列出开发者上传的主题（[ThemeSpec.all]，本期内置两套）；
/// - 当前生效那套显示选中态（左缘朱砂竖线 + 「当前」标记）；
/// - 点选另一套 → [AppThemeController.setTheme] → 全 App 立即换色 + 本地持久化。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Inks.ink,
      body: InkSurface(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              InkAppBar(
                title: '设置',
                subtitle: 'SETTINGS',
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  children: <Widget>[
                    const InkSectionLabel('主题', expand: true),
                    const SizedBox(height: 10),
                    Text(
                      '开发者上传 · 用户只选',
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 12,
                        color: Inks.paperDim,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 监听控制器：切主题后重建，选中态跟着变。
                    ListenableBuilder(
                      listenable: AppThemeController.instance,
                      builder: (BuildContext context, Widget? child) {
                        return Column(
                          children: <Widget>[
                            for (final ThemeSpec theme in ThemeSpec.all) ...<Widget>[
                              _ThemeCard(theme: theme),
                              if (theme != ThemeSpec.all.last)
                                const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 一套主题的选择卡片：色块预览 + 主题名 + 选中态（左缘朱砂竖线 + 「当前」）。
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme});

  final ThemeSpec theme;

  @override
  Widget build(BuildContext context) {
    final bool active = AppThemeController.instance.spec.id == theme.id;

    return InkPanel(
      tone: InkTone.dark,
      onTap: () => AppThemeController.instance.setTheme(theme.id),
      accent: active,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: <Widget>[
          // 色块预览：用该主题的底色 + 主色，直观看到「这套长什么样」。
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.bg,
              border: Border.all(color: theme.border),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.primary,
                  border: Border.all(color: theme.primaryBright, width: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  theme.name,
                  style: TextStyle(
                    fontFamily: kSerif,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Inks.paper,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  theme.id,
                  style: TextStyle(
                    fontFamily: kMono,
                    fontSize: 10.5,
                    color: Inks.paperDim,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (active)
            Text(
              '当前',
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Inks.seal,
              ),
            )
          else
            Icon(
              Icons.chevron_right,
              color: Inks.paper.withValues(alpha: 0.35),
              size: 18,
            ),
        ],
      ),
    );
  }
}
