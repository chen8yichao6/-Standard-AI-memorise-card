import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/mech_background.dart';
import '../../core/widgets/mech_panel.dart';

/// 录音功能页（P3）—— 占位骨架。
///
/// 本期不接真录音（`record` 插件下一板块接入），点录音键只弹提示。
/// 2026-10-03 加密度：HUD 状态行、刻度环录音键、底部波形与量程尺。
class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

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
                const _TopBar(),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: AppTheme.gapXs),
                      Text(
                        '00:00',
                        style: AppTheme.numeralLarge.copyWith(fontSize: 62),
                      ),
                      const SizedBox(height: AppTheme.gapXxs),
                      Text(
                        'STANDBY · 未开始采集',
                        style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
                      ),
                      const Spacer(),
                      _RecordButton(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('录音功能下一板块接入')),
                        ),
                      ),
                      const SizedBox(height: AppTheme.gapXxl),
                      Text('点击开始录音', style: AppTheme.caption),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: MechPanel(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const HudLabel('输入电平'),
                                  const Spacer(),
                                  Text(
                                    '-∞ dB',
                                    style: AppTheme.micro.copyWith(
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.gapSm),
                              const WaveBars(count: 36, height: 26),
                              const SizedBox(height: AppTheme.gapXs),
                              CalibrationRuler(
                                divisions: 30,
                                height: 7,
                                color: AppTheme.textTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.gapSm),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const HudBar(
                          items: <HudItem>[
                            HudItem(label: 'FORMAT', value: 'M4A / AAC-LC'),
                            HudItem(label: 'RATE', value: '44.1 kHz'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.gapXs),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶栏：返回 + 标题 + 呼吸指示灯 + 状态字。
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.chevron_left, color: AppTheme.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: AppTheme.gapXxs),
              Text('录音', style: AppTheme.title),
              const Spacer(),
              const PulseDot(size: 6),
              const SizedBox(width: AppTheme.gapXs),
              Text(
                'STANDBY',
                style: AppTheme.micro,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const HudBar(
            items: <HudItem>[
              HudItem(label: 'MIC', value: 'IDLE'),
              HudItem(label: 'GAIN', value: '0 dB'),
              HudItem(label: 'TRACK', value: '01'),
            ],
          ),
        ),
      ],
    );
  }
}

/// 中央录音键：外刻度环 + 内圆 + 麦克风。
///
/// 2026-10-06 Day 9 修复：原实现用裸 `GestureDetector`，点下去毫无反馈，
/// 与历史录音行（`InkWell` 有涟漪）是两套交互标准。改为有状态组件：
/// 按下时内键缩到 0.92、辉光减弱、描边转亮青；松开/取消弹回。
class _RecordButton extends StatefulWidget {
  const _RecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<_RecordButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // 刻度环
          const Positioned.fill(
            child: CustomPaint(painter: _DialRingPainter()),
          ),
          // 外圈
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
              gradient: AppTheme.panelGradient(),
            ),
          ),
          // 内键（带按压态）
          GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: AnimatedScale(
              scale: _pressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pressed ? AppTheme.surface : AppTheme.surfaceRaised,
                  border: Border.all(color: AppTheme.primary, width: 1.6),
                  boxShadow: AppTheme.glow(opacity: _pressed ? 0.10 : 0.22),
                ),
                child: Icon(Icons.mic_none, color: AppTheme.primary, size: 34),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 外圈刻度环：72 根短刻度，每 6 根一条长刻度。
class _DialRingPainter extends CustomPainter {
  const _DialRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final Paint p = Paint()..strokeWidth = 1.2;
    const int total = 72;
    for (int i = 0; i < total; i++) {
      final double a = i * 2 * math.pi / total - math.pi / 2;
      final bool major = i % 6 == 0;
      final double r1 = size.width / 2 - (major ? 12 : 8);
      final double r2 = size.width / 2 - 2;
      p.color = major
          ? AppTheme.primary.withValues(alpha: 0.7)
          : AppTheme.borderStrong.withValues(alpha: 0.45);
      canvas.drawLine(
        c + Offset(math.cos(a) * r1, math.sin(a) * r1),
        c + Offset(math.cos(a) * r2, math.sin(a) * r2),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
