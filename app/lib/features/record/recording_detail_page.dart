import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/mech_background.dart';
import '../../core/widgets/mech_panel.dart';
import '../../data/mock/mock_seed.dart';

/// 历史录音详情页（P3a）—— 真回放。
///
/// 2026-10-10 接入 `just_audio`：按 [RecordingItem.filePath] 加载本地音频，
/// 播放/暂停切换、进度条与波形着色走真实播放进度。
/// 种子数据没有真文件（filePath 为 null）时降级为「无音频文件」提示，不崩溃。
class RecordingDetailPage extends StatefulWidget {
  const RecordingDetailPage({super.key, required this.item});

  final RecordingItem item;

  @override
  State<RecordingDetailPage> createState() => _RecordingDetailPageState();
}

class _RecordingDetailPageState extends State<RecordingDetailPage> {
  final AudioPlayer _player = AudioPlayer();

  bool _ready = false;
  bool _playing = false;
  bool _completed = false; // 播完一遍（再点即重播）
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    final String? path = widget.item.filePath;
    if (path != null) _init(path);
  }

  Future<void> _init(String path) async {
    try {
      await _player.setFilePath(path);
      _duration = _player.duration ?? Duration.zero;
      if (mounted) setState(() => _ready = true);
      _posSub = _player.positionStream.listen((Duration p) {
        if (mounted) setState(() => _position = p);
      });
      _stateSub = _player.playerStateStream.listen((PlayerState s) {
        final bool playing = s.playing;
        // 播完一遍后 just_audio 停在末尾（completed），此时直接 play() 不会重播，
        // 必须先 seek 回 0 —— 交给 _togglePlay 处理，这里只同步 UI 状态。
        final bool completed = s.processingState == ProcessingState.completed;
        if (mounted && (playing != _playing || completed != _completed)) {
          setState(() {
            _playing = playing;
            _completed = completed;
          });
        }
      });
    } catch (_) {
      // 文件缺失 / 解码失败：降级为「无音频文件」。
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该记录无音频文件，去录一段吧')),
      );
      return;
    }
    if (_playing) {
      await _player.pause();
      return;
    }
    // 关键：播完一遍后播放头停在末尾，just_audio 不会自动回到开头，
    // 再调 play() 会「没反应」——先 seek 到 0 才是重播。
    if (_completed || _player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      if (mounted) setState(() => _completed = false);
    }
    await _player.play();
  }

  double get _progress {
    if (_duration.inMilliseconds <= 0) return 0.0;
    return (_position.inMilliseconds / _duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
                const _TopBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: <Widget>[
                      const SizedBox(height: AppTheme.gapXs),
                      Text(widget.item.title, style: AppTheme.display),
                      const SizedBox(height: AppTheme.gapSm),
                      Row(
                        children: <Widget>[
                          _MetaChip(label: 'DATE', value: widget.item.date),
                          const SizedBox(width: AppTheme.gapXs),
                          _MetaChip(
                            label: 'LEN',
                            value: widget.item.duration,
                            valueColor: AppTheme.primary,
                          ),
                          const SizedBox(width: AppTheme.gapXs),
                          _MetaChip(
                            label: 'ID',
                            value: widget.item.id.toUpperCase(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.gapXl),
                      const HudLabel('波形预览'),
                      const SizedBox(height: AppTheme.gapSm),
                      MechPanel(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          children: <Widget>[
                            WaveBars(
                              count: 40,
                              height: 64,
                              progress: _ready ? _progress : 0.0,
                            ),
                            const SizedBox(height: AppTheme.gapXs),
                            CalibrationRuler(
                              divisions: 40,
                              height: 7,
                              color: AppTheme.textTertiary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.gapLg),
                      _PlayerPanel(
                        ready: _ready,
                        playing: _playing,
                        completed: _completed,
                        position: _position,
                        duration: _duration,
                        progress: _progress,
                        onToggle: _togglePlay,
                      ),
                      const SizedBox(height: AppTheme.gapLg),
                      const TechDivider(label: 'TRACK INFO'),
                      const SizedBox(height: AppTheme.gapSm),
                      Text(
                        widget.item.filePath == null
                            ? '该记录为示例数据，无音频文件；录一段新录音即可回放。'
                            : '转写、纪要、纠错入口不在本期范围（第一阶段只跑通录音与回放）。',
                        style: AppTheme.micro.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.gapLg),
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

/// 元信息小胶囊：`DATE 09-28`。
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: AppTheme.gapXxs),
          Text(
            value,
            style: AppTheme.mono.copyWith(
              color: valueColor ?? AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 真播放器：切角面板 + 播放/暂停键 + 当前时间/总时长 + 真实进度条。
class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.ready,
    required this.playing,
    required this.completed,
    required this.position,
    required this.duration,
    required this.progress,
    required this.onToggle,
  });

  final bool ready;
  final bool playing;
  final bool completed;
  final Duration position;
  final Duration duration;
  final double progress;
  final VoidCallback onToggle;

  String _fmt(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color keyColor = ready ? AppTheme.primary : AppTheme.textTertiary;
    final String status = !ready
        ? '无音频文件'
        : playing
            ? '播放中'
            : completed
                ? '已播完 · 点击重播'
                : '已就绪';
    return MechPanel(
      cornerTag: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceRaised,
                    border: Border.all(color: keyColor, width: 1.5),
                  ),
                  child: Icon(
                    playing
                        ? Icons.pause
                        : (completed ? Icons.replay : Icons.play_arrow),
                    color: keyColor,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_fmt(position), style: AppTheme.numeral),
                    const SizedBox(height: AppTheme.gapXxs),
                    Text(
                      status,
                      style: AppTheme.micro.copyWith(
                        color: playing ? AppTheme.primary : AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _fmt(duration),
                style: AppTheme.mono.copyWith(color: AppTheme.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.gapMd),
          // 真实进度条：暗槽 + 青色已播放段
          Container(
            height: 3,
            color: AppTheme.bgDeep,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶栏：返回 + 标题。
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.chevron_left, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppTheme.gapXxs),
          Text('录音详情', style: AppTheme.title),
          const Spacer(),
          Text(
            'PLAYBACK',
            style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
