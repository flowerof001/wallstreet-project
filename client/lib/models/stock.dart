/// 股票数据模型
class Stock {
  final String code;
  final String name;
  final String market; // sh, sz, bj, hk, us
  final double currentPrice;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final double open;
  final double preClose;
  final int volume;
  final double amount;
  final DateTime updateTime;

  const Stock({
    required this.code,
    required this.name,
    required this.market,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
    required this.open,
    required this.preClose,
    required this.volume,
    required this.amount,
    required this.updateTime,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      code: json['code'] as String,
      name: (json['name'] as String?) ?? (json['code'] as String),
      market: (json['market'] as String?) ?? 'sh',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0,
      change: (json['change'] as num?)?.toDouble() ?? 0,
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0,
      high: (json['high'] as num?)?.toDouble() ?? 0,
      low: (json['low'] as num?)?.toDouble() ?? 0,
      open: (json['open'] as num?)?.toDouble() ?? 0,
      preClose: (json['pre_close'] as num?)?.toDouble() ?? 0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      updateTime: json['update_time'] != null
          ? DateTime.tryParse(json['update_time'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'market': market,
        'current_price': currentPrice,
        'change': change,
        'change_percent': changePercent,
        'high': high,
        'low': low,
        'open': open,
        'pre_close': preClose,
        'volume': volume,
        'amount': amount,
        'update_time': updateTime.toIso8601String(),
      };

  /// A股: 涨红跌绿
  bool get isRise => change >= 0;
}

/// 行情页面模型
class MarketPage {
  final String id;
  final String name;
  final List<StockCard> cards;
  final int layoutColumns;

  const MarketPage({
    required this.id,
    required this.name,
    this.cards = const [],
    this.layoutColumns = 3,
  });

  factory MarketPage.fromJson(Map<String, dynamic> json) {
    return MarketPage(
      id: json['page_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      cards: (json['cards'] as List<dynamic>?)
              ?.map((c) => StockCard.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      layoutColumns: json['layout_columns'] as int? ?? 3,
    );
  }
}

/// 走势图卡片模型
class StockCard {
  final String id;
  final String stockCode;
  final String? stockName;
  final int position;
  final double width;
  final double height;
  final String chartType;

  const StockCard({
    required this.id,
    required this.stockCode,
    this.stockName,
    this.position = 0,
    this.width = 400,
    this.height = 300,
    this.chartType = 'time_sharing',
  });

  factory StockCard.fromJson(Map<String, dynamic> json) {
    return StockCard(
      id: json['card_id'] as String? ?? json['id'] as String,
      stockCode: json['stock_code'] as String,
      stockName: json['stock_name'] as String?,
      position: json['position'] as int? ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 400,
      height: (json['height'] as num?)?.toDouble() ?? 300,
      chartType: json['chart_type'] as String? ?? 'time_sharing',
    );
  }

  StockCard copyWith({
    String? id,
    String? stockCode,
    String? stockName,
    int? position,
    double? width,
    double? height,
    String? chartType,
  }) {
    return StockCard(
      id: id ?? this.id,
      stockCode: stockCode ?? this.stockCode,
      stockName: stockName ?? this.stockName,
      position: position ?? this.position,
      width: width ?? this.width,
      height: height ?? this.height,
      chartType: chartType ?? this.chartType,
    );
  }
}
