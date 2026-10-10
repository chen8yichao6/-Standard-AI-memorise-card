import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/dio_client.dart';
import '../../core/guard.dart';
import '../../core/token_store.dart';
import 'models/user.dart';

/// 鉴权数据层（契约 §3）：login / register / me / logout + 冷启动会话判断。
///
/// 所有方法只抛 [ApiException]（经 `guard` 解包）。access 只入内存、refresh 落
/// secure storage，由 [TokenStore] 统一管理，本层不直接碰 dio 拦截器细节。
class AuthRepository {
  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Dio get _dio => _client.dio;
  TokenStore get _tokens => _client.tokens;

  /// 登录（`POST /auth/login`）。成功即已登录，返回 User 并把令牌落好。
  Future<User> login({required String email, required String password}) {
    return guard(() async {
      final Response<Map<String, dynamic>> r =
          await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: <String, dynamic>{
          'email': email,
          'password': password,
          'device_name': 'Android',
        },
      );
      return _absorbAuth(r.data!);
    });
  }

  /// 注册（`POST /auth/register`）。成功即已登录。
  Future<User> register({
    required String email,
    required String password,
    String? nickname,
  }) {
    return guard(() async {
      final Response<Map<String, dynamic>> r =
          await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: <String, dynamic>{
          'email': email,
          'password': password,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
          'device_name': 'Android',
        },
      );
      return _absorbAuth(r.data!);
    });
  }

  /// 上传头像（`PUT /users/me/avatar`，契约 §1.7）。
  ///
  /// `multipart/form-data`，字段名 `file`；≤5 MiB；`jpg`/`png`/`webp`，
  /// 服务端魔数终判（类型不符 415 / 超限 413）。响应同 §1.5（`{user: {...}}`）。
  ///
  /// ⚠️ 服务端做「魔数嗅探」判类型，会结合 `filename` 扩展名 + `Content-Type`
  /// 辅助判定。这里从文件路径取真实扩展名作为 `filename`，并读文件前几字节
  /// 推断真实 `MediaType`，避免 image_picker 缓存路径无扩展名导致 415。
  Future<User> uploadAvatar(String filePath) {
    return guard(() async {
      final String name = _avatarFilename(filePath);
      final MediaType? mediaType = _sniffMediaType(filePath);
      final FormData form = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(
          filePath,
          filename: name,
          contentType: mediaType,
        ),
      });
      final Response<Map<String, dynamic>> r =
          await _dio.put<Map<String, dynamic>>(
        '/users/me/avatar',
        data: form,
      );
      return User.fromJson(r.data!['user'] as Map<String, dynamic>);
    });
  }

  /// 从路径提取文件名；无扩展名时按魔数补一个（后端魔数嗅探依赖扩展名）。
  String _avatarFilename(String filePath) {
    final String base = filePath.split(RegExp(r'[/\\]')).last;
    if (base.contains('.')) {
      return base;
    }
    return '$base.${_sniffMediaType(filePath)?.subtype ?? 'jpg'}';
  }

  /// 读文件前几字节嗅探图片类型（契约仅收 jpg/png/webp）。
  MediaType? _sniffMediaType(String filePath) {
    try {
      final File f = File(filePath);
      final List<int> head = f.readAsBytesSync().take(12).toList();
      if (head.length >= 12 &&
          head[0] == 0xFF &&
          head[1] == 0xD8 &&
          head[2] == 0xFF) {
        return MediaType('image', 'jpeg');
      }
      if (head.length >= 8 &&
          head[0] == 0x89 &&
          head[1] == 0x50 &&
          head[2] == 0x4E &&
          head[3] == 0x47) {
        return MediaType('image', 'png');
      }
      if (head.length >= 12 &&
          head[0] == 0x52 &&
          head[1] == 0x49 &&
          head[2] == 0x46 &&
          head[3] == 0x46 &&
          head[8] == 0x57 &&
          head[9] == 0x45 &&
          head[10] == 0x42 &&
          head[11] == 0x50) {
        return MediaType('image', 'webp');
      }
    } catch (_) {
      // 读不到就返回 null，交给 dio 按文件推断。
    }
    return null;
  }

  /// 冷启动：读取本地凭证（refresh token + user_id + 最后登录时间）。
  /// 无 refresh token 返回 null；有则返回完整凭证集供免登录窗口判断。
  Future<StoredTokens?> hasStoredSession() async {
    return await _tokens.read();
  }

  /// 用本地 user_id 构造最小 User（离线免登录兜底，信息待联网补全）。
  User localUser(String userId) {
    return User(
      id: userId,
      email: '',
      nickname: '',
      avatarUrl: null,
      role: 'user',
      status: 'active',
      avatarUpdatedAt: null,
      createdAt: 0,
    );
  }

  /// 静默恢复成功后刷新「最后登录时间」锚点。
  Future<void> touchSession() => _tokens.touchLastLogin();

  /// 凭证被拒时清除本地凭证。
  Future<void> clearSession() => _tokens.clear();

  /// 拉取当前用户（`GET /users/me`）。
  ///
  /// 冷启动后 access 不在内存，首次调用会 401 → 由 AuthInterceptor 单飞刷新
  /// 补齐 access 并重放，业务层无感知。
  Future<User> me() {
    return guard(() async {
      final Response<Map<String, dynamic>> r =
          await _dio.get<Map<String, dynamic>>('/users/me');
      return User.fromJson(r.data!);
    });
  }

  /// 登出：吊销 refresh token（幂等 204）+ 清本地凭证。
  ///
  /// 服务端吊销失败不阻塞本地清凭证——离线也要能登出。
  Future<void> logout() async {
    final StoredTokens? stored = await _tokens.read();
    if (stored != null && stored.refreshToken.isNotEmpty) {
      try {
        await _dio.post<void>(
          '/auth/logout',
          data: <String, dynamic>{'refresh_token': stored.refreshToken},
          options: Options(extra: <String, dynamic>{'skip_auth': true}),
        );
      } catch (_) {
        // 幂等 204；失败（离线/超时）忽略，本地照清。
      }
    }
    await _tokens.clear();
  }

  /// 把登录/注册响应（`user` + `tokens`）拆解并落好凭证，返回 User。
  Future<User> _absorbAuth(Map<String, dynamic> data) async {
    final User user = User.fromJson(data['user'] as Map<String, dynamic>);
    final Map<String, dynamic> tokens = data['tokens'] as Map<String, dynamic>;
    final TokenPair pair = TokenPair(
      accessToken: tokens['access_token'] as String,
      refreshToken: tokens['refresh_token'] as String,
      accessExpiresIn: tokens['access_expires_in'] as int,
      userId: user.id,
    );
    _tokens.setAccess(pair.accessToken);
    await _tokens.save(pair);
    return user;
  }
}
