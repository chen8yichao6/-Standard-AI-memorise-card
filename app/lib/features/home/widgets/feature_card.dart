import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mech_panel.dart';

/// 主动作入口卡片（本期只有「录音」）。
///
/// 深蓝赛博：金属渐变面板 + 青色左条 + 铆钉点 + 右上 REC 标。
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MechPanel(
      onTap: onTap,
      accentBar: true,
      bolts: true,
      raised: true,
      padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(title, style: AppTheme.title),
                    const SizedBox(width: AppTheme.gapXs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryDim),
                      ),
                      child: Text(
                        'REC',
                        style: AppTheme.micro.copyWith(color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.gapXxs),
                Text(subtitle, style: AppTheme.caption),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppTheme.primary, size: 22),
        ],
      ),
    );
  }
}
