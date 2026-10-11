import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/ink_tokens.dart';
import '../../data/mock/mock_seed.dart';
import '../../data/recordings/recording_store.dart';
import '../../services/recording_service.dart';
import '../profile/profile_page.dart';
import '../record/record_page.dart';
import '../record/recording_detail_page.dart';
import 'widgets/ink_stamp.dart';

/// 首页（P2）—— v11「墨落」落地版。
///
/// 行为母题：**按下 → 墨落 → 渗开 → 显影**。
/// - 上半屏 = 生宣（落墨区，纸出血到屏幕边缘，底边手工毛边）
/// - 下半屏 = 暗房（已显影的底片，颗粒只归这里）
///
/// 三色纪律：墨 = 黑 ／ 印 = 朱 ／ 显影 = 琥珀。待机全屏零发光。
/// 视觉规格来自 `.workbuddy/pack/AI记忆卡-首页设计-v11`（九步流程 + 9 轮评审 8.5/10）。
///
/// ⚠ 本页刻意**不接入 AppTheme 换肤**：母题里的朱砂印章与琥珀显影是语义色，
/// 换色会一起毁掉。详见 [Inks] 顶部注释。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RecordingService _svc = RecordingService();

  bool _recording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    RecordingStore.instance.addListener(_onStore);
    RecordingStore.instance.load();
    // 生宣是浅色，状态栏图标须转深色（否则白图标压在纸上看不见）。
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    RecordingStore.instance.removeListener(_onStore);
    _timer?.cancel();
    _svc.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  // ── 录音（复用真录音服务，录音键就在首页）─────────────────
  Future<void> _toggleRecord() async {
    if (_recording) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    try {
      await _svc.start();
      if (!mounted) {
        await _svc.stop();
        return;
      }
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    } on RecordingException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('录音启动失败：$e');
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    final String? path = await _svc.stop();
    if (!mounted) return;
    setState(() => _recording = false);
    if (path == null) {
      _toast('未录到音频，请重试');
      return;
    }
    final RecordingItem item = RecordingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '录音 ${_hhmm()}',
      duration: _fmt(_elapsed),
      date: '今天 ${_hhmm()} · 刚录制',
      type: RecordingType.meeting,
      filePath: path,
    );
    await RecordingStore.instance.add(item);
    if (!mounted) return;
    _toast('已收录「${item.title}」· ${item.duration}');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmt(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _hhmm() {
    final DateTime n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}';
  }

  void _openDetail(RecordingItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RecordingDetailPage(item: item)),
    );
  }

  void _openTab(int i) {
    if (i == 0) return;
    final Widget page = i == 1 ? const RecordPage() : const ProfilePage();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Inks.ink,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final double sheetH = c.maxHeight * Inks.sheetRatio;
          return Stack(
            children: <Widget>[
              // 暗房铺满整屏（生宣盖住上半，撕纸缺口处透出来）
              Positioned.fill(child: _darkRoomBg()),
              // 上半屏：生宣
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: sheetH,
                child: _sheet(),
              ),
              // 下半屏：暗房内容
              Positioned(
                left: 0,
                right: 0,
                top: sheetH,
                bottom: 0,
                child: _darkRoomContent(),
              ),
              // 底部导航（融进暗房，不浮起）
              Positioned(left: 0, right: 0, bottom: 0, child: _tabBar()),
            ],
          );
        },
      ),
    );
  }

  // ── 暗房底 ────────────────────────────────────────────────
  Widget _darkRoomBg() {
    return Stack(
      children: <Widget>[
        Container(color: Inks.ink),
        // 颗粒（1:1 tile，normal 混合只在暗房）
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/ink/film-grain-dark.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        ),
        // 镜头暗角（只属于暗房，不越界到纸上）
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  center: const Alignment(0, -0.16),
                  stops: const <double>[0, 0.48, 1],
                  colors: <Color>[
                    const Color(0x00000000),
                    const Color(0x00000000),
                    Colors.black.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 上半屏：生宣 ──────────────────────────────────────────
  Widget _sheet() {
    return ClipPath(
      clipper: const _DeckleClipper(),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Inks.sheetBg,
          image: DecorationImage(
            image: AssetImage('assets/ink/paper.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment(0, -0.6),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _BrandHeader(),
                const SizedBox(height: 18),
                const _Inscription(),
                Expanded(
                  child: Center(
                    // 小屏兜底：墨团固定 330，屏太矮时按比例缩小而不是溢出。
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: InkStamp(
                        recording: _recording,
                        onTap: _toggleRecord,
                      ),
                    ),
                  ),
                ),
                _hint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hint() {
    final String h1 =
        _recording ? '正在录音 · 按一下结束' : '按一下开始录音';
    final String h2 = _recording ? _fmt(_elapsed) : '或长按进入速记';
    return Column(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            h1,
            key: ValueKey<String>(h1),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Inks.inkOnPaper,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _recording
              // 计时刻意用墨色（不用琥珀）：琥珀的职责是「显影」，
              // 计时属于「渗开」阶段，靠等宽数字 + 字距取得存在感。
              ? Text(
                  h2,
                  key: ValueKey<String>(h2),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Inks.inkOnPaper,
                    letterSpacing: 1.6,
                    fontFeatures: <ui.FontFeature>[
                      ui.FontFeature.tabularFigures(),
                    ],
                  ),
                )
              : Text(
                  h2,
                  key: ValueKey<String>(h2),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Inks.inkOnPaperDim,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ],
    );
  }

  // ── 下半屏：暗房内容 ──────────────────────────────────────
  Widget _darkRoomContent() {
    final List<RecordingItem> items = RecordingStore.instance.items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _recentHeader(items.length),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int i) => _RecentRow(
                item: items[i],
                first: i == 0,
                onTap: () => _openDetail(items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentHeader(int count) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              '最近 · 共 $count 段',
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 1,
                color: Inks.paper.withValues(alpha: 0.72),
              ),
            ),
            const Spacer(),
            Text(
              '全部 →',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.5,
                color: Inks.paper.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        // 分隔线 = 两端淡出的墨线（通栏实线是「通用深色列表」最强的信号）
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                Inks.paper.withValues(alpha: 0.20),
                Inks.paper.withValues(alpha: 0.10),
                Inks.paper.withValues(alpha: 0.04),
              ],
              stops: const <double>[0, 0.4, 1],
            ),
          ),
          child: const SizedBox(height: 1, width: double.infinity),
        ),
      ],
    );
  }

  // ── 底部导航 ──────────────────────────────────────────────
  Widget _tabBar() {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 60,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Inks.paper.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _TabItem(
                kind: _TabKind.home,
                label: '首页',
                active: true,
                onTap: () => _openTab(0),
              ),
              _TabItem(
                kind: _TabKind.record,
                label: '记录',
                active: false,
                onTap: () => _openTab(1),
              ),
              _TabItem(
                kind: _TabKind.mine,
                label: '我的',
                active: false,
                onTap: () => _openTab(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 生宣区组件
// ══════════════════════════════════════════════════════════════

/// 撕纸毛边：把生宣的**底边**裁成手工撕出来的一排起伏。
///
/// ⚠ v11 血泪：边缘起伏必须做到「渲染尺度下能存活」的大小 —— 亚像素细节会被
/// 抗锯齿平均掉。这里用**多尺度正弦 + 固定 seed 抖动**合成，段数 72、振幅约 ±4。
class _DeckleClipper extends CustomClipper<Path> {
  const _DeckleClipper();

  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 8);

    const int segments = 72;
    final double step = size.width / segments;
    final math.Random rnd = math.Random(17);
    // 从右到左回描底边
    for (int i = segments; i >= 0; i--) {
      final double x = i * step;
      final double wave =
          math.sin(i * 0.85) * 2.0 + math.sin(i * 0.31 + 1.3) * 1.4;
      final double jitter = (rnd.nextDouble() * 2 - 1) * 1.6;
      final double y = size.height - 7 + (wave + jitter) * 0.7;
      path.lineTo(x, y);
    }
    path
      ..lineTo(0, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 品牌牌：朱砂印章「记」+ 名称 + 汉堡菜单。这一次印章是真的盖在纸上。
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // 印章
        Transform.rotate(
          angle: -0.035, // ≈ -2deg
          child: Container(
            width: Inks.sealSize,
            height: Inks.sealSize,
            decoration: BoxDecoration(
              color: Inks.seal,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(3),
                bottomLeft: Radius.circular(1),
                bottomRight: Radius.circular(3),
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Inks.sealPaper.withValues(alpha: 0.85),
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: const Text(
                  '记',
                  style: TextStyle(
                    fontFamily: _serif,
                    fontSize: 20,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: Inks.sealPaper,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'AI 记忆卡',
          style: TextStyle(
            fontFamily: _serif,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
            color: Inks.inkOnPaper.withValues(alpha: 0.78),
          ),
        ),
        const Spacer(),
        // 汉堡菜单（三笔墨痕）
        SizedBox(
          width: 40,
          height: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Container(
                  width: 18,
                  height: 1.5,
                  margin: const EdgeInsets.only(bottom: 3.5),
                  decoration: BoxDecoration(
                    color: Inks.inkOnPaper.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 题字：「开口，便被记下。」—— 「记」用朱砂。
class _Inscription extends StatelessWidget {
  const _Inscription();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          const TextSpan(text: '开口，便被'),
          TextSpan(
            text: '记',
            style: TextStyle(
              fontFamily: _serif,
              fontSize: 23,
              color: Inks.seal,
            ),
          ),
          const TextSpan(text: '下。'),
        ],
      ),
      style: const TextStyle(
        fontFamily: _serif,
        fontSize: 21,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.5,
        color: Inks.inkOnPaper,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 暗房区组件
// ══════════════════════════════════════════════════════════════

/// 最近录音的一条。左竖墨线 + 状态符号 + 标题/元信息 + 时长 + 播放键。
class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.item,
    required this.first,
    required this.onTap,
  });

  final RecordingItem item;
  final bool first;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool tc = item.isTranscribing;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          // 行与行之间也是墨线（两端淡出），而不是靠留白分隔
          if (!first)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Inks.paper.withValues(alpha: 0.10),
                    Inks.paper.withValues(alpha: 0.05),
                    const Color(0x00000000),
                  ],
                  stops: const <double>[0, 0.45, 1],
                ),
              ),
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                // 每行左侧一道短竖墨线：把这一行「挂」在纸上
                Container(
                  width: 2,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Inks.paper.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 9),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CustomPaint(
                    painter: _StatusMarkPainter(
                      transcribing: tc,
                      color: tc ? Inks.progress : Inks.paper,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _title(tc),
                      const SizedBox(height: 4),
                      Text(
                        item.date,
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 0.3,
                          color: tc ? Inks.progress : Inks.paperDim,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.duration,
                  style: TextStyle(
                    fontSize: 13,
                    color: tc ? Inks.progress : Inks.paperSoft,
                    fontFeatures: const <ui.FontFeature>[
                      ui.FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                if (!tc) ...<Widget>[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(
                      painter: _PlayPainter(
                        color: Inks.paperSoft,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(bool tc) {
    const TextStyle base = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Inks.paper,
      letterSpacing: 0,
    );
    if (!tc) return Text(item.title, style: base);
    // 转写中 = 正在显影：标题由模糊浮到清晰、再退回。
    return _DevelopText(text: item.title, style: base);
  }
}

/// 「显影」文字：模糊 ↔ 清晰循环（母题第三个动作）。
///
/// ⚠ 用负相位起步（从周期的「清晰段」开始）—— 否则页面刚加载就被看到，
/// 正好停在最模糊的一帧。
class _DevelopText extends StatefulWidget {
  const _DevelopText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_DevelopText> createState() => _DevelopTextState();
}

class _DevelopTextState extends State<_DevelopText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  @override
  void initState() {
    super.initState();
    _c.value = 0.5; // 负 delay 等价：从周期中点（清晰段）起步
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double p = _c.value;
        double blur = 0;
        double op = 1;
        if (p < 0.12) {
          final double t = p / 0.12;
          blur = 0.9 * (1 - t);
          op = 0.86 + 0.14 * t;
        } else if (p > 0.88) {
          final double t = (p - 0.88) / 0.12;
          blur = 0.9 * t;
          op = 1 - 0.14 * t;
        }
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Opacity(opacity: op, child: child),
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}

/// 状态符号：已生成 = 实心墨点；转写中 = 半显影的琥珀环。
class _StatusMarkPainter extends CustomPainter {
  const _StatusMarkPainter({required this.transcribing, required this.color});

  final bool transcribing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    if (!transcribing) {
      canvas.drawCircle(c, 4, Paint()..color = color);
      return;
    }
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.22);
    canvas.drawCircle(c, size.width / 2 - 1, ring);
    // 停在「半显影」的一段弧
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: size.width / 2 - 1),
      -math.pi / 2,
      math.pi,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _StatusMarkPainter old) =>
      old.transcribing != transcribing || old.color != color;
}

/// 播放三角。
class _PlayPainter extends CustomPainter {
  const _PlayPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(size.width * 0.18, size.height * 0.12)
      ..lineTo(size.width * 0.86, size.height * 0.5)
      ..lineTo(size.width * 0.18, size.height * 0.88)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PlayPainter old) => old.color != color;
}

// ══════════════════════════════════════════════════════════════
// 底部导航
// ══════════════════════════════════════════════════════════════

enum _TabKind { home, record, mine }

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.kind,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final _TabKind kind;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        active ? Inks.paper : Inks.paper.withValues(alpha: 0.40);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedScale(
            scale: active ? 1.07 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(painter: _TabIconPainter(kind, color)),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 三个图标都是母题符号：方印（首页）／声波+落墨（记录）／毛笔（我的）。
/// 选中态靠**笔画视觉加重**而非换色 —— 这个页面只有三档语义色，导航不该引进第四种。
class _TabIconPainter extends CustomPainter {
  const _TabIconPainter(this.kind, this.color);

  final _TabKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()..color = color;

    if (kind == _TabKind.home) {
        // 子母印：外框（粗）+ 内框（细、只描边）
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4.4 * s, 4.4 * s, 15.2 * s, 15.2 * s),
            Radius.circular(2.2 * s),
          ),
          stroke
            ..strokeWidth = 1.8 * s
            ..color = color,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(8.4 * s, 8.4 * s, 7.2 * s, 7.2 * s),
            Radius.circular(1.4 * s),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.15 * s
            ..strokeJoin = StrokeJoin.round
            ..color = color.withValues(alpha: 0.62),
        );
    } else if (kind == _TabKind.record) {
        // 五根不等长墨痕 + 底下一点落墨
        final List<double> xs = <double>[5.6, 8.9, 12.2, 15.5, 18.8];
        final List<double> tops = <double>[8.2, 5.4, 4.2, 6.2, 8.6];
        final List<double> bots = <double>[12.6, 15.4, 16.8, 14.6, 12.2];
        for (int i = 0; i < 5; i++) {
          canvas.drawLine(
            Offset(xs[i] * s, tops[i] * s),
            Offset(xs[i] * s, bots[i] * s),
            Paint()
              ..color = color
              ..strokeWidth = 2 * s
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawCircle(Offset(12 * s, 19.8 * s), 1.85 * s, fill);
    } else {
        // 一支搁着的毛笔（斜笔杆 + 收尖的笔锋）
        canvas.drawLine(
          Offset(19.5 * s, 4.1 * s),
          Offset(12.3 * s, 11.3 * s),
          Paint()
            ..color = color
            ..strokeWidth = 2.7 * s
            ..strokeCap = StrokeCap.round,
        );
        final Path tip = Path()
          ..moveTo(12.3 * s, 11.3 * s)
          ..lineTo(6.7 * s, 19.2 * s)
          ..lineTo(11.4 * s, 16.4 * s)
          ..lineTo(13.3 * s, 12.7 * s)
          ..close();
        canvas.drawPath(tip, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _TabIconPainter old) =>
      old.kind != kind || old.color != color;
}

/// 衬线字族名。Android 上以系统衬线族兜底（CJK 可能回退到系统无衬线）。
///
/// TODO(字体)：正式版应打包 `Noto Serif SC`（600/900）子集 + `Ma Shan Zheng`（只留「记」），
/// 见 v11 的「工程侧 TODO · 字体子集化」。
const String _serif = 'serif';
