import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 令牌存储（契约 §3.1/§3.4）：
/// - `access_token` 只放**内存**，不落盘。
/// - `refresh_token` 放 `flutter_secure_storage`（轮换式，旧值即刻失效）。
/// - `user_id` 一并落盘，用于多账号隔离校验。
///
/// 只存 refresh + user_id，**不要存 access token**（落盘只增加泄露面）。
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _kRefresh = 'refresh_token';
  static const String _kUserId = 'user_id';
  static const String _kLastLoginAt = 'last_login_at';

  /// 免登录窗口：距上次成功登录 ≤ 此时长，冷启动直接信任本地凭证进首页
  /// （断网也不踢），超时则回登录页。产品要求「3 天没登录就重登」。
  static const Duration trustWindow = Duration(days: 3);

  final FlutterSecureStorage _storage;

  String? _accessToken;

  // ---- access（内存） ----

  Future<String?> access() async => _accessToken;

  void setAccess(String? token) => _accessToken = token;

  // ---- refresh（secure storage） ----

  /// 读取落盘的 refresh token、user_id 与最后登录时间；无则返回 null。
  Future<StoredTokens?> read() async {
    final String? refresh = await _storage.read(key: _kRefresh);
    final String? userId = await _storage.read(key: _kUserId);
    if (refresh == null || refresh.isEmpty) {
      return null;
    }
    final String? lastLoginRaw = await _storage.read(key: _kLastLoginAt);
    return StoredTokens(
      refreshToken: refresh,
      userId: userId,
      lastLoginAtMs: int.tryParse(lastLoginRaw ?? ''),
    );
  }

  /// 轮换：立刻覆盖旧 refresh。userId 为空时不覆盖已存值。
  /// 每次成功登录/刷新都刷新「最后登录时间」，作为免登录窗口锚点。
  Future<void> save(TokenPair pair) async {
    await _storage.write(key: _kRefresh, value: pair.refreshToken);
    if (pair.userId != null && pair.userId!.isNotEmpty) {
      await _storage.write(key: _kUserId, value: pair.userId!);
    }
    await _touchLastLogin();
  }

  /// 刷新「最后登录时间」（登录成功 / 静默恢复成功时调用）。
  Future<void> touchLastLogin() => _touchLastLogin();

  Future<void> _touchLastLogin() async {
    final String now = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _kLastLoginAt, value: now);
  }

  /// 清除全部本地凭证（登出 / 令牌被拒时调用）。
  Future<void> clear() async {
    _accessToken = null;
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kLastLoginAt);
  }
}

/// 一次登录/刷新得到的令牌对。
class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.accessExpiresIn,
    this.userId,
  });

  final String accessToken;
  final String refreshToken;

  /// 秒（`access_expires_in`，7200）。
  final int? accessExpiresIn;

  /// 仅登录/注册响应携带；刷新响应无此字段。
  final String? userId;
}

/// 落盘在 secure storage 里的最小凭证集。
class StoredTokens {
  const StoredTokens({required this.refreshToken, this.userId, this.lastLoginAtMs});

  final String refreshToken;
  final String? userId;

  /// 最后一次成功登录/刷新的时间戳（Unix 毫秒）；用于免登录窗口判断。
  final int? lastLoginAtMs;

  /// 是否仍在免登录信任窗口内（距上次登录 ≤ [TokenStore.trustWindow]）。
  /// 无时间戳（老版本数据）视为已过期，回登录页重新登录一次后即有锚点。
  bool get withinTrustWindow {
    final int? ms = lastLoginAtMs;
    if (ms == null) return false;
    final Duration since = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    return since >= Duration.zero && since <= TokenStore.trustWindow;
  }
}
