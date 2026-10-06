import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/mech_background.dart';
import '../../core/widgets/mech_panel.dart';
import '../../data/mock/mock_seed.dart';

/// 历史录音详情页（P3a）—— 占位。
///
/// 展示元信息 + 波形预览 + 「回放待接入」的播放器占位，不接真音频（`just_audio` 下一板块）。
/// 2026-10-03 加密度：HUD 状态行、波形条、量程尺、播放器重新排版。
class RecordingDetailPage extends StatelessWidget {
  const RecordingDetailPage({super.key, required this.item});

  final RecordingItem item;

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
                      Text(item.title, style: AppTheme.display),
                      const SizedBox(height: AppTheme.gapSm),
                      Row(
                        children: <Widget>[
                          _MetaChip(label: 'DATE', value: item.date),
                          const SizedBox(width: AppTheme.gapXs),
                          _MetaChip(
                            label: 'LEN',
                            value: item.duration,
                            valueColor: AppTheme.primary,
                          ),
                          const SizedBox(width: AppTheme.gapXs),
                          _MetaChip(label: 'ID', value: item.id.toUpperCase()),
                        ],
                      ),
                      const SizedBox(height: AppTheme.gapXl),
                      const HudLabel('波形预览'),
                      const SizedBox(height: AppTheme.gapSm),
                      MechPanel(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          children: <Widget>[
                            const WaveBars(count: 40, height: 64, progress: 0.34),
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
                      _PlayerPlaceholder(duration: item.duration),
                      const SizedBox(height: AppTheme.gapLg),
                      const TechDivider(label: 'TRACK INFO'),
                      const SizedBox(height: AppTheme.gapSm),
                      Text(
                        '转写、纪要、纠错入口不在本期范围（第一阶段只跑通录音与回放）。',
                        style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
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

/// 播放器占位：切角面板 + 播放键 + 进度条 + 「待接入」。
class _PlayerPlaceholder extends StatelessWidget {
  const _PlayerPlaceholder({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    return MechPanel(
      cornerTag: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceRaised,
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                ),
                child: const Icon(Icons.play_arrow, color: AppTheme.primary, size: 26),
              ),
              const SizedBox(width: AppTheme.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(duration, style: AppTheme.numeral),
                    const SizedBox(height: AppTheme.gapXxs),
                    Text(
                      '音频回放待接入',
                      style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              Text(
                '00:00',
                style: AppTheme.mono.copyWith(color: AppTheme.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.gapMd),
          // 假进度条：暗槽 + 青色已播放段
          Container(
            height: 3,
            color: AppTheme.bgDeep,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.06,
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
            icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
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
