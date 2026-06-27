/// 本地短语词典 — 离线翻译常用短句的兜底方案
///
/// 当 MLKit 模型未下载/网络不可用时，
/// 用此词典提供最基本的常用问候和对话短语翻译。
class PhraseDictionary {
  PhraseDictionary._();

  /// 核心短语集 (简体中文 → 多语言)
  /// 每个条目: 中文原文 → { 目标语言代码: 译文 }
  static const Map<String, Map<String, String>> _phrases = {
    '你好': {
      'en-US': 'Hello',
      'ja-JP': 'こんにちは',
      'ko-KR': '안녕하세요',
      'es-ES': 'Hola',
      'fr-FR': 'Bonjour',
      'de-DE': 'Hallo',
      'pt-BR': 'Olá',
      'ru-RU': 'Здравствуйте',
      'ar-SA': 'مرحبا',
      'th-TH': 'สวัสดี',
      'vi-VN': 'Xin chào',
    },
    '谢谢': {
      'en-US': 'Thank you',
      'ja-JP': 'ありがとう',
      'ko-KR': '감사합니다',
      'es-ES': 'Gracias',
      'fr-FR': 'Merci',
      'de-DE': 'Danke',
      'pt-BR': 'Obrigado',
      'ru-RU': 'Спасибо',
      'ar-SA': 'شكرا',
      'th-TH': 'ขอบคุณ',
      'vi-VN': 'Cảm ơn',
    },
    '再见': {
      'en-US': 'Goodbye',
      'ja-JP': 'さようなら',
      'ko-KR': '안녕히 계세요',
      'es-ES': 'Adiós',
      'fr-FR': 'Au revoir',
      'de-DE': 'Auf Wiedersehen',
      'pt-BR': 'Tchau',
      'ru-RU': 'До свидания',
      'ar-SA': 'مع السلامة',
      'th-TH': 'ลาก่อน',
      'vi-VN': 'Tạm biệt',
    },
    '是的': {
      'en-US': 'Yes',
      'ja-JP': 'はい',
      'ko-KR': '네',
      'es-ES': 'Sí',
      'fr-FR': 'Oui',
      'de-DE': 'Ja',
      'pt-BR': 'Sim',
      'ru-RU': 'Да',
      'ar-SA': 'نعم',
      'th-TH': 'ใช่',
      'vi-VN': 'Vâng',
    },
    '不是': {
      'en-US': 'No',
      'ja-JP': 'いいえ',
      'ko-KR': '아니요',
      'es-ES': 'No',
      'fr-FR': 'Non',
      'de-DE': 'Nein',
      'pt-BR': 'Não',
      'ru-RU': 'Нет',
      'ar-SA': 'لا',
      'th-TH': 'ไม่',
      'vi-VN': 'Không',
    },
    '对不起': {
      'en-US': 'Sorry',
      'ja-JP': 'すみません',
      'ko-KR': '죄송합니다',
      'es-ES': 'Lo siento',
      'fr-FR': 'Désolé',
      'de-DE': 'Entschuldigung',
      'pt-BR': 'Desculpe',
      'ru-RU': 'Извините',
      'ar-SA': 'آسف',
      'th-TH': 'ขอโทษ',
      'vi-VN': 'Xin lỗi',
    },
    '请帮我': {
      'en-US': 'Please help me',
      'ja-JP': '助けてください',
      'ko-KR': '도와주세요',
      'es-ES': 'Ayúdeme por favor',
      'fr-FR': 'Aidez-moi s\'il vous plaît',
      'de-DE': 'Bitte helfen Sie mir',
      'pt-BR': 'Ajude-me por favor',
      'ru-RU': 'Помогите мне, пожалуйста',
      'ar-SA': 'ساعدني من فضلك',
      'th-TH': 'ช่วยฉันหน่อย',
      'vi-VN': 'Vui lòng giúp tôi',
    },
    '多少钱': {
      'en-US': 'How much',
      'ja-JP': 'いくらですか',
      'ko-KR': '얼마예요',
      'es-ES': '¿Cuánto cuesta',
      'fr-FR': 'Combien ça coûte',
      'de-DE': 'Wie viel kostet das',
      'pt-BR': 'Quanto custa',
      'ru-RU': 'Сколько стоит',
      'ar-SA': 'كم السعر',
      'th-TH': 'เท่าไหร่',
      'vi-VN': 'Bao nhiêu tiền',
    },
    '我不明白': {
      'en-US': 'I don\'t understand',
      'ja-JP': 'わかりません',
      'ko-KR': '이해하지 못했습니다',
      'es-ES': 'No entiendo',
      'fr-FR': 'Je ne comprends pas',
      'de-DE': 'Ich verstehe nicht',
      'pt-BR': 'Não entendo',
      'ru-RU': 'Я не понимаю',
      'ar-SA': 'لا أفهم',
      'th-TH': 'ฉันไม่เข้าใจ',
      'vi-VN': 'Tôi không hiểu',
    },
    '请慢点说': {
      'en-US': 'Please speak slowly',
      'ja-JP': 'ゆっくり話してください',
      'ko-KR': '천천히 말씀해 주세요',
      'es-ES': 'Hable más despacio por favor',
      'fr-FR': 'Parlez lentement s\'il vous plaît',
      'de-DE': 'Bitte sprechen Sie langsamer',
      'pt-BR': 'Fale mais devagar por favor',
      'ru-RU': 'Говорите медленнее, пожалуйста',
      'ar-SA': 'تحدث ببطء من فضلك',
      'th-TH': 'กรุณาพูดช้าๆ',
      'vi-VN': 'Vui lòng nói chậm hơn',
    },
  };

  /// 查找短语翻译
  /// 返回精确匹配的译文，或 null
  static String? lookup(String text, String targetLang) {
    // 精确匹配
    final match = _phrases[text];
    if (match != null) return match[targetLang];

    // 尝试包含匹配
    for (final entry in _phrases.entries) {
      if (text.contains(entry.key)) {
        final translation = entry.value[targetLang];
        if (translation != null) {
          // 替换原文中的匹配部分
          return text.replaceFirst(entry.key, translation);
        }
      }
    }

    return null;
  }

  /// 支持的短语数量
  static int get phraseCount => _phrases.length;

  /// 判断是否有足够置信度的匹配
  static bool hasMatch(String text, String targetLang) {
    if (text.isEmpty) return false;
    return _phrases.containsKey(text) || _phrases.keys.any((k) => text.contains(k));
  }
}
