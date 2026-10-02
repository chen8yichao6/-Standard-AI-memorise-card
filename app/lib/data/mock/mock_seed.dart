/// Mock 数据种子 —— 本期所有「写死数据」集中在这一处。
///
/// 约定（见 TECH_DESIGN.md §7.4）：
/// 假数据只当「种子」，初始内容写死；将来接真接口时只替换本文件的数据来源，
/// 页面与组件一行不动。图标映射放在 UI 层，这里只存纯数据，不依赖 Flutter。
library;

/// 一个功能入口（基础功能区里的项）。
class FeatureItem {
  const FeatureItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

/// 一条录音记录（最近录音列表里的项，元信息写死）。
class RecordingItem {
  const RecordingItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.date,
  });

  final String id;
  final String title;
  final String duration;
  final String date;
}

/// 基础功能 —— 本期只有一个：录音。
const List<FeatureItem> mockFeatures = <FeatureItem>[
  FeatureItem(
    id: 'record',
    title: '录音',
    subtitle: '记录每一段声音',
  ),
];

/// 最近录音 —— 写死的元信息（只当种子）。
const List<RecordingItem> mockRecordings = <RecordingItem>[
  RecordingItem(id: 'r1', title: '班会纪要', duration: '12:30', date: '09-28'),
  RecordingItem(id: 'r2', title: '英语课笔记', duration: '45:08', date: '09-27'),
  RecordingItem(id: 'r3', title: '太极训练心得', duration: '08:15', date: '09-26'),
];
