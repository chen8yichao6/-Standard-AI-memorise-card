# mvp实验产品（试做版归档）

这里存放 **MVP 试做版**的产物，**仅供正式版参考，不再演进**。

## 这是什么

试做版验证了「录音卡 / AI 记忆卡」的产品可行性 —— 口语复读引擎 + 记录闭环，跑通后归档到此。正式版从零重写，需要时从这里取用。

## 内容一览

| 条目 | 说明 |
|---|---|
| `PRD.md` | 产品需求文档（v0.5，65 条验收标准）|
| `TECH_DESIGN.md` | 技术设计（v0.5，含方案对比、接口契约、同步机制）|
| `research.md` | 竞品研究（PLAUD NOTE / 讯飞听见 / 飞书妙记）|
| `录音卡产品-软件层SRS-需求规格说明书.md` / `.pdf` | 口语线需求规格说明书 |
| `英语口语录音卡App-SRS需求规格说明书.md` | 早期 SRS |
| `srs-style.css` | SRS 排版样式 |
| `AGENTS.trial.md` / `CODEBUDDY.trial.md` | 试做版规则（重写正式版规则时的参考）|
| `docs/` | 系统设计 + 时序图/类图 + 环境搭建说明 + 运行说明 + 项目结构图 + 演示材料 |
| `app/` | Flutter 客户端源码（M1 复读机引擎，**不含** build 缓存）|
| `server/` | FastAPI 服务端源码（auth/memories 六接口闭环，**不含** .venv 与数据库）|
| `assets/` | 示例原声等素材 |

## 完整版在哪

| 形态 | 位置 |
|---|---|
| 完整提交历史 | GitHub：`XingHo-VibeCoding/AI-sound-card` |
| 完整运行环境（含 .venv / build） | 本地：`D:\AI-sound-card` |

> 迁移时已排除缓存与依赖（`build` / `.dart_tool` / `.venv` / `__pycache__` / `dev.db`），归档源码净重约 2.5 MB。
