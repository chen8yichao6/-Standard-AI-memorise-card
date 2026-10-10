---
name: ai-memory-card-rules
description: AI 记忆卡（AI Memory Card）Flutter App 的项目规则总纲。This skill should be used before any coding task in this project — 在动手改代码前加载，确保遵守项目已确认的规则：开发协作规则(AGENTS.md)、团队协作规则(CONTRIBUTING)、前端技术约定(TECH_DESIGN)、视觉设计规范(深蓝赛博)。触发场景：开发 AI 记忆卡 App、改 app/ 代码、按今日任务清单推进、提交推送等。
agent_created: true
---

# AI 记忆卡 · 项目规则总纲

本项目 = 「AI 记忆卡」Flutter App。工作区 `D:\06-AI记忆卡`，代码在 `app/`；团队协作库 `D:\07-星禾开物`。

在做任何开发任务前先加载本 skill，按下面四类规则约束行为。规则详情以「权威文件」为准，本文件只提炼可执行要点，规则冲突时团队规则 > 个人规则。

## 一、开发协作规则（权威文件：项目根 `AGENTS.md`，共八章）

1. **任务边界**：收到「今日任务清单」后，清单就是当天唯一范围。只做清单里写的事；不建多余文件、不写清单没提的功能、不提前做以后的天。拿不准是否在范围内，先问，不猜。
2. **一次一步**：先给执行计划（顺序/每步做法/哪些要用户动手），停下等确认；确认后一次只做一个步骤，做完停下报告「做了什么/改了哪些文件/怎么验证」，等用户说「进入下一板块」再继续。
3. **人机分工**：需人工操作的（注册、点按钮、装软件、截图）不代办、不假装完成，只给步骤和预期结果；需生成的（文档/代码）等用户说了再做；拍板点列选项和代价让用户选。
4. **讲清楚**：每步先讲「在作品里的位置→为什么现在做→做完变什么样」，按「结论→为什么→怎么做」讲；默认用户是新手，术语第一次出现用一句话解释。
5. **Git**：提交前先列改动文件清单+每文件属于哪天任务，等确认；commit 格式 `Day X｜一句话说明`；密钥/.env/连接串永远不进提交；一天做完、用户核对完清单后才提交。
6. **收尾**：用户说「今天做完了」后，逐条对照清单完成标准，输出「完成标准/状态(已完成·部分·未完成)/证据」表，诚实标出未完成项，不模糊凑数。
7. **出问题**：撤销用 `git revert` 保留历史，禁 `git reset --hard` 和强推；回退前先确认恢复到哪个提交；同一操作反复失败停下报告，不循环重试。

## 二、团队协作规则（权威文件：`D:\07-星禾开物\CONTRIBUTING.md`）

1. **GitHub Flow**：每任务一分支，命名 `类型/目录-简短描述`（feat/fix/docs/refactor/chore）。
2. **Conventional Commits**：`feat(scope): 一句话`，scope 用目录名（web/server/ai/docs/ci）。个人库则用 `Day X｜一句话`。
3. **PR 纪律**：一个 PR 只做一件事，≤400 行；CI 全绿 + 至少 1 人 review 通过后 Squash merge；合并后删分支。
4. **契约只增不改**：对外契约权威在 `backend/api/openapi.yaml`，内部契约在 `ai/api/openapi.internal.yaml`；改契约要 @ 相关同学确认。
5. **绝不提交 `.env` 和任何 API Key**；没有 Key 时用 mock 模式开发。
6. **无 Issue 先建 Issue**，把自己设为 Assignee。

## 三、前端技术约定（权威文件：`app/` 内 `TECH_DESIGN.md` / `PRD.md`，编号沿用不另起）

1. **音频格式常量集中一处** `audio_constants.dart`：m4a / AAC-LC / 44.1kHz / 单声道 / 128kbps。后端是否接受属契约 T4，不由前端单方定。
2. **「写死」= 只写死种子**：假数据集中在 `lib/data/mock/mock_seed.dart`，首次启动写进 `recordings_index.json`，之后读写走真文件；接真接口只替换数据源，页面组件不动。
3. **主题运行时切换**：`ThemeSpec` 数据包 + `AppThemeController`（ValueNotifier），`MaterialApp(key: ValueKey(themeId))` 强制重建；颜色/字阶转 getter，间距保留 const。
4. **dio 拦截器 onError 逆序执行**（后添加先执行）：addAll 顺序须为 `[ErrorMapping, Retry, Auth, RequestId]`，否则 401 刷新永不生效。错误响应是 `{"error":{code,message,request_id,details}}` 包裹结构。
5. **base path = `/api/v1`**；生产域名 `https://ai-mem.xinghexingsui.com`（注意拼写是 xinghexingsui）。
6. **两个接入位**：`lib/remote/`（后端 API 客户端，已建 dio 层）、`lib/hardware/`（录音卡，本期空壳）。
7. **组件复用**：统一背景 `MechBackground`、面板 `MechPanel`、状态行 `HUD/HudBar/HudLabel`、头像 `MechAvatar`、区块状态 `SectionStatus`，不重复造轮子。

## 四、视觉设计规范（「深蓝赛博」，权威文件：`lib/core/theme/app_theme.dart`）

1. **颜色/字阶/间距一律走 `AppTheme` getter**（如 `AppTheme.primary` / `AppTheme.title` / `AppTheme.gapMd`），禁止硬编码色值。
2. **克制**：一个视觉焦点，其余安静；不堆装饰、不堆动效。
3. **正式场合用国旗红 `#DE2910`**（演讲 PPT 等，非 App 内）。

## 关键环境事实（本机，避免反复踩坑）

- **Git**：用系统 Git 全路径 `C:/Program Files/Git/cmd/git.exe` + `-c http.sslVerify=false`（Steam++ 中间人劫持 HTTPS，PortableGit 的 credential-helper 非交互失效）。
- **编译验证**：用 `flutter build apk --debug`（直接调 Dart 编译器，能暴露真实错误）；`flutter analyze` 走 LSP 通道在本机不稳。
- **模拟器**：窗口模式 `-gpu host`（headless 截图全黑、uiautomator 被 SIGKILL）；adb 操作必须单命令内 `start-server` + `wait-for-device`。
