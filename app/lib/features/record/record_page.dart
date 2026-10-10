import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/mech_background.dart';
import '../../core/widgets/mech_panel.dart';
import '../../data/mock/mock_seed.dart';
import '../../data/recordings/recording_store.dart';
import '../../services/recording_service.dart';

/// 录音功能页（P3）—— 真录音。
///
/// 2026-10-10 接入 `record` 插件：点录音键开始真录音（写本地 m4a），
/// 再点停止 → 写入 [RecordingStore] → 回首页，列表顶部出现新录音可回放。
/// 计时器走真时间，波形 / dB 电平随录音状态切换。
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final RecordingService _service = RecordingService();

  bool _recording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  double? _dB; // 录音中的实时电平（dBFS）；null = 未录音（-∞）
  String? _currentPath;

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _service.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_recording) {
      _stop();
    } else {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      final String path = await _service.start();
      if (!mounted) {
        // 页面已销毁：立即停止，避免录音泄漏。
        await _service.stop();
        return;
      }
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
        _dB = null;
        _currentPath = path;
      });
      // 计时器：每秒 +1s
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
      // 实时电平：驱动 dB 显示
      _ampSub = _service.amplitudeStream().listen((Amplitude a) {
        if (mounted) setState(() => _dB = a.current);
      });
    } on RecordingException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('录音启动失败：$e');
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    _ampSub?.cancel();
    _ampSub = null;

    final String? path = await _service.stop();
    if (!mounted) return;

    if (path == null) {
      setState(() {
        _recording = false;
        _dB = null;
      });
      _toast('未录到音频，请重试');
      return;
    }

    final RecordingItem item = RecordingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _nowTitle(),
      duration: _fmt(_elapsed),
      date: _nowShort(),
      type: RecordingType.meeting,
      filePath: path,
    );
    await RecordingStore.instance.add(item);

    if (!mounted) return;
    setState(() {
      _recording = false;
      _dB = null;
    });
    _toast('已保存「${item.title}」· ${item.duration}');
    Navigator.of(context).pop();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmt(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _nowTitle() {
    final DateTime n = DateTime.now();
    final String hh = n.hour.toString().padLeft(2, '0');
    final String mm = n.minute.toString().padLeft(2, '0');
    return '录音 $hh:$mm';
  }

  String _nowShort() {
    final DateTime n = DateTime.now();
    final String mo = n.month.toString().padLeft(2, '0');
    final String dd = n.day.toString().padLeft(2, '0');
    return '$mo-$dd';
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
                _TopBar(recording: _recording),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: AppTheme.gapXs),
                      Text(
                        _fmt(_elapsed),
                        style: AppTheme.numeralLarge.copyWith(fontSize: 62),
                      ),
                      const SizedBox(height: AppTheme.gapXxs),
                      Text(
                        _recording ? 'REC · 采集中' : 'STANDBY · 未开始采集',
                        style: AppTheme.micro.copyWith(
                          color: _recording
                              ? AppTheme.danger
                              : AppTheme.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      _RecordButton(
                        recording: _recording,
                        onTap: _toggle,
                      ),
                      const SizedBox(height: AppTheme.gapXxl),
                      Text(
                        _recording ? '点击停止并保存' : '点击开始录音',
                        style: AppTheme.caption,
                      ),
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
                                    _recording && _dB != null
                                        ? '${_dB!.toStringAsFixed(0)} dB'
                                        : '-∞ dB',
                                    style: AppTheme.micro.copyWith(
                                      color: _recording
                                          ? AppTheme.primary
                                          : AppTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.gapSm),
                              WaveBars(
                                count: 36,
                                height: 26,
                                animate: _recording,
                              ),
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
                        child: HudBar(
                          items: <HudItem>[
                            const HudItem(label: 'FORMAT', value: 'M4A / AAC-LC'),
                            const HudItem(label: 'RATE', value: '44.1 kHz'),
                            HudItem(
                              label: 'BIT',
                              value: '128k',
                              valueColor: _recording
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
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
  const _TopBar({required this.recording});

  final bool recording;

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
              PulseDot(
                size: 6,
                color: recording ? AppTheme.danger : null,
                period: recording
                    ? const Duration(milliseconds: 900)
                    : const Duration(seconds: 2),
              ),
              const SizedBox(width: AppTheme.gapXs),
              Text(
                recording ? 'REC' : 'STANDBY',
                style: AppTheme.micro.copyWith(
                  color: recording ? AppTheme.danger : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: HudBar(
            items: <HudItem>[
              HudItem(
                label: 'MIC',
                value: recording ? 'LIVE' : 'IDLE',
                valueColor: recording ? AppTheme.danger : AppTheme.textSecondary,
              ),
              const HudItem(label: 'GAIN', value: '0 dB'),
              const HudItem(label: 'TRACK', value: '01'),
            ],
          ),
        ),
      ],
    );
  }
}

/// 中央录音键：外刻度环 + 内圆 + 麦克风/停止。
///
/// 2026-10-06 Day 9 修复：原实现用裸 `GestureDetector`，点下去毫无反馈，
/// 与历史录音行（`InkWell` 有涟漪）是两套交互标准。改为有状态组件：
/// 按下时内键缩到 0.92、辉光减弱、描边转亮青；松开/取消弹回。
/// 2026-10-10 接入真录音：录音中图标转红色停止键。
class _RecordButton extends StatefulWidget {
  const _RecordButton({required this.onTap, required this.recording});

  final VoidCallback onTap;
  final bool recording;

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
    final Color keyColor = widget.recording ? AppTheme.danger : AppTheme.primary;
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
              border: Border.all(
                color: widget.recording
                    ? AppTheme.danger.withValues(alpha: 0.5)
                    : AppTheme.border,
              ),
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
                  border: Border.all(color: keyColor, width: 1.6),
                  boxShadow: AppTheme.glow(
                    color: keyColor,
                    opacity: _pressed ? 0.10 : 0.22,
                  ),
                ),
                child: widget.recording
                    ? Icon(Icons.stop, color: keyColor, size: 30)
                    : Icon(Icons.mic_none, color: keyColor, size: 34),
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
