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

/// 行情页面模型：页面可包含最多20张走势图卡片
class MarketPage {
  final String id;
  final String name;
  final List<StockCard> cards; // 最多20张
  final int layoutColumns; // 列数

  const MarketPage({
    required this.id,
    required this.name,
    this.cards = const [],
    this.layoutColumns = 3,
  });

  factory MarketPage.fromJson(Map<String, dynamic> json) {
    return MarketPage(
      id: json['id'] as String,
      name: json['name'] as String,
      cards: (json['cards'] as List<dynamic>?)
              ?.map((c) => StockCard.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      layoutColumns: json['layout_columns'] as int? ?? 3,
    );
  }
}

/// 走势图卡片：单只股票的走势图卡片
class StockCard {
  final String id;
  final String stockCode;
  final double width;
  final double height;
  final int position; // 排序位置
  final String chartType; // time_sharing, daily_k, monthly_k, yearly_k

  const StockCard({
    required this.id,
    required this.stockCode,
    this.width = 400,
    this.height = 300,
    this.position = 0,
    this.chartType = 'time_sharing',
  });

  factory StockCard.fromJson(Map<String, dynamic> json) {
    return StockCard(
      id: json['id'] as String,
      stockCode: json['stock_code'] as String,
      width: (json['width'] as num?)?.toDouble() ?? 400,
      height: (json['height'] as num?)?.toDouble() ?? 300,
      position: json['position'] as int? ?? 0,
      chartType: json['chart_type'] as String? ?? 'time_sharing',
    );
  }
}
