/// 语言模型
class Language {
  final String code;       // "zh-CN", "en-US", "ja-JP", ...
  final String name;       // "中文", "English", "日本語"
  final String nativeName; // "中文", "English", "日本語"
  final String flag;       // 🇨🇳 🇺🇸 🇯🇵

  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  static const List<Language> supported = [
    Language(code: 'zh-CN', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    Language(code: 'en-US', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    Language(code: 'ja-JP', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    Language(code: 'ko-KR', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    Language(code: 'es-ES', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    Language(code: 'fr-FR', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    Language(code: 'de-DE', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    Language(code: 'pt-BR', name: 'Portuguese', nativeName: 'Português', flag: '🇧🇷'),
    Language(code: 'ar-SA', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    Language(code: 'th-TH', name: 'Thai', nativeName: 'ไทย', flag: '🇹🇭'),
    Language(code: 'vi-VN', name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
    Language(code: 'ru-RU', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
  ];
}
