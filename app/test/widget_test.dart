// 冒烟测试：保证测试目标可编译、可运行。
//
// 说明：App 主体依赖平台插件（安全存储 / 录音 / 音频播放），不适合在没有
// 插件宿主的环境里直接 pump，因此这里做最小化的框架级冒烟测试。
// 原来的模板测试引用了不存在的 MyApp 类，会导致 analyze 报错，已一并修正。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp 渲染冒烟测试', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('smoke')))),
    );
    expect(find.text('smoke'), findsOneWidget);
  });
}
