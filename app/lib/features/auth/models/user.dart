/// 用户模型（契约 `components/schemas/User`）。
///
/// 注册/登录响应与 `GET /users/me` 同构（契约 §1.1/§1.5），复用同一模型。
/// `avatar_url` 每次请求重新签发（presigned GET，15 分钟），未设置头像为 `null`。
library;

class User {
  const User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.avatarUpdatedAt,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'active',
      avatarUpdatedAt: json['avatar_updated_at'] as int?,
      createdAt: json['created_at'] as int,
    );
  }

  final String id;
  final String email;
  final String nickname;
  final String? avatarUrl;

  /// 契约 §0.7 闭集：`user` / `admin`。
  final String role;

  /// 契约 §0.7 闭集：`active` / `disabled` / `deleted`。
  final String status;

  /// 头像最后更新时间（Unix 毫秒）；从未设置过头像时为 `null`。
  final int? avatarUpdatedAt;

  /// 注册时间（Unix 毫秒）。
  final int createdAt;
}
