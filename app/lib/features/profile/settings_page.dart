import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_controller.dart';
import '../../core/theme/theme_spec.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/mech_background.dart';
import '../../core/widgets/mech_panel.dart';

/// 设置页（P1a）—— 从个人页「设置」进入。
///
/// 本期只做一项：**主题更换**（PRD §3.2 F-06 / F-07 / F-08）。
/// - 列出开发者上传的主题（[ThemeSpec.all]，本期内置两套）；
/// - 当前生效那套显示选中态；
/// - 点选另一套 → [AppThemeController.setTheme] → 全 App 立即换色 + 本地持久化。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MechBackground()),
          SafeArea(
            child: Column(
              children: <Widget>[
                _TopBar(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    children: <Widget>[
                      const HudLabel('主题', expand: true),
                      const SizedBox(height: AppTheme.gapXs),
                      Text(
                        '开发者上传 · 用户只选',
                        style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
                      ),
                      const SizedBox(height: AppTheme.gapMd),
                      // 监听控制器：切主题后重建，选中态跟着变。
                      ListenableBuilder(
                        listenable: AppThemeController.instance,
                        builder: (BuildContext context, Widget? child) {
                          return Column(
                            children: <Widget>[
                              for (final ThemeSpec theme in ThemeSpec.all) ...<Widget>[
                                _ThemeCard(theme: theme),
                                if (theme != ThemeSpec.all.last)
                                  const SizedBox(height: AppTheme.gapSm),
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
          const Positioned.fill(child: ScanSweep()),
        ],
      ),
    );
  }
}

/// 一套主题的选择卡片：色块预览 + 主题名 + 选中态。
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme});

  final ThemeSpec theme;

  @override
  Widget build(BuildContext context) {
    final bool active = AppThemeController.instance.spec.id == theme.id;

    return MechPanel(
      onTap: () => AppThemeController.instance.setTheme(theme.id),
      active: active,
      accentBar: active,
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
          const SizedBox(width: AppTheme.gapSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(theme.name, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppTheme.gapXxs),
                Text(
                  theme.id,
                  style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.gapXs),
          if (active) ...<Widget>[
            const PulseDot(size: 6),
            const SizedBox(width: AppTheme.gapXs),
            Text(
              '当前',
              style: AppTheme.micro.copyWith(color: AppTheme.primary),
            ),
          ] else
            Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 18),
        ],
      ),
    );
  }
}

/// 设置页顶栏：返回箭头 + 标题。
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 10),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.arrow_back, color: AppTheme.textSecondary, size: 22),
            ),
          ),
          const SizedBox(width: AppTheme.gapXs),
          Text('设置', style: AppTheme.title),
          const SizedBox(width: AppTheme.gapXs),
          Container(width: 1, height: 14, color: AppTheme.border),
          const SizedBox(width: AppTheme.gapXs),
          Text('SETTINGS', style: AppTheme.micro),
        ],
      ),
    );
  }
}
