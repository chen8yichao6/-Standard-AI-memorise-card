import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_exception.dart';
import '../../core/theme/ink_tokens.dart';
import '../../core/widgets/ink/ink.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../auth/models/user.dart';
import 'settings_page.dart';

/// 个人页面（P1）—— 从首页右上角头像进入。v11「墨落」换装。
///
/// 本期范围（PRD §3.1）：
/// - 顶部头像（**可点击更换**，走 `PUT /users/me/avatar`）+ 昵称 + 邮箱；
/// - 三个入口：账号 / 设置 / 关于；
/// - 退出登录（朱砂字，二次确认 → 真登出，清凭证回登录页）。
///
/// 登录态变化（如上传头像后 user 刷新）通过监听 [AuthController] 自动重绘。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _uploading = false;

  /// 选图 → 上传头像 → 刷新登录态。
  ///
  /// 契约 §1.7：`multipart/form-data` 字段 `file`，≤5 MiB，jpg/png/webp；
  /// 服务端魔数终判，类型不符 415、超限 413——错误文案原样透传给用户。
  Future<void> _pickAndUploadAvatar() async {
    if (_uploading) return;

    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await AuthController.instance.uploadAvatar(picked.path);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('头像已更新')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('头像上传失败，请稍后重试')),
          );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthController.instance,
      builder: (BuildContext context, AuthState state, Widget? child) {
        final User? user = state is AuthAuthenticated ? state.user : null;
        return Scaffold(
          backgroundColor: Inks.ink,
          body: InkSurface(
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  InkAppBar(
                    title: '个人中心',
                    subtitle: 'PROFILE',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      children: <Widget>[
                        _buildProfileCard(user),
                        const SizedBox(height: 28),
                        const InkSectionLabel('账户与设置', expand: true),
                        const SizedBox(height: 12),
                        InkPanel(
                          tone: InkTone.dark,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: <Widget>[
                              _EntryTile(
                                icon: Icons.person_outline,
                                title: '账号',
                                subtitle: user?.email ?? '—',
                                onTap: () =>
                                    _showTodo(context, '账号区下一板块接入'),
                              ),
                              const InkHairline(indent: 49),
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
                              const InkHairline(indent: 49),
                              _EntryTile(
                                icon: Icons.info_outline,
                                title: '关于',
                                subtitle: 'v0.1.0',
                                onTap: () => _showAbout(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkPanel(
                          tone: InkTone.dark,
                          onTap: () => _confirmLogout(context),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(Icons.logout, color: Inks.seal, size: 17),
                              const SizedBox(width: 8),
                              Text(
                                '退出登录',
                                style: TextStyle(
                                  fontFamily: kSerif,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                  color: Inks.seal,
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
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(User? user) {
    return InkPanel(
      tone: InkTone.dark,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: <Widget>[
          // 点击头像 → 选图上传（契约 §1.7）。上传中禁用重复点击。
          InkAvatar(
            size: 72,
            imageUrl: user?.avatarUrl,
            fallbackText: user?.nickname ?? user?.email,
            onTap: _uploading ? null : _pickAndUploadAvatar,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user?.nickname ?? '未登录',
                  style: TextStyle(
                    fontFamily: kSerif,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Inks.paper,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _uploading ? '正在上传头像…' : (user?.email ?? '账号区待接入'),
                  style: TextStyle(
                    fontFamily: kMono,
                    fontSize: 11,
                    color: Inks.paperDim,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Text(
                  '点击头像可更换',
                  style: TextStyle(
                    fontFamily: kSerif,
                    fontSize: 11.5,
                    color: Inks.paperDim,
                  ),
                ),
              ],
            ),
          ),
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
          backgroundColor: Inks.inkSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: BorderSide(color: Inks.paper.withValues(alpha: 0.14)),
          ),
          title: Text(
            'AI 记忆卡',
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Inks.paper,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'v0.1.0',
                style: TextStyle(
                  fontFamily: kMono,
                  fontSize: 11,
                  color: Inks.paperDim,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '把每一段声音，沉淀成可调用的记忆。',
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 14,
                  height: 1.5,
                  color: Inks.paperSoft,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '知道了',
                style: TextStyle(
                  fontFamily: kSerif,
                  color: Inks.paperSoft,
                ),
              ),
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
          backgroundColor: Inks.inkSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: BorderSide(color: Inks.paper.withValues(alpha: 0.14)),
          ),
          title: Text(
            '确认退出登录？',
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Inks.paper,
            ),
          ),
          content: Text(
            '退出后将清除本地登录凭证，回到登录页。',
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 14,
              height: 1.5,
              color: Inks.paperSoft,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(fontFamily: kSerif, color: Inks.paperDim),
              ),
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
              child: Text(
                '退出',
                style: TextStyle(fontFamily: kSerif, color: Inks.seal),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 一个入口行：墨线图标 + 衬线标题 + 右侧等宽副文字 + 箭头。
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
            Icon(icon, color: Inks.paperDim, size: 19),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Inks.paper,
                ),
              ),
            ),
            if (subtitle != null) ...<Widget>[
              Text(
                subtitle!,
                style: TextStyle(
                  fontFamily: kMono,
                  fontSize: 10.5,
                  color: Inks.paperDim,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              color: Inks.paper.withValues(alpha: 0.35),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
