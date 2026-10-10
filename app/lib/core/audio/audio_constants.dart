/// 音频格式常量 —— 全 App 录音落盘的唯一出口。
///
/// 规格 Day 5 定死（见 TECH_DESIGN.md §7.4）：m4a / AAC-LC / 44.1 kHz / 单声道 / 128 kbps。
/// 后端是否接受这一规格属契约 T4，不由前端单方定；本文件只描述「本 App 录音落盘」的规格，
/// 与后端上传是两件事。
library;

/// 音频文件扩展名（容器 = m4a）。
const String kAudioExtension = 'm4a';

/// 编码 = AAC-LC（对应 record 插件的 `AudioEncoder.aacLc`）。
///
/// 仅作人类可读说明，实际编码枚举由 `RecordingService` 引用 record 插件传入。

/// 采样率：44.1 kHz。
const int kAudioSampleRate = 44100;

/// 声道数：单声道。
const int kAudioChannels = 1;

/// 码率：128 kbps（1 小时 ≈ 58 MB）。
const int kAudioBitRate = 128000;

/// 录音文件目录名（位于应用文档目录下）。
const String kRecordingsDir = 'recordings';

/// 录音列表索引文件名（位于应用文档目录下）。
const String kIndexFileName = 'recordings_index.json';
