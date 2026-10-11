import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/env.dart';
import '../../core/theme/ink_tokens.dart';
import '../../core/widgets/ink/ink.dart';
import 'auth_controller.dart';

/// 登录 / 注册页（阶段 A 打通鉴权）—— v11「墨落」换装。
///
/// 作为 `RootGate` 的未登录分支，不是 push 进来的，无返回按钮。
/// 登录成功后 [AuthController] 状态切到已登录，由 RootGate 自动替换为首页。
///
/// 视觉：暗房底 + 朱砂印章 + 生宣纸表单（墨线输入）；**逻辑一字未动**。
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
      backgroundColor: Inks.ink,
      body: InkSurface(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: <Widget>[
              const SizedBox(height: 24),
              _Brand(register: _register),
              const SizedBox(height: 32),
              _ModeSwitch(register: _register, onToggle: _toggleMode),
              const SizedBox(height: 14),
              InkPanel(
                tone: InkTone.paper,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkTextField(
                      controller: _email,
                      label: 'EMAIL',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),
                    InkTextField(
                      controller: _password,
                      label: 'PASSWORD',
                      hint: _register ? '≥8 位，含字母与数字' : '请输入密码',
                      obscure: true,
                      textInputAction: TextInputAction.next,
                    ),
                    if (_register) ...<Widget>[
                      const SizedBox(height: 18),
                      InkTextField(
                        controller: _nickname,
                        label: 'NICKNAME（可选）',
                        hint: '不填则取邮箱 @ 前缀',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 16),
                      _ErrorLine(message: _error!),
                    ],
                    const SizedBox(height: 22),
                    InkButton(
                      loading: _loading,
                      label: _register ? '注册并登录' : '登 录',
                      onTap: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _EndpointHint(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶部品牌区：朱砂印章 + 名称 + 题字 + 模式标。
class _Brand extends StatelessWidget {
  const _Brand({required this.register});

  final bool register;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const InkSeal(size: 56),
        const SizedBox(height: 16),
        Text(
          'AI 记忆卡',
          style: TextStyle(
            fontFamily: kSerif,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 5,
            color: Inks.paper,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '把每段声音，收进记忆',
          style: TextStyle(
            fontFamily: kMono,
            fontSize: 11,
            letterSpacing: 3,
            color: Inks.paperDim,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          register ? 'R E G I S T E R' : 'S I G N   I N',
          style: TextStyle(
            fontFamily: kMono,
            fontSize: 10,
            letterSpacing: 3,
            color: Inks.paperSoft,
          ),
        ),
      ],
    );
  }
}

/// 登录 / 注册 切换 —— 选中态靠**笔画加重**（底线变粗），不引进第四种颜色。
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
        const SizedBox(width: 10),
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
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: 15,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 2,
                color: active ? Inks.paper : Inks.paperDim,
              ),
            ),
          ),
          Container(
            height: active ? 2.4 : 0.8,
            color: active ? Inks.paper : Inks.paper.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

/// 内联错误行（纸上朱砂）。
class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.error_outline, color: Inks.seal, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 13,
              height: 1.35,
              color: Inks.seal,
            ),
          ),
        ),
      ],
    );
  }
}

/// 底部联调提示：显示当前 base url，方便真机排查「连没连对后端」。
class _EndpointHint extends StatelessWidget {
  const _EndpointHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const InkSectionLabel('接入点'),
        const SizedBox(height: 8),
        Text(
          Env.apiBaseUrl,
          style: TextStyle(
            fontFamily: kMono,
            fontSize: 10.5,
            color: Inks.paperDim,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
