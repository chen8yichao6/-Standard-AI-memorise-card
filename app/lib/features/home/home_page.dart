import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hud.dart';
import '../../core/widgets/mech_avatar.dart';
import '../../core/widgets/mech_background.dart';
import '../../core/widgets/mech_panel.dart';
import '../../data/mock/mock_seed.dart';
import '../profile/profile_page.dart';
import '../record/record_page.dart';
import '../record/recording_detail_page.dart';
import 'widgets/feature_card.dart';
import 'widgets/section_status.dart';

/// 首页状态，通过 --dart-define=HOME_STATE=xxx 切换，仅用于本地验收四态。
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

/// 首页（P2）—— 深蓝赛博风。
///
/// 2026-10-03 重构（用户反馈「元素太少、太空 / 质感太平 / 动画不够动感」）：
/// - 顶栏下方加 HUD 状态行（VER / STORE / SYNC），补「设备在报告数据」的感觉；
/// - 海报占位从空框改成**仪表占位**（准星 + 同心环 + 刻度尺）；
/// - 区块标题统一走 [HudLabel]（`▮ 最近录音` 形式）；
/// - 全屏叠一层 [ScanSweep] 扫描光带，界面不再死板；
/// - 列表项左侧竖条改青色渐变，时长用青色等宽数字。
///
/// 交互（上一轮救活的，全部保留）：搜索栏本地过滤 / 点录音卡进录音页 /
/// 点历史录音进详情页。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = '';

  List<RecordingItem> get _filtered {
    final String q = _query.trim();
    if (q.isEmpty) return mockRecordings;
    return mockRecordings
        .where((RecordingItem r) => r.title.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final HomeStatus status = _resolveStatus();
    final bool searching = _query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: MechBackground()),
          SafeArea(
            child: Column(
              children: <Widget>[
                _TopBar(onAvatarTap: _openProfile),
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: <Widget>[
                      _SearchBar(
                        onChanged: (String v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: AppTheme.gapXs),
                      _IndexMeta(
                        searching: searching,
                        query: _query.trim(),
                        count: _filtered.length,
                      ),
                      const SizedBox(height: AppTheme.gapMd),
                      const _RadarPlaceholder(),
                      const SizedBox(height: AppTheme.gapXl),
                      const HudLabel('基础功能', expand: true),
                      const SizedBox(height: AppTheme.gapSm),
                      _buildFeatureList(),
                      const SizedBox(height: AppTheme.gapXl),
                      const HudLabel('最近录音'),
                      const SizedBox(height: AppTheme.gapXs),
                      SectionStatus(
                        status: status,
                        items: _filtered,
                        itemBuilder: _buildRecordingTile,
                        onRetry: () => setState(() {}),
                      ),
                      const SizedBox(height: AppTheme.gapXl),
                      const _FooterStatus(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 扫描光带叠在最上层：掠过文字更有「设备正在跑」的感觉。
          const Positioned.fill(child: ScanSweep()),
        ],
      ),
    );
  }

  void _openRecord() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RecordPage()),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
    );
  }

  void _openDetail(RecordingItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecordingDetailPage(item: item),
      ),
    );
  }

  Widget _buildFeatureList() {
    final FeatureItem feature = mockFeatures.first;
    return FeatureCard(
      title: feature.title,
      subtitle: feature.subtitle,
      onTap: _openRecord,
    );
  }

  /// 最近录音的一条：青色竖标 + 标题/日期，右侧青色等宽时长 + 箭头。
  Widget _buildRecordingTile(RecordingItem item) {
    return InkWell(
      onTap: () => _openDetail(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[AppTheme.primaryBright, AppTheme.primaryDim],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.gapSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.gapXxs),
                  Row(
                    children: <Widget>[
                      Text(item.date, style: AppTheme.mono),
                      const SizedBox(width: AppTheme.gapXs),
                      Container(width: 3, height: 3, color: AppTheme.textTertiary),
                      const SizedBox(width: AppTheme.gapXs),
                      Text('REC', style: AppTheme.micro),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.gapXs),
            Text(item.duration, style: AppTheme.numeral),
            const SizedBox(width: AppTheme.gapXxs),
            Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}

/// 自绘顶栏：左标题 + 右头像入口，下面压一条 HUD 状态行。
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onAvatarTap});

  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Row(
            children: <Widget>[
              Text('AI 记忆卡', style: AppTheme.title),
              const SizedBox(width: AppTheme.gapXs),
              Container(width: 1, height: 14, color: AppTheme.border),
              const SizedBox(width: AppTheme.gapXs),
              Text(
                'MEMORY UNIT',
                style: AppTheme.micro,
              ),
              const Spacer(),
              // 右上角：个人中心入口（头像）。ONLINE 状态已下移到下方 HUD 行。
              MechAvatar(size: 30, onTap: onAvatarTap),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: HudBar(
            items: <HudItem>[
              HudItem(label: 'VER', value: '0.1.0'),
              HudItem(label: 'STORE', value: 'LOCAL'),
              HudItem(label: 'DEV', value: 'MOBILE'),
              HudItem(label: 'LINK', value: 'ONLINE', valueColor: AppTheme.primary),
            ],
          ),
        ),
      ],
    );
  }
}

