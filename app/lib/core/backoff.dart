import 'dart:math' as math;

/// 退避计算（契约 §4.3）：`Retry-After` 优先，否则指数退避 + ±20% 抖动。
///
/// 基数序列 1, 2, 4, 8, 16, 30…（封顶 30 秒）。
Duration backoff(int attempt, {int? retryAfterS}) {
  if (retryAfterS != null) {
    return Duration(seconds: retryAfterS);
  }
  final int base = math.min(30, math.pow(2, attempt).toInt());
  final double jitter = 0.8 + math.Random().nextDouble() * 0.4; // ±20%
  return Duration(milliseconds: (base * 1000 * jitter).round());
}
