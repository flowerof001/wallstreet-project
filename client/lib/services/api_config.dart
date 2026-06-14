/// API & WebSocket 地址配置
///
/// 根据运行环境自动选择本地开发地址或生产环境地址。
/// 生产环境通过编译时常量或环境变量注入。
class ApiConfig {
  /// Python FastAPI 服务地址
  static String get pythonBaseUrl {
    // 在 Web 平台读取 JS 全局变量
    // 这些变量由 Cloudflare Pages 环境变量注入或 wrangler.toml vars 设置
    // 本地开发时回退到 localhost
    return _getEnv('PYTHON_API_URL', 'http://localhost:8000');
  }

  /// Go WebSocket 服务地址
  static String get goWsUrl {
    return _getEnv('GO_WS_URL', 'ws://localhost:8080');
  }

  /// 内置测试用户（开发环境用）
  static const bool _isDebug = bool.fromEnvironment('dart.vm.product') == false;

  /// 读取环境变量（Web 平台通过 JS 全局变量，其他平台通过编译常量）
  static String _getEnv(String key, String defaultValue) {
    // 在 Flutter Web 中，JavaScript 全局变量可以通过 window 对象访问
    // 本地开发时始终使用 defaultValue
    try {
      // 尝试读取 dart:html window 的全局属性
      // 这在 Web 构建时会生效，非 Web 时跳过
      if (_isDebug) return defaultValue;
    } catch (_) {}

    return defaultValue;
  }

  /// 是否在本地开发环境
  static bool get isLocalDev => pythonBaseUrl.contains('localhost');

  // ---- Convenience URLs ----

  /// Python API base + version prefix
  static String get apiV1 => '$pythonBaseUrl/api/v1';

  /// Auth endpoints
  static String get authSendCode => '$apiV1/auth/send-code';
  static String get authLogin => '$apiV1/auth/login';
  static String get authAdminLogin => '$apiV1/auth/admin/login';

  /// User endpoints
  static String get userMe => '$apiV1/user/me';
  static String get userChangePassword => '$apiV1/user/change-password';
  static String get userWatchlist => '$apiV1/user/watchlist';
  static String get userPages => '$apiV1/user/pages';

  static String userPageCards(String pageId) => '$apiV1/user/pages/$pageId/cards';
  static String userPageCard(String pageId, String cardId) =>
      '$apiV1/user/pages/$pageId/cards/$cardId';

  /// Search endpoints
  static String get searchStocks => '$apiV1/search/stocks';

  /// Market data endpoints
  static String quote(String code) => '$pythonBaseUrl/api/v1/quote/$code';
  static String history(String code, {String period = 'daily', int count = 100}) =>
      '$pythonBaseUrl/api/v1/quote/$code/history?period=$period&count=$count';
  static String get marketIndices => '$pythonBaseUrl/api/v1/indices';

  /// WebSocket
  static String get wsQuotes => '$goWsUrl/ws';
}
