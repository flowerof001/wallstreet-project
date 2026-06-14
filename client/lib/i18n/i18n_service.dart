import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'app_locale.dart';

/// 国际化管理服务
class I18nService {
  static final I18nService _instance = I18nService._internal();
  factory I18nService() => _instance;
  I18nService._internal();

  Map<String, dynamic> _currentLocale = {};
  AppLocale _locale = AppLocale.en;

  AppLocale get currentLocale => _locale;
  String get localeCode => _locale.languageCode;

  /// 初始化，加载默认语言
  Future<void> init() async {
    await loadLocale(AppLocale.en);
  }

  /// 加载指定语言
  Future<void> loadLocale(AppLocale locale) async {
    _locale = locale;
    final filePath = 'lib/i18n/locales/${locale.name}.json';
    try {
      final jsonStr = await rootBundle.loadString(filePath);
      _currentLocale = jsonDecode(jsonStr);
    } catch (e) {
      try {
        final fallback = await rootBundle.loadString('lib/i18n/locales/en.json');
        _currentLocale = jsonDecode(fallback);
      } catch (_) {
        _currentLocale = _hardcodedEnglish();
      }
    }
  }

  /// 获取翻译文本
  String t(String key) {
    return _currentLocale[key]?.toString() ?? key;
  }

  /// 硬编码英文翻译作为最终降级
  static Map<String, dynamic> _hardcodedEnglish() {
    return {
      'home': 'Home',
      'watchlist': 'Watchlist',
      'settings': 'Settings',
      'login': 'Login / Register',
      'market_overview': 'Market Overview',
      'search_stock': 'Search stocks...',
      'add_to_watchlist': 'Add to Watchlist',
      'added': 'Added',
      'time_sharing': 'Time Sharing',
      'daily_k': 'Daily K',
      'monthly_k': 'Monthly K',
      'yearly_k': 'Yearly K',
      'change_password': 'Change Password',
      'delete_account': 'Delete Account',
      'delete_account_confirm': 'Delete account?',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'send_code': 'Send Code',
      'enter_phone': 'Enter phone number',
      'enter_code': 'Enter verification code',
      'country_code': 'Country Code',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_password': 'Confirm Password',
      'password_rule': '6-32 characters',
      'market_shanghai_shenzhen': 'Shanghai & Shenzhen',
      'market_beijing': 'Beijing Exchange',
      'market_hongkong': 'Hong Kong',
      'market_us': 'US Market',
      'page': 'Page',
      'add_chart': 'Add Chart',
      'remove_chart': 'Remove Chart',
      'stock_detail': 'Stock Detail',
      'drag_to_reorder': 'Drag to reorder',
      'zoom_in': 'Zoom In',
      'zoom_out': 'Zoom Out',
      'admin_dashboard': 'Admin Dashboard',
      'logout': 'Logout',
      'personal_center': 'My Account',
    };
  }
}

/// 便捷函数，在 Widget 中使用
String t(String key) => I18nService().t(key);
