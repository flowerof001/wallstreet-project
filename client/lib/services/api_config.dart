/// API & WebSocket 地址配置

class ApiConfig {
  /// Python FastAPI 服务地址
  static String get pythonBaseUrl {
    return 'https://wallstreet-python.onrender.com';
  }

  /// WebSocket 地址
  static String get wsQuotes {
    final base = pythonBaseUrl;
    return base
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://') + '/ws';
  }

  static bool get isLocalDev => false;

  // ---- Convenience URLs ----

  static String get apiV1 => '$pythonBaseUrl/api/v1';

  // Auth
  static String get authSendCode => '$apiV1/auth/send-code';
  static String get authLogin => '$apiV1/auth/login';
  static String get authAdminLogin => '$apiV1/auth/admin/login';

  // User
  static String get userMe => '$apiV1/user/me';
  static String get userChangePassword => '$apiV1/user/change-password';
  static String get userWatchlist => '$apiV1/user/watchlist';
  static String get userPages => '$apiV1/user/pages';
  static String userPageCards(String pageId) => '$apiV1/user/pages/$pageId/cards';
  static String userPageCard(String pageId, String cardId) =>
      '$apiV1/user/pages/$pageId/cards/$cardId';

  // Search
  static String get searchStocks => '$apiV1/search/stocks';

  // Market
  static String quote(String code) => '$pythonBaseUrl/api/v1/quote/$code';
  static String history(String code, {String period = 'daily', int count = 100}) =>
      '$pythonBaseUrl/api/v1/quote/$code/history?period=$period&count=$count';
  static String get marketIndices => '$pythonBaseUrl/api/v1/indices';
  static String get allQuotes => '$pythonBaseUrl/quotes';
  static String singleQuote(String code) => '$pythonBaseUrl/quotes/$code';
}
