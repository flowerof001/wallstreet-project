/// 用户数据模型
class User {
  final String userId;
  final String phone;
  final String countryCode;
  final String? email;
  final String? ipAddress;
  final String country;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> watchlist; // stock codes
  final bool isGuest;

  const User({
    required this.userId,
    required this.phone,
    required this.countryCode,
    this.email,
    this.ipAddress,
    required this.country,
    required this.createdAt,
    this.lastLoginAt,
    this.watchlist = const [],
    this.isGuest = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as String,
      phone: json['phone'] as String,
      countryCode: json['country_code'] as String,
      email: json['email'] as String?,
      ipAddress: json['ip_address'] as String?,
      country: json['country'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      watchlist: List<String>.from(json['watchlist'] ?? []),
      isGuest: json['is_guest'] as bool? ?? true,
    );
  }

  /// 游客用户
  factory User.guest() => User(
        userId: '',
        phone: '',
        countryCode: '',
        country: 'CN',
        createdAt: DateTime.now(),
        isGuest: true,
      );
}
