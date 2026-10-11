import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/ink_tokens.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/ink/ink.dart';
import '../../data/mock/mock_seed.dart';

/// 历史录音详情页（P3a）—— 真回放。v11「墨落」换装。
///
/// 接入 `just_audio`：按 [RecordingItem.filePath] 加载本地音频，
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
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
                title: '录音详情',
                subtitle: 'PLAYBACK',
                onBack: () => Navigator.of(context).pop(),
                showDivider: false,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: <Widget>[
                    const SizedBox(height: 6),
                    Text(
                      widget.item.title,
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Inks.paper,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        InkTag(label: 'DATE', value: widget.item.date),
                        const SizedBox(width: 8),
                        InkTag(
                          label: 'LEN',
                          value: widget.item.duration,
                          valueColor: Inks.paper,
                        ),
                        const SizedBox(width: 8),
                        InkTag(
                          label: 'ID',
                          value: widget.item.id.toUpperCase(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const InkSectionLabel('波形预览'),
                    const SizedBox(height: 12),
                    InkPanel(
                      tone: InkTone.dark,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        children: <Widget>[
                          WaveBars(
                            count: 40,
                            height: 64,
                            progress: _ready ? _progress : 0.0,
                            color: Inks.paper,
                          ),
                          const SizedBox(height: 12),
                          CalibrationRuler(
                            divisions: 40,
                            height: 7,
                            color: Inks.paper.withValues(alpha: 0.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _PlayerPanel(
                      ready: _ready,
                      playing: _playing,
                      completed: _completed,
                      position: _position,
                      duration: _duration,
                      progress: _progress,
                      onToggle: _togglePlay,
                    ),
                    const SizedBox(height: 24),
                    const InkHairline(),
                    const SizedBox(height: 14),
                    Text(
                      widget.item.filePath == null
                          ? '该记录为示例数据，无音频文件；录一段新录音即可回放。'
                          : '转写、纪要、纠错入口不在本期范围（第一阶段只跑通录音与回放）。',
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 12,
                        height: 1.55,
                        color: Inks.paperDim,
                      ),
                    ),
                    const SizedBox(height: 28),
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

/// 播放器：暗房面板 + 墨线播放键 + 当前时间/总时长 + 纸色进度条。
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
    final Color keyColor = ready ? Inks.paper : Inks.paperDim;
    final String status = !ready
        ? '无音频文件'
        : playing
            ? '播放中'
            : completed
                ? '已播完 · 点击重播'
                : '已就绪';
    return InkPanel(
      tone: InkTone.dark,
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
                    border: Border.all(color: keyColor, width: 1.5),
                  ),
                  child: Icon(
                    playing
                        ? Icons.pause
                        : (completed ? Icons.replay : Icons.play_arrow),
                    color: keyColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _fmt(position),
                      style: TextStyle(
                        fontFamily: kMono,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Inks.paper,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      status,
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 11.5,
                        color: playing ? Inks.paper : Inks.paperDim,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _fmt(duration),
                style: TextStyle(
                  fontFamily: kMono,
                  fontSize: 11.5,
                  color: Inks.paperDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 真实进度条：暗槽 + 纸色已播放段
          Container(
            height: 2.4,
            color: Inks.paper.withValues(alpha: 0.12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(color: Inks.paper),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
