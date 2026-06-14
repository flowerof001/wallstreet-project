import 'package:flutter/material.dart';
import '../i18n/app_locale.dart';
import '../i18n/i18n_service.dart';

/// 语言/国别切换 Provider
class LocaleProvider extends ChangeNotifier {
  AppLocale _locale = AppLocale.zhCN;

  AppLocale get locale => _locale;

  void setLocale(AppLocale locale) {
    _locale = locale;
    I18nService().loadLocale(locale);
    notifyListeners();
  }

  void setLocaleByCountry(String countryCode) {
    final locale = AppLocale.values.firstWhere(
      (l) => l.countryCode == countryCode,
      orElse: () => AppLocale.en,
    );
    setLocale(locale);
  }
}
