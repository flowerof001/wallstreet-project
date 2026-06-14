import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'app_locale.dart';

/// 国际化管理服务
class I18nService {
  static final I18nService _instance = I18nService._internal();
  factory I18nService() => _instance;
  I18nService._internal();

  Map<String, dynamic> _currentLocale = {};
  AppLocale _locale = AppLocale.zhCN;

  AppLocale get currentLocale => _locale;
  String get localeCode => _locale.languageCode;

  /// 初始化，加载默认语言
  Future<void> init() async {
    // TODO: 从持久化存储读取用户上次选择的语言
    await loadLocale(AppLocale.zhCN);
  }

  /// 加载指定语言
  Future<void> loadLocale(AppLocale locale) async {
    _locale = locale;
    final filePath = 'lib/i18n/locales/${locale.name}.json';
    try {
      final jsonStr = await rootBundle.loadString(filePath);
      _currentLocale = jsonDecode(jsonStr);
    } catch (e) {
      // 降级到英文
      final fallback = await rootBundle.loadString('lib/i18n/locales/en.json');
      _currentLocale = jsonDecode(fallback);
    }
  }

  /// 获取翻译文本
  String t(String key) {
    return _currentLocale[key]?.toString() ?? key;
  }
}

/// 便捷函数，在 Widget 中使用
String t(String key) => I18nService().t(key);
