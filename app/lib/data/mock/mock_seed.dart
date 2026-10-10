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

/// 录音类型（分类筛选维度；元信息写死，只当种子）。
enum RecordingType {
  meeting('会议'),
  classNote('课堂'),
  training('训练'),
  interview('采访');

  final String label;
  const RecordingType(this.label);
}

/// 一条录音记录（最近录音列表里的项）。
///
/// 元信息来源：种子数据写死；真录音写入后走 `recordings_index.json`。
/// [filePath] 是本地音频文件完整路径——种子数据没有真文件，为 `null`；
/// 真录音落地后才有值，回放页据此加载音频。
class RecordingItem {
  const RecordingItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.date,
    required this.type,
    this.filePath,
  });

  final String id;
  final String title;
  final String duration;
  final String date;
  final RecordingType type;
  final String? filePath;

  /// 序列化（写 `recordings_index.json` 用）。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'duration': duration,
        'date': date,
        'type': type.name,
        'filePath': filePath,
      };

  /// 反序列化（读 `recordings_index.json` 用）。
  factory RecordingItem.fromJson(Map<String, dynamic> json) => RecordingItem(
        id: json['id'] as String,
        title: json['title'] as String,
        duration: json['duration'] as String,
        date: json['date'] as String,
        type: RecordingType.values.firstWhere(
          (RecordingType t) => t.name == json['type'],
          orElse: () => RecordingType.meeting,
        ),
        filePath: json['filePath'] as String?,
      );
}

/// 基础功能 —— 本期只有一个：录音。
const List<FeatureItem> mockFeatures = <FeatureItem>[
  FeatureItem(id: 'record', title: '录音', subtitle: '记录每一段声音'),
];

/// 最近录音 —— 写死的元信息（只当种子）。
///
/// 类型分布：会议 / 课堂 / 训练 各 1 条，「采访」类型刻意留空 ——
/// 分类筛选用它测「无结果」态（选采访 → 0 条）。
const List<RecordingItem> mockRecordings = <RecordingItem>[
  RecordingItem(
    id: 'r1',
    title: '班会纪要',
    duration: '12:30',
    date: '09-28',
    type: RecordingType.meeting,
  ),
  RecordingItem(
    id: 'r2',
    title: '英语课笔记',
    duration: '45:08',
    date: '09-27',
    type: RecordingType.classNote,
  ),
  RecordingItem(
    id: 'r3',
    title: '太极训练心得',
    duration: '08:15',
    date: '09-26',
    type: RecordingType.training,
  ),
];

/// 当前用户（P1 个人页面顶部展示的占位信息）。
///
/// 本期账号区写死：默认就是「未登录」占位态（对应 PRD EX-11），
/// 不虚构真实昵称/手机号。将来接 T1 认证接口时，只替换这里的来源。
class UserProfile {
  const UserProfile({required this.nickname, required this.account});

  final String nickname;
  final String account;
}

/// 未登录占位态。
const UserProfile mockUser = UserProfile(nickname: '未登录', account: '账号区待接入');
