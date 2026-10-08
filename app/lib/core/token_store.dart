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

  final FlutterSecureStorage _storage;

  String? _accessToken;

  // ---- access（内存） ----

  Future<String?> access() async => _accessToken;

  void setAccess(String? token) => _accessToken = token;

  // ---- refresh（secure storage） ----

  /// 读取落盘的 refresh token 与 user_id；无则返回 null。
  Future<StoredTokens?> read() async {
    final String? refresh = await _storage.read(key: _kRefresh);
    final String? userId = await _storage.read(key: _kUserId);
    if (refresh == null || refresh.isEmpty) {
      return null;
    }
    return StoredTokens(refreshToken: refresh, userId: userId);
  }

  /// 轮换：立刻覆盖旧 refresh。userId 为空时不覆盖已存值。
  Future<void> save(TokenPair pair) async {
    await _storage.write(key: _kRefresh, value: pair.refreshToken);
    if (pair.userId != null && pair.userId!.isNotEmpty) {
      await _storage.write(key: _kUserId, value: pair.userId!);
    }
  }

  /// 清除全部本地凭证（登出 / 令牌被拒时调用）。
  Future<void> clear() async {
    _accessToken = null;
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUserId);
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
  const StoredTokens({required this.refreshToken, this.userId});

  final String refreshToken;
  final String? userId;
}
