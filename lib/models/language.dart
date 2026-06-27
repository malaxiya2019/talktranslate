/// 语言代码映射工具
class LanguageUtil {
  LanguageUtil._();

  /// 国际化标准语言代码 → 英文名称（用于 LLM 翻译提示）
  static String langName(String code) {
    const map = {
      'zh-CN': 'Chinese',
      'en-US': 'English',
      'ja-JP': 'Japanese',
      'ko-KR': 'Korean',
      'es-ES': 'Spanish',
      'fr-FR': 'French',
      'de-DE': 'German',
      'pt-BR': 'Portuguese',
      'ru-RU': 'Russian',
      'ar-SA': 'Arabic',
      'th-TH': 'Thai',
      'vi-VN': 'Vietnamese',
    };
    return map[code] ?? 'English';
  }

  /// 语音识别区域标识
  static String sttLocale(String code) {
    const map = {
      'zh-CN': 'zh_CN',
      'en-US': 'en_US',
      'ja-JP': 'ja_JP',
      'ko-KR': 'ko_KR',
      'es-ES': 'es_ES',
      'fr-FR': 'fr_FR',
      'de-DE': 'de_DE',
      'pt-BR': 'pt_BR',
      'ru-RU': 'ru_RU',
      'ar-SA': 'ar_SA',
      'th-TH': 'th_TH',
      'vi-VN': 'vi_VN',
    };
    return map[code] ?? 'en_US';
  }

  /// TTS 语音标识
  static String ttsLocale(String code) {
    const map = {
      'zh-CN': 'zh-CN',
      'en-US': 'en-US',
      'ja-JP': 'ja-JP',
      'ko-KR': 'ko-KR',
      'es-ES': 'es-ES',
      'fr-FR': 'fr-FR',
      'de-DE': 'de-DE',
      'pt-BR': 'pt-BR',
      'ru-RU': 'ru-RU',
    };
    return map[code] ?? 'en-US';
  }
}
