/// 统一业务异常 —— 所有非 2xx 最终都映射成本类型抛给 UI 层。
///
/// 映射规则（契约 §0.2/§7，`api-frontend-guide.md` §4.1）：
/// 1. 有 `error.code` → 用 `code`；未知 code 不崩，按 HTTP 状态兜底。
/// 2. 无响应体（超时/断连）→ `code = 'NETWORK_ERROR'`，`requestId = ''`，可重试。
/// 3. `429` / `503` 读 `Retry-After` 响应头（秒）写入 `retryAfterS`。
library;

class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    required this.requestId,
    this.details = const <String, dynamic>{},
    this.httpStatus,
    this.retryAfterS,
  });

  /// 契约 §7 闭集，未知 code 原样保留。
  final String code;

  /// 仅供展示。
  final String message;

  /// `X-Request-Id` / `error.request_id`。
  final String requestId;

  final Map<String, dynamic> details;

  final int? httpStatus;

  /// 429/503 的 `Retry-After`（优先于本地退避）。
  final int? retryAfterS;

  /// 是否可安全重试（幂等白名单之外的进一步判断）。
  bool get retryable =>
      const <String>{
        'OBJECT_NOT_UPLOADED',
        'IDEMPOTENCY_IN_PROGRESS',
        'TRANSCRIPT_NOT_READY',
        'RATE_LIMITED',
        'INTERNAL_ERROR',
        'ASR_CAPACITY_FULL',
        'STORAGE_UNAVAILABLE',
        'SERVICE_UNAVAILABLE',
      }.contains(code) ||
      (httpStatus ?? 0) >= 500;

  @override
  String toString() =>
      'ApiException(code=$code, http=$httpStatus, requestId=$requestId, '
      'message=$message)';
}
