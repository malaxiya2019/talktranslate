/// 语言模型
class Language {
  final String code;       // STT locale code
  final String name;       // English name
  final String nativeName; // Native name
  final String flag;       // Flag emoji

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  static const List<Language> supported = [
    // ── 东亚 ──
    Language(code: 'zh-CN', name: 'Chinese (Simplified)', nativeName: '中文（简体）', flag: '🇨🇳'),
    Language(code: 'zh-TW', name: 'Chinese (Traditional)', nativeName: '中文（繁體）', flag: '🇹🇼'),
    Language(code: 'ja-JP', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    Language(code: 'ko-KR', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),

    // ── 英语区域 ──
    Language(code: 'en-US', name: 'English (US)', nativeName: 'English (US)', flag: '🇺🇸'),
    Language(code: 'en-GB', name: 'English (UK)', nativeName: 'English (UK)', flag: '🇬🇧'),
    Language(code: 'en-AU', name: 'English (Australia)', nativeName: 'English (AU)', flag: '🇦🇺'),
    Language(code: 'en-CA', name: 'English (Canada)', nativeName: 'English (CA)', flag: '🇨🇦'),
    Language(code: 'en-IN', name: 'English (India)', nativeName: 'English (IN)', flag: '🇮🇳'),

    // ── 欧洲 ──
    Language(code: 'es-ES', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    Language(code: 'es-MX', name: 'Spanish (Mexico)', nativeName: 'Español (MX)', flag: '🇲🇽'),
    Language(code: 'fr-FR', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    Language(code: 'fr-CA', name: 'French (Canada)', nativeName: 'Français (CA)', flag: '🇨🇦'),
    Language(code: 'de-DE', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    Language(code: 'pt-BR', name: 'Portuguese (Brazil)', nativeName: 'Português (BR)', flag: '🇧🇷'),
    Language(code: 'pt-PT', name: 'Portuguese (Portugal)', nativeName: 'Português (PT)', flag: '🇵🇹'),
    Language(code: 'it-IT', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    Language(code: 'ru-RU', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    Language(code: 'nl-NL', name: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
    Language(code: 'sv-SE', name: 'Swedish', nativeName: 'Svenska', flag: '🇸🇪'),
    Language(code: 'nb-NO', name: 'Norwegian', nativeName: 'Norsk', flag: '🇳🇴'),
    Language(code: 'da-DK', name: 'Danish', nativeName: 'Dansk', flag: '🇩🇰'),
    Language(code: 'fi-FI', name: 'Finnish', nativeName: 'Suomi', flag: '🇫🇮'),
    Language(code: 'pl-PL', name: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
    Language(code: 'cs-CZ', name: 'Czech', nativeName: 'Čeština', flag: '🇨🇿'),
    Language(code: 'sk-SK', name: 'Slovak', nativeName: 'Slovenčina', flag: '🇸🇰'),
    Language(code: 'hu-HU', name: 'Hungarian', nativeName: 'Magyar', flag: '🇭🇺'),
    Language(code: 'ro-RO', name: 'Romanian', nativeName: 'Română', flag: '🇷🇴'),
    Language(code: 'el-GR', name: 'Greek', nativeName: 'Ελληνικά', flag: '🇬🇷'),
    Language(code: 'uk-UA', name: 'Ukrainian', nativeName: 'Українська', flag: '🇺🇦'),

    // ── 中东 / 南亚 ──
    Language(code: 'ar-SA', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    Language(code: 'he-IL', name: 'Hebrew', nativeName: 'עברית', flag: '🇮🇱'),
    Language(code: 'tr-TR', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
    Language(code: 'hi-IN', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    Language(code: 'th-TH', name: 'Thai', nativeName: 'ไทย', flag: '🇹🇭'),
    Language(code: 'vi-VN', name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
    Language(code: 'id-ID', name: 'Indonesian', nativeName: 'Bahasa Indonesia', flag: '🇮🇩'),
    Language(code: 'ms-MY', name: 'Malay', nativeName: 'Bahasa Melayu', flag: '🇲🇾'),

    // ── 其他 ──
    Language(code: 'ca-ES', name: 'Catalan', nativeName: 'Català', flag: '🇪🇸'),
    Language(code: 'hr-HR', name: 'Croatian', nativeName: 'Hrvatski', flag: '🇭🇷'),
    Language(code: 'sr-RS', name: 'Serbian', nativeName: 'Српски', flag: '🇷🇸'),
    Language(code: 'bg-BG', name: 'Bulgarian', nativeName: 'Български', flag: '🇧🇬'),
    Language(code: 'lt-LT', name: 'Lithuanian', nativeName: 'Lietuvių', flag: '🇱🇹'),
    Language(code: 'lv-LV', name: 'Latvian', nativeName: 'Latviešu', flag: '🇱🇻'),
    Language(code: 'et-EE', name: 'Estonian', nativeName: 'Eesti', flag: '🇪🇪'),
    Language(code: 'sl-SI', name: 'Slovenian', nativeName: 'Slovenščina', flag: '🇸🇮'),
  ];

  /// 按区域分组
  static Map<String, List<Language>> get grouped {
    return {
      '东亚': supported.where((l) => ['zh-CN','zh-TW','ja-JP','ko-KR'].contains(l.code)).toList(),
      '英语': supported.where((l) => l.code.startsWith('en')).toList(),
      '欧洲': supported.where((l) => ['es-ES','es-MX','fr-FR','fr-CA','de-DE','pt-BR','pt-PT','it-IT','ru-RU','nl-NL','sv-SE','nb-NO','da-DK','fi-FI','pl-PL','cs-CZ','sk-SK','hu-HU','ro-RO','el-GR','uk-UA'].contains(l.code)).toList(),
      '中东/南亚': supported.where((l) => ['ar-SA','he-IL','tr-TR','hi-IN','th-TH','vi-VN','id-ID','ms-MY'].contains(l.code)).toList(),
      '其他': supported.where((l) => ['ca-ES','hr-HR','sr-RS','bg-BG','lt-LT','lv-LV','et-EE','sl-SI'].contains(l.code)).toList(),
    };
  }
}
