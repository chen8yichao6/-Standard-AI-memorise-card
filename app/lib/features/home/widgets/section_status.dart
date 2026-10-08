import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mech_panel.dart';
import '../../../data/mock/mock_seed.dart';

/// 四种页面状态。
enum HomeStatus { loading, success, empty, error }

/// 一个数据区的四态渲染器。
///
/// 用法：传入状态 + 数据 + 单项构建函数；加载/空/错误由本组件统一渲染，
/// 成功态才调用 itemBuilder 画列表。
///
/// 2026-10-03：主光色由亮绿改为青色（`accent` → `primary`），
/// 空态补一行等宽说明，避免只有图标 + 一句话显得太空。
class SectionStatus extends StatelessWidget {
  const SectionStatus({
    super.key,
    required this.status,
    required this.items,
    required this.itemBuilder,
    this.onRetry,
  });

  final HomeStatus status;
  final List<RecordingItem> items;
  final Widget Function(RecordingItem item) itemBuilder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case HomeStatus.loading:
        // 注意：不能 const——CircularProgressIndicator 与字阶里带主题色，
        // 主题切换后要能取到新值（2026-10-08 主题层改造）。
        return _StatusBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(height: AppTheme.gapSm),
              Text('加载中…', style: AppTheme.caption),
              SizedBox(height: AppTheme.gapXxs),
              Text('READING LOCAL INDEX', style: AppTheme.micro),
            ],
          ),
        );

      case HomeStatus.empty:
        return const _EmptyBox();

      case HomeStatus.error:
        return _StatusBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.error_outline, size: 34, color: AppTheme.danger),
              const SizedBox(height: AppTheme.gapSm),
              Text('录音拉取失败', style: AppTheme.caption),
              const SizedBox(height: AppTheme.gapXxs),
              Text('ERR-SECTION-LOAD', style: AppTheme.micro),
              const SizedBox(height: AppTheme.gapSm),
              OutlinedButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        );

      case HomeStatus.success:
        if (items.isEmpty) return const _EmptyBox();
        return Column(
          children: <Widget>[
            for (int i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0) Container(height: 1, color: AppTheme.divider()),
              itemBuilder(items[i]),
            ],
          ],
        );
    }
  }
}

/// 空态 —— 机械面板 + 图标 + 两行说明。
class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) {
    return _StatusBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.inbox_outlined, size: 34, color: AppTheme.textTertiary),
          SizedBox(height: AppTheme.gapSm),
          Text('还没有录音，去录一段吧', style: AppTheme.caption),
          SizedBox(height: AppTheme.gapXxs),
          Text('NO RECORD FOUND', style: AppTheme.micro),
        ],
      ),
    );
  }
}

/// 状态占位框：加载/空/错误三态共用的机械面板（左对齐）。
class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MechPanel(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}
