import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock/mock_seed.dart';
import 'widgets/feature_card.dart';
import 'widgets/section_status.dart';

/// 首页状态，通过 --dart-define=HOME_STATE=xxx 切换，仅用于本地验收四态。
/// 不加 UI 开关 —— 避免把「假功能」塞进产品，第 3 周还得拆。
const String _homeStateEnv =
    String.fromEnvironment('HOME_STATE', defaultValue: 'success');

HomeStatus _resolveStatus() {
  switch (_homeStateEnv) {
    case 'loading':
      return HomeStatus.loading;
    case 'empty':
      return HomeStatus.empty;
    case 'error':
      return HomeStatus.error;
    default:
      return HomeStatus.success;
  }
}

/// 首页（P2）：顶部导航栏 + 搜索栏 + 海报占位 + 基础功能 + 最近录音。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeStatus status = _resolveStatus();

    return Scaffold(
      appBar: AppBar(title: const Text('开启记录之路吧')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: <Widget>[
          const _SearchBar(),
          const SizedBox(height: 16),
          const _PosterPlaceholder(),
          const SizedBox(height: 24),
          const _SectionTitle('基础功能'),
          const SizedBox(height: 12),
          _buildFeatureList(context),
          const SizedBox(height: 24),
          const _SectionTitle('最近录音'),
          const SizedBox(height: 12),
          SectionStatus(
            status: status,
            items: mockRecordings,
            itemBuilder: _buildRecordingTile,
            onRetry: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('录音页下一板块接入')),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final FeatureItem feature = mockFeatures.first;
    return FeatureCard(
      title: feature.title,
      subtitle: feature.subtitle,
      icon: Icons.mic,
      color: AppTheme.cinnabar,
      onTap: () => _showComingSoon(context),
    );
  }

  Widget _buildRecordingTile(RecordingItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.ink.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.azurite.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: AppTheme.azurite,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.date,
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              item.duration,
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 区块标题：左侧一竖条色块 + 标题文字。
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.cinnabar,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 搜索栏 —— 仅外观，不接搜索逻辑（搜索属本期不做）。
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.search,
            color: AppTheme.ink.withValues(alpha: 0.4),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '搜索录音或功能',
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// 海报占位区 —— 按需求「暂时就不放东西空那」，只留一个淡淡的渐变色块。
class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.azurite.withValues(alpha: 0.10),
            AppTheme.gamboge.withValues(alpha: 0.10),
            AppTheme.rouge.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.06)),
      ),
    );
  }
}
