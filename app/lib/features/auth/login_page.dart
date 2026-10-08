import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/env.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/mech_background.dart';
import '../../core/widgets/mech_panel.dart';
import 'auth_controller.dart';

/// 登录 / 注册页（阶段 A 打通鉴权）。
///
/// 作为 `RootGate` 的未登录分支，不是 push 进来的，无返回按钮。
/// 登录成功后 [AuthController] 状态切到已登录，由 RootGate 自动替换为首页。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _nickname = TextEditingController();

  bool _register = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _email.text.trim();
    final String password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入邮箱和密码');
      return;
    }
    if (_register && password.length < 8) {
      setState(() => _error = '密码至少 8 位，且需包含字母与数字');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_register) {
        await AuthController.instance.register(
          email: email,
          password: password,
          nickname: _nickname.text.trim(),
        );
      } else {
        await AuthController.instance.login(email: email, password: password);
      }
      // 成功：不 setState，AuthState 变化会由 RootGate 自动切到首页。
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '请求失败，请稍后重试';
      });
    }
  }

  void _toggleMode(bool register) {
    if (_loading || register == _register) return;
    setState(() {
      _register = register;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MechBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: <Widget>[
                const SizedBox(height: AppTheme.gapXl),
                _Brand(register: _register),
                const SizedBox(height: AppTheme.gapXxl),
                _ModeSwitch(register: _register, onToggle: _toggleMode),
                const SizedBox(height: AppTheme.gapSm),
                MechPanel(
                  raised: true,
                  bolts: true,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _Field(
                        controller: _email,
                        label: 'EMAIL',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppTheme.gapMd),
                      _Field(
                        controller: _password,
                        label: 'PASSWORD',
                        hint: _register ? '≥8 位，含字母与数字' : '请输入密码',
                        obscure: true,
                        textInputAction: TextInputAction.next,
                      ),
                      if (_register) ...<Widget>[
                        const SizedBox(height: AppTheme.gapMd),
                        _Field(
                          controller: _nickname,
                          label: 'NICKNAME（可选）',
                          hint: '不填则取邮箱 @ 前缀',
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: AppTheme.gapMd),
                        _ErrorLine(message: _error!),
                      ],
                      const SizedBox(height: AppTheme.gapLg),
                      _SubmitButton(
                        loading: _loading,
                        label: _register ? '注册并登录' : '登 录',
                        onTap: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.gapMd),
                _EndpointHint(),
              ],
            ),
          ),
          const Positioned.fill(child: ScanSweep()),
        ],
      ),
    );
  }
}

/// 顶部品牌区：标题 + 副标题 + 模式标。
class _Brand extends StatelessWidget {
  const _Brand({required this.register});

  final bool register;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('AI 记忆卡', style: AppTheme.display),
        const SizedBox(height: AppTheme.gapXs),
        Text(
          '把每段声音，收进记忆',
          style: AppTheme.mono.copyWith(
            color: AppTheme.textSecondary,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: AppTheme.gapSm),
        Text(
          register ? 'REGISTER' : 'SIGN IN',
          style: AppTheme.micro.copyWith(color: AppTheme.primary),
        ),
      ],
    );
  }
}

/// 登录 / 注册 切换。
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.register, required this.onToggle});

  final bool register;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _ModeTab(
            label: '登录',
            active: !register,
            onTap: () => onToggle(false),
          ),
        ),
        const SizedBox(width: AppTheme.gapXs),
        Expanded(
          child: _ModeTab(
            label: '注册',
            active: register,
            onTap: () => onToggle(true),
          ),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppTheme.primary.withValues(alpha: 0.12) : null,
          border: Border.all(
            color: active ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.body.copyWith(
            color: active ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 表单输入框：HUD 标签 + 描边输入区。
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTheme.micro.copyWith(
            color: AppTheme.textTertiary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppTheme.gapXs),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.panelGradient(),
            border: Border.all(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
              cursorColor: AppTheme.primary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 内联错误行。
class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
        const SizedBox(width: AppTheme.gapXs),
        Expanded(
          child: Text(
            message,
            style: AppTheme.caption.copyWith(color: AppTheme.danger),
          ),
        ),
      ],
    );
  }
}

/// 提交按钮。
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.loading,
    required this.label,
    required this.onTap,
  });

  final bool loading;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: onTap == null
              ? null
              : LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[AppTheme.primaryDim, AppTheme.primaryBright],
                ),
          color: onTap == null ? AppTheme.bgDeep : null,
          border: Border.all(
            color: onTap == null ? AppTheme.border : AppTheme.primaryBright,
          ),
        ),
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              )
            : Text(
                label,
                style: AppTheme.body.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}

/// 底部联调提示：显示当前 base url，方便真机排查「连没连对后端」。
class _EndpointHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const HudLabel('ENDPOINT', expand: true),
        const SizedBox(height: AppTheme.gapXs),
        Text(
          Env.apiBaseUrl,
          style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
