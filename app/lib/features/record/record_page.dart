import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../../core/theme/ink_tokens.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/ink/ink.dart';
import '../../data/mock/mock_seed.dart';
import '../../data/recordings/recording_store.dart';
import '../../services/recording_service.dart';

/// 录音功能页（P3）—— 真录音，v11「墨落」换装。
///
/// 接入 `record` 插件：点墨点开始真录音（写本地 m4a），再点停止 →
/// 写入 [RecordingStore] → 回上一页，列表顶部出现新录音可回放。
/// 计时器走真时间，电平随录音状态切换。录音键复用首页同一滴墨（[InkStamp]）。
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
      await _service.start();
      if (!mounted) {
        // 页面已销毁：立即停止，避免录音泄漏。
        await _service.stop();
        return;
      }
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
        _dB = null;
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      backgroundColor: Inks.ink,
      body: InkSurface(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              InkAppBar(
                title: '录音',
                subtitle: _recording ? 'REC' : 'STANDBY',
                onBack: () => Navigator.of(context).pop(),
                showDivider: false,
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Text(
                      _fmt(_elapsed),
                      style: TextStyle(
                        fontFamily: kMono,
                        fontSize: 52,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                        color: Inks.paper,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _recording ? '正在录音 · 按一下结束' : '按一下墨点，开始记录',
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 12.5,
                        letterSpacing: 1,
                        color: _recording ? Inks.record : Inks.paperDim,
                      ),
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: InkStamp(recording: _recording, onTap: _toggle),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkPanel(
                        tone: InkTone.dark,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const InkSectionLabel('输入电平'),
                                const Spacer(),
                                Text(
                                  _recording && _dB != null
                                      ? '${_dB!.toStringAsFixed(0)} dB'
                                      : '-∞ dB',
                                  style: TextStyle(
                                    fontFamily: kMono,
                                    fontSize: 11,
                                    color: _recording
                                        ? Inks.paper
                                        : Inks.paperDim,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            WaveBars(
                              count: 36,
                              height: 26,
                              animate: _recording,
                              color: Inks.paper,
                            ),
                            const SizedBox(height: 10),
                            CalibrationRuler(
                              divisions: 30,
                              height: 7,
                              color: Inks.paper.withValues(alpha: 0.45),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: <Widget>[
                          const Expanded(
                            child: InkTag(label: 'FORMAT', value: 'M4A/AAC-LC'),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: InkTag(label: 'RATE', value: '44.1 kHz'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkTag(
                              label: 'BIT',
                              value: '128k',
                              valueColor: _recording ? Inks.paper : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
