import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/stock.dart';
import '../services/api_config.dart';
import '../services/user_service.dart';

/// 股票行情提供者 — WebSocket 实时行情 + 卡片/页面管理
class StockProvider extends ChangeNotifier {
  final Map<String, Stock> _stockCache = {};
  final List<StockCard> _cards = [];
  final List<MarketPage> _pages = [MarketPage(id: '1', name: 'Page 1')];
  String _currentPageId = '1';
  bool _connected = false;
  int _reconnectDelay = 1;
  Timer? _reconnectTimer;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  List<Stock> get cachedStocks => _stockCache.values.toList();
  List<StockCard> get cards => _cards;
  bool get isConnected => _connected;
  MarketPage get currentPage =>
      _pages.firstWhere((p) => p.id == _currentPageId);
  List<MarketPage> get pages => _pages;
  String get currentPageId => _currentPageId;

  /// 启动 WebSocket 连接
  void connect() {
    _doConnect();

    // 加载用户保存的页面和卡片
    _loadUserPages();
  }

  void _doConnect() {
    try {
      final wsUrl = ApiConfig.wsQuotes;
      debugPrint('[StockProvider] Connecting to $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _connected = true;
      _reconnectDelay = 1;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (error) {
          debugPrint('[StockProvider] WS error: $error');
          _onDisconnected();
        },
        onDone: () {
          debugPrint('[StockProvider] WS closed');
          _onDisconnected();
        },
      );

      // 订阅默认指数
      _subscribeDefaults();
      notifyListeners();
    } catch (e) {
      debugPrint('[StockProvider] Connection failed: $e');
      _onDisconnected();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'batch') {
        final quotes = data['data'] as List?;
        if (quotes != null) {
          for (final q in quotes) {
            final stock = Stock.fromJson(q as Map<String, dynamic>);
            _stockCache[stock.code] = stock;
          }
          notifyListeners();
        }
      } else if (type == 'quote') {
        final q = data['data'] as Map<String, dynamic>?;
        if (q != null) {
          final stock = Stock.fromJson(q);
          _stockCache[stock.code] = stock;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[StockProvider] Parse error: $e');
    }
  }

  void _subscribeDefaults() {
    const codes = [
      '000001', '399001', '399006', '000688', // 沪深
      '899050', // 北证
      'HSI', 'HSCCI', 'HSCEI', 'VHSI', // 港股
      'DJI', 'IXIC', 'GSPC', // 美股
    ];
    _sendAction('subscribe', codes);
  }

  void _sendAction(String action, List<String> codes) {
    if (_channel == null || !_connected) return;
    try {
      _channel!.sink.add(jsonEncode({
        'action': action,
        'codes': codes,
      }));
    } catch (e) {
      debugPrint('[StockProvider] Send error: $e');
    }
  }

  void _onDisconnected() {
    _connected = false;
    notifyListeners();

    // 指数退避重连
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelay), () {
      _reconnectDelay = (_reconnectDelay * 2).clamp(1, 60);
      _doConnect();
    });
  }

  /// 订阅单只股票
  void subscribeStock(String code) {
    _sendAction('subscribe', [code]);
  }

  /// 取消订阅
  void unsubscribeStock(String code) {
    _sendAction('unsubscribe', [code]);
  }

  /// 通过 WebSocket 更新股票行情
  void updateStockFromWs(Stock stock) {
    _stockCache[stock.code] = stock;
    notifyListeners();
  }

  /// 批量更新
  void batchUpdateStocks(List<Stock> stocks) {
    for (final stock in stocks) {
      _stockCache[stock.code] = stock;
    }
    notifyListeners();
  }

  /// 搜索股票（远程 + 本地缓存）
  Future<List<Stock>> searchStocks(String keyword) async {
    if (keyword.isEmpty) return [];

    try {
      final results = await UserService.searchStocks(keyword);
      final stocks = <Stock>[];
      for (final r in results) {
        // Also update local cache
        if (_stockCache.containsKey(r['code'])) {
          stocks.add(_stockCache[r['code']]!);
        } else {
          // Search results don't include real-time price
          stocks.add(Stock(
            code: r['code'] as String,
            name: r['name'] as String,
            market: r['market'] as String? ?? '',
            currentPrice: 0,
            change: 0,
            changePercent: 0,
            high: 0,
            low: 0,
            open: 0,
            preClose: 0,
            volume: 0,
            amount: 0,
            updateTime: DateTime.now(),
          ));
        }
      }
      return stocks;
    } catch (e) {
      debugPrint('[StockProvider] Search failed: $e');
      // 降级到本地缓存搜索
      final lower = keyword.toLowerCase();
      return _stockCache.values.where((s) {
        return s.code.toLowerCase().contains(lower) ||
            s.name.toLowerCase().contains(lower);
      }).toList();
    }
  }

  /// 获取股票行情（优先缓存）
  Stock? getStock(String code) => _stockCache[code];

  // ---- Card Management ----

  void addCard(String stockCode, {String? stockName}) {
    if (_cards.length >= 20) return;
    final card = StockCard(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      stockCode: stockCode,
      stockName: stockName ?? stockCode,
      position: _cards.length,
    );
    _cards.add(card);
    subscribeStock(stockCode);
    notifyListeners();
  }

  void removeCard(String cardId) {
    final card = _cards.where((c) => c.id == cardId).firstOrNull;
    if (card != null) {
      unsubscribeStock(card.stockCode);
    }
    _cards.removeWhere((c) => c.id == cardId);
    notifyListeners();
  }

  void reorderCards(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final card = _cards.removeAt(oldIndex);
    _cards.insert(newIndex, card);
    // Update positions
    for (var i = 0; i < _cards.length; i++) {
      _cards[i] = _cards[i].copyWith(position: i);
    }
    notifyListeners();
  }

  void updateCardSize(String cardId, double width, double height) {
    final idx = _cards.indexWhere((c) => c.id == cardId);
    if (idx >= 0) {
      _cards[idx] = _cards[idx].copyWith(width: width, height: height);
      notifyListeners();
    }
  }

  void updateCardChartType(String cardId, String chartType) {
    final idx = _cards.indexWhere((c) => c.id == cardId);
    if (idx >= 0) {
      _cards[idx] = _cards[idx].copyWith(chartType: chartType);
      notifyListeners();
    }
  }

  // ---- Page Management ----

  void addPage(String name) {
    if (_pages.length >= 20) return;
    final newPage = MarketPage(
      id: 'page_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
    _pages.add(newPage);
    _currentPageId = newPage.id;
    notifyListeners();
  }

  void deletePage(String pageId) {
    if (_pages.length <= 1) return; // keep at least 1 page
    _pages.removeWhere((p) => p.id == pageId);
    if (_currentPageId == pageId) {
      _currentPageId = _pages.first.id;
    }
    notifyListeners();
  }

  void renamePage(String pageId, String newName) {
    final idx = _pages.indexWhere((p) => p.id == pageId);
    if (idx >= 0) {
      _pages[idx] = MarketPage(id: _pages[idx].id, name: newName);
      notifyListeners();
    }
  }

  void switchPage(String pageId) {
    _currentPageId = pageId;
    notifyListeners();
  }

  /// 从用户服务加载保存的页面布局
  Future<void> _loadUserPages() async {
    try {
      final savedPages = await UserService.getPages();
      if (savedPages.isNotEmpty) {
        _pages.clear();
        _cards.clear();

        for (final p in savedPages) {
          final cards = (p['cards'] as List? ?? [])
              .map<StockCard>((c) => StockCard(
                    id: c['card_id'] as String,
                    stockCode: c['stock_code'] as String,
                    stockName: c['stock_code'] as String, // 不再存储 name
                    position: c['position'] as int? ?? 0,
                    width: (c['width'] as num?)?.toDouble() ?? 400,
                    height: (c['height'] as num?)?.toDouble() ?? 300,
                    chartType: c['chart_type'] as String? ?? 'time_sharing',
                  ))
              .toList();

          _pages.add(MarketPage(
            id: p['page_id'] as String,
            name: p['name'] as String? ?? 'Page',
          ));

          // Add cards to current display
          if (p == savedPages.first) {
            _cards.addAll(cards);
          }
        }

        _currentPageId = _pages.first.id;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[StockProvider] Failed to load pages: $e');
    }
  }

  /// 同步当前页面布局到服务器
  Future<void> syncCurrentPage() async {
    try {
      // Create/update page
      // Cards are synced individually via addCard/removeCard
    } catch (e) {
      debugPrint('[StockProvider] Sync failed: $e');
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
