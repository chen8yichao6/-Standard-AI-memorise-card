import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_spec.dart';

/// 主题控制器 —— 持有当前 [ThemeSpec]，负责装配与切换。
///
/// 全局单例：`AppTheme` 里的颜色/字阶 getter 都从它读；
/// 设置页点选 → [setTheme] 换主题 → `notifyListeners` → 根部 [ListenableBuilder]
/// 重建 MaterialApp，全 App 立即换色。
///
/// 持久化：`theme_id` 存 `shared_preferences`（本地），启动时 [load] 读回。
/// 对应 PRD F-08「退出 App 再进来，选中的主题仍然生效」。
class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  static const String _keyThemeId = 'theme_id';

  ThemeSpec _spec = ThemeSpec.dark;
  ThemeSpec get spec => _spec;
  ThemeData get themeData => _spec.toThemeData();

  /// 启动时读本地存的 theme_id 并装配。在 `runApp` 之前调用。
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? id = prefs.getString(_keyThemeId);
    if (id == null) return;
    final ThemeSpec next = ThemeSpec.byId(id);
    if (next.id != _spec.id) {
      _spec = next;
    }
  }

  /// 切换主题：换 spec → 通知重建 → 写本地。
  Future<void> setTheme(String id) async {
    final ThemeSpec next = ThemeSpec.byId(id);
    if (next.id == _spec.id) return;
    _spec = next;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeId, id);
  }
}
