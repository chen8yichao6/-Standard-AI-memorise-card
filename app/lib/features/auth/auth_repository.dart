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
  Future<User> uploadAvatar(String filePath) {
    return guard(() async {
      final FormData form = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(filePath, filename: 'avatar'),
      });
      final Response<Map<String, dynamic>> r =
          await _dio.put<Map<String, dynamic>>(
        '/users/me/avatar',
        data: form,
      );
      return User.fromJson(r.data!['user'] as Map<String, dynamic>);
    });
  }

  /// 冷启动：本地是否还保留 refresh token（用于决定进登录页还是首页）。
  Future<bool> hasStoredSession() async {
    return await _tokens.read() != null;
  }

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
