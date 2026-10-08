/// 环境配置 —— 全部通过 `--dart-define` 注入，禁止在代码里硬编码地址。
///
/// 团队契约（`docs/api-frontend-guide.md` §2.4）：
/// - `API_BASE_URL` / `WS_BASE_URL` 由构建时注入，默认指向团队后端。
/// - 后端 base path = `/api/v1`（`backend/internal/contract/ownership.yaml` 全量路径均带此前缀）。
/// - OSS 直传 host 由服务端下发的 `upload_url` 决定，与 `apiBaseUrl` 无关，禁止自己拼。
///
/// 真机连本地后端（模拟器地址不同）：
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1 \
///               --dart-define=WS_BASE_URL=ws://10.0.2.2:8080/api/v1
library;

class Env {
  Env._();

  /// 后端 REST API 根地址（含 `/api/v1` 前缀）。
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ai-mem.xinghexingsui.com/api/v1',
  );

  /// 实时转写 WebSocket 根地址（含 `/api/v1` 前缀）。
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://ai-mem.xinghexingsui.com/api/v1',
  );

  /// 默认连接/接收超时（`/search` 15s、`complete` 30s、导出 60s 单独覆盖）。
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
