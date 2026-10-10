import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/audio/audio_constants.dart';

/// 真录音服务 —— 封装 `record` 插件，把麦克风写成本地 m4a 文件。
///
/// 音频格式见 [kAudioSampleRate] 等常量（m4a / AAC-LC / 44.1kHz / 单声道 / 128kbps）。
/// 文件落在应用文档目录的 `recordings/` 下，文件名用时间戳，保证不重名。
class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  /// 是否正在录音（异步）。
  Future<bool> isRecording() => _recorder.isRecording();

  /// 是否已授予麦克风权限（UI 预检用；`start` 内部也会兜底检查）。
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// 开始录音，返回将要写入的文件完整路径。
  Future<String> start() async {
    if (!await _recorder.hasPermission()) {
      throw const RecordingException('未授予麦克风权限');
    }
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory recDir = Directory('${dir.path}/$kRecordingsDir');
    await recDir.create(recursive: true);
    final String path =
        '${recDir.path}/${DateTime.now().millisecondsSinceEpoch}.$kAudioExtension';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: kAudioSampleRate,
        numChannels: kAudioChannels,
        bitRate: kAudioBitRate,
      ),
      path: path,
    );
    return path;
  }

  /// 停止录音，返回最终文件路径（未在录音时为 null）。
  Future<String?> stop() => _recorder.stop();

  /// 振幅流（dBFS，约 -160 ~ 0），用于实时电平显示。
  Stream<Amplitude> amplitudeStream() =>
      _recorder.onAmplitudeChanged(const Duration(milliseconds: 200));

  Future<void> dispose() => _recorder.dispose();
}

/// 录音异常（权限拒绝等），UI 层捕获后提示。
class RecordingException implements Exception {
  const RecordingException(this.message);

  final String message;

  @override
  String toString() => message;
}