/// 搜索框下方的索引元信息行：`本地索引 · 3 ITEMS` / `匹配 1 条`。
class _IndexMeta extends StatelessWidget {
  const _IndexMeta({
    required this.searching,
    required this.query,
    required this.count,
  });

  final bool searching;
  final String query;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 4,
          color: searching ? AppTheme.primary : AppTheme.borderStrong,
        ),
        const SizedBox(width: AppTheme.gapXs),
        Expanded(
          child: Text(
            searching ? '检索「$query」命中 $count 条' : '本地索引 · 元信息为种子数据',
            style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$count ITEMS',
          style: AppTheme.micro.copyWith(
            color: searching ? AppTheme.primary : AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// 搜索栏：金属渐变底 + 左青色标记 + 右侧 SCAN 标。
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient(),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 3,
            height: 26,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[AppTheme.primaryBright, AppTheme.primaryDim],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.gapSm),
          Icon(Icons.search, color: AppTheme.textTertiary, size: 18),
          const SizedBox(width: AppTheme.gapXs),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppTheme.body,
              cursorColor: AppTheme.primary,
              decoration: InputDecoration(
                hintText: '搜索录音',
                hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.gapXs),
          Text(
            'SCAN',
            style: AppTheme.micro,
          ),
          const SizedBox(width: AppTheme.gapSm),
        ],
      ),
    );
  }
}

/// 仪表占位（原「海报占位」）—— 切角框 + 准星同心环 + 底部刻度尺。
///
/// 比空框多出「仪器待校准」的感觉：中间是准星，底下是量程刻度。
class _RadarPlaceholder extends StatelessWidget {
  const _RadarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const ChamferClipper(cut: 14),
      child: Container(
        height: 134,
        width: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.panelGradient()),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: CustomPaint(painter: _ReticlePainter()),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const PulseDot(size: 5, period: Duration(seconds: 3)),
                  const SizedBox(height: AppTheme.gapXs),
                  Text(
                    '待接入',
                    style: AppTheme.mono.copyWith(
                      color: AppTheme.textSecondary,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 11,
              child: CalibrationRuler(
                divisions: 34,
                height: 7,
                color: AppTheme.primary,
              ),
            ),
            Positioned(
              left: 14,
              top: 10,
              child: Text(
                'SLOT-01',
                style: AppTheme.micro,
              ),
            ),
            Positioned(
              right: 14,
              top: 10,
              child: Text(
                'IDLE',
                style: AppTheme.micro.copyWith(color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 准星 + 同心环（仪表盘底纹）。
class _ReticlePainter extends CustomPainter {
  const _ReticlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2 - 6);
    final Paint thin = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.75)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 同心环
    for (final double r in <double>[26, 44]) {
      canvas.drawCircle(c, r, thin);
    }

    // 十字准星（只画环外的四个方向，避免穿过中心的文字）
    final Paint cross = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const double gap = 54;
    const double len = 999;
    canvas.drawLine(Offset(c.dx, c.dy - gap), Offset(c.dx, c.dy - len), cross);
    canvas.drawLine(Offset(c.dx, c.dy + gap), Offset(c.dx, c.dy + len), cross);
    canvas.drawLine(Offset(c.dx - gap, c.dy), Offset(c.dx - len, c.dy), cross);
    canvas.drawLine(Offset(c.dx + gap, c.dy), Offset(c.dx + len, c.dy), cross);

    // 四角小刻度
    final Paint tick = Paint()
      ..color = AppTheme.borderStrong.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    const double pad = 10;
    const double tl = 8;
    canvas.drawLine(Offset(pad, pad), Offset(pad + tl, pad), tick);
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad - tl, pad), tick);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 底部设备状态行 —— 收尾用，告诉用户「现在是什么状态」。
class _FooterStatus extends StatelessWidget {
  const _FooterStatus();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const HudBar(
          items: <HudItem>[
            HudItem(label: 'STORAGE', value: '0 B'),
            HudItem(label: 'AI', value: 'OFFLINE'),
            HudItem(label: 'SYNC', value: 'LOCAL ONLY'),
          ],
        ),
        const SizedBox(height: AppTheme.gapXs),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '录音与回放尚未接入，当前为界面骨架',
                style: AppTheme.micro.copyWith(color: AppTheme.textTertiary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
