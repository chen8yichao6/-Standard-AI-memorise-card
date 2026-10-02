import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/mock/mock_seed.dart';

/// 四种页面状态。
///
/// 今日清单的「今天要掌握」问的就是这个：四种状态里，哪一种最容易被忽略。
/// 答案见收尾说明 —— 这里先把四种都做出来，且每一种都能被真实触发、验收。
enum HomeStatus { loading, success, empty, error }

/// 一个数据区的四态渲染器。
///
/// 用法：传入状态 + 数据 + 单项构建函数；加载/空/错误由本组件统一渲染，
/// 成功态才调用 itemBuilder 画列表。
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
        return const _StatusBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 12),
              Text('加载中…'),
            ],
          ),
        );

      case HomeStatus.empty:
        return const _StatusBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.inbox_outlined, size: 40, color: AppTheme.ochre),
              SizedBox(height: 12),
              Text('还没有录音，去录一段吧'),
            ],
          ),
        );

      case HomeStatus.error:
        return _StatusBox(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 40, color: AppTheme.rouge),
              const SizedBox(height: 12),
              const Text('加载失败，请重试'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('重试'),
              ),
            ],
          ),
        );

      case HomeStatus.success:
        if (items.isEmpty) {
          return const _StatusBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.inbox_outlined, size: 40, color: AppTheme.ochre),
                SizedBox(height: 12),
                Text('还没有录音，去录一段吧'),
              ],
            ),
          );
        }
        return Column(
          children: <Widget>[
            for (final RecordingItem item in items) itemBuilder(item),
          ],
        );
    }
  }
}

/// 状态占位框：加载/空/错误三态共用的浅色卡片底。
class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}
