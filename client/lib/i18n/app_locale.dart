/// 支持的语种列表（按需求优先级排序）
enum AppLocale {
  en('English', 'English'),
  zhCN('中文简体', 'Chinese Simplified'),
  zhTW('中文繁體', 'Chinese Traditional'),
  hi('हिन्दी', 'Hindi'),
  ja('日本語', 'Japanese'),
  ko('한국어', 'Korean'),
  vi('Tiếng Việt', 'Vietnamese'),
  fil('Filipino', 'Filipino'),
  ms('Bahasa Melayu', 'Malay'),
  ar('العربية', 'Arabic'),
  fr('Français', 'French'),
  de('Deutsch', 'German'),
  es('Español', 'Spanish'),
  it('Italiano', 'Italian'),
  ru('Русский', 'Russian');

  final String nativeName;
  final String englishName;
  const AppLocale(this.nativeName, this.englishName);

  String get languageCode {
    switch (this) {
      case AppLocale.zhCN:
        return 'zh';
      case AppLocale.zhTW:
        return 'zh';
      case AppLocale.fil:
        return 'fil';
      case AppLocale.ms:
        return 'ms';
      default:
        return name;
    }
  }

  String? get countryCode {
    switch (this) {
      case AppLocale.zhCN:
        return 'CN';
      case AppLocale.zhTW:
        return 'TW';
      case AppLocale.en:
        return 'US';
      case AppLocale.fil:
        return 'PH';
      case AppLocale.ms:
        return 'MY';
      default:
        return null;
    }
  }

  static AppLocale fromString(String code) {
    return AppLocale.values.firstWhere(
      (l) => l.name == code || l.languageCode == code,
      orElse: () => AppLocale.en,
    );
  }
}
