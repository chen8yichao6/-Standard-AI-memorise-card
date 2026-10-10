import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/audio/audio_constants.dart';
import '../mock/mock_seed.dart';

/// 录音列表数据层 —— 全局单例，持「最近录音」列表，驱动首页 / 录音 / 回放三处。
///
/// 数据来源约定（TECH_DESIGN.md §7.4）：
/// 写死数据只当「种子」——首次启动把 [mockRecordings] 落成 `recordings_index.json`，
/// 之后读写都走真文件。将来接真接口时，只替换本文件的数据来源，页面与组件一行不动。
///
/// 模式与 [AuthController] 一致：`ChangeNotifier` 单例，UI 用 `ValueListenableBuilder`
/// 或 `addListener` 监听，做到「录完回首页列表即时更新」。
class RecordingStore extends ChangeNotifier {
  RecordingStore._() : _items = List<RecordingItem>.from(mockRecordings);

  static final RecordingStore instance = RecordingStore._();

  List<RecordingItem> _items;
  bool _loaded = false;

  /// 只读视图（不可从外部直接改列表）。
  List<RecordingItem> get items => List<RecordingItem>.unmodifiable(_items);

  Future<File> _indexFile() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$kIndexFileName');
  }

  /// 启动加载：读 index.json；没有则用种子初始化并落盘。
  /// 幂等：多次调用只执行一次。
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final File f = await _indexFile();
      if (!await f.exists()) {
        await _persist();
        return;
      }
      final List<dynamic> raw = jsonDecode(await f.readAsString()) as List<dynamic>;
      _items = raw
          .map((dynamic e) => RecordingItem.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // 索引损坏 / 读失败：回退到种子，保证不崩。
      _items = List<RecordingItem>.from(mockRecordings);
      notifyListeners();
    }
  }

  /// 新增一条（插到最前，最新在上）。
  Future<void> add(RecordingItem item) async {
    _items.insert(0, item);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final File f = await _indexFile();
      await f.writeAsString(
        jsonEncode(_items.map((RecordingItem e) => e.toJson()).toList()),
      );
    } catch (_) {
      // 写盘失败不阻塞主流程：录音文件本身已落盘，索引下次启动回退种子。
    }
  }
}
