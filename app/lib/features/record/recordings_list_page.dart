import 'package:flutter/material.dart';

import '../../core/theme/ink_tokens.dart';
import '../../core/widgets/ink/ink.dart';
import '../../data/mock/mock_seed.dart';
import '../../data/recordings/recording_store.dart';
import 'record_page.dart';
import 'recording_detail_page.dart';

/// 全部录音列表页（P2b）。
///
/// 原「记录」tab 落地的是一个**录音页**（与首页那片落墨的录音键功能重叠）。
/// 2026-10-11 改为「全部录音列表」：首页只管「最近几条 + 落墨录音」，
/// 完整列表归这里。右上角「录音」进录音页，录完返回时列表自动刷新
/// （走 [RecordingStore] 的 `notifyListeners`，无需手动传值）。
class RecordingsListPage extends StatefulWidget {
  const RecordingsListPage({super.key});

  @override
  State<RecordingsListPage> createState() => _RecordingsListPageState();
}

class _RecordingsListPageState extends State<RecordingsListPage> {
  @override
  void initState() {
    super.initState();
    RecordingStore.instance.addListener(_onStore);
    RecordingStore.instance.load();
  }

  @override
  void dispose() {
    RecordingStore.instance.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  void _openDetail(RecordingItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecordingDetailPage(item: item),
      ),
    );
  }

  Future<void> _newRecording() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RecordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<RecordingItem> items = RecordingStore.instance.items;
    return Scaffold(
      backgroundColor: Inks.ink,
      body: InkSurface(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              InkAppBar(
                title: '全部录音',
                subtitle: 'RECORDS · 共 ${items.length}',
                onBack: () => Navigator.of(context).pop(),
                trailing: _NewRecordButton(onTap: _newRecording),
              ),
              Expanded(
                child: items.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                        physics: const ClampingScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (BuildContext context, int i) =>
                            InkRecordingRow(
                          item: items[i],
                          first: i == 0,
                          onTap: () => _openDetail(items[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶栏右侧的「录音」入口：朱砂一点 + 衬线小字（不引第四色）。
class _NewRecordButton extends StatelessWidget {
  const _NewRecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.fiber_manual_record, size: 11, color: Inks.seal),
            const SizedBox(width: 6),
            Text(
              '录音',
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: 13,
                letterSpacing: 1,
                color: Inks.paper,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空态：一道短墨线 + 两行提示（不画插画，保持墨落克制）。
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 2.4,
            height: 40,
            color: Inks.paper.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有录音',
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 15,
              letterSpacing: 2,
              color: Inks.paperSoft,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点右上角「录音」，把第一段声音收进来',
            style: TextStyle(fontSize: 12, color: Inks.paperDim),
          ),
        ],
      ),
    );
  }
}
