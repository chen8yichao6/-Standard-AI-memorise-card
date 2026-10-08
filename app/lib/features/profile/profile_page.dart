import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/mech_avatar.dart';
import '../../core/widgets/mech_background.dart';
import '../../core/widgets/mech_panel.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../auth/models/user.dart';
import 'settings_page.dart';

/// 个人页面（P1）—— 从首页右上角头像进入。
///
/// 本期范围（PRD §3.1）：
/// - 顶部头像占位 + 昵称 + 邮箱（数据来自登录态 [AuthController]，真数据）；
/// - 三个入口：账号 / 设置 / 关于；
/// - 退出登录（红字，二次确认 → 真登出，清凭证回登录页）。
///
/// 「账号」子页排在步 3 建，本页先占位提示；
/// 「设置」子页已建（主题更换）；「关于」直接弹窗展示，不建子页。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// 当前登录用户（未登录时为 null）。
  User? get _user {
    final AuthState state = AuthController.instance.value;
    return state is AuthAuthenticated ? state.user : null;
  }

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
                      _buildProfileCard(),
                      const SizedBox(height: AppTheme.gapXl),
                      const HudLabel('账户与设置', expand: true),
                      const SizedBox(height: AppTheme.gapSm),
                      MechPanel(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: <Widget>[
                            _EntryTile(
                              icon: Icons.person_outline,
                              title: '账号',
                              subtitle: _user?.email ?? '—',
                              onTap: () => _showTodo(context, '账号区下一板块接入'),
                            ),
                            const _EntryDivider(),
                            _EntryTile(
                              icon: Icons.palette_outlined,
                              title: '设置',
                              subtitle: '主题更换',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsPage(),
                                ),
                              ),
                            ),
                            const _EntryDivider(),
                            _EntryTile(
                              icon: Icons.info_outline,
                              title: '关于',
                              subtitle: 'v0.1.0',
                              onTap: () => _showAbout(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.gapSm),
                      MechPanel(
                        onTap: () => _confirmLogout(context),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.logout, color: AppTheme.danger, size: 18),
                            SizedBox(width: AppTheme.gapXs),
                            Text(
                              '退出登录',
                              style: TextStyle(
                                color: AppTheme.danger,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildProfileCard() {
    final User? user = _user;
    return MechPanel(
      raised: true,
      bolts: true,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: <Widget>[
          const MechAvatar(size: 72),
          const SizedBox(width: AppTheme.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user?.nickname ?? '未登录',
                  style: AppTheme.title.copyWith(fontSize: 20),
                ),
                const SizedBox(height: AppTheme.gapXxs),
                Text(
                  user?.email ?? '账号区待接入',
                  style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          Text('P1', style: AppTheme.micro),
        ],
      ),
    );
  }

  void _showTodo(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: BorderSide(color: AppTheme.borderStrong),
          ),
          title: Text(
            'AI 记忆卡',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'v0.1.0',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              SizedBox(height: AppTheme.gapSm),
              Text(
                '把每一段声音，沉淀成可调用的记忆。',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: BorderSide(color: AppTheme.borderStrong),
          ),
          title: Text(
            '确认退出登录？',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 17),
          ),
          content: Text(
            '退出后将清除本地登录凭证，回到登录页。',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthController.instance.logout();
                if (context.mounted) {
                  // 回到根（此时 RootGate 已切换为登录页）。
                  Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
                }
              },
              child: Text('退出', style: TextStyle(color: AppTheme.danger)),
            ),
          ],
        );
      },
    );
  }
}

/// 个人页顶栏：返回箭头 + 标题。
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
              child: Icon(
                Icons.arrow_back,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.gapXs),
          Text('个人中心', style: AppTheme.title),
          const SizedBox(width: AppTheme.gapXs),
          Container(width: 1, height: 14, color: AppTheme.border),
          const SizedBox(width: AppTheme.gapXs),
          Text('PROFILE', style: AppTheme.micro),
        ],
      ),
    );
  }
}

/// 一个入口行：图标 + 标题 + 右侧副文字 + 箭头。
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: AppTheme.gapSm),
            Expanded(
              child: Text(
                title,
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (subtitle != null) ...<Widget>[
              Text(subtitle!, style: AppTheme.micro),
              const SizedBox(width: AppTheme.gapXs),
            ],
            Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

/// 入口之间的细分隔线（左右留边）。
class _EntryDivider extends StatelessWidget {
  const _EntryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.8,
      margin: const EdgeInsets.only(left: 48),
      color: AppTheme.divider(),
    );
  }
}
