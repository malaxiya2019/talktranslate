import 'dart:convert';
import 'package:http/http.dart' as http;

/// 翻译服务
class TranslationService {
  static const String _deepseekUrl = 'https://api.deepseek.com/v1/chat/completions';
  String? _apiKey;

  void setApiKey(String key) => _apiKey = key;

  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    if (text.isEmpty) return '';

    // 用 LLM
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      try {
        return await _llmTranslate(text, from, to);
      } catch (_) {}
    }

    // 降级: 返回标记
    return '[${_langName(to)}] $text';
  }

  Future<String> _llmTranslate(String text, String from, String to) async {
    final fromName = _langName(from);
    final toName = _langName(to);

    final resp = await http.post(
      Uri.parse(_deepseekUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'system', 'content': 'Translate $fromName to $toName. Output ONLY translation.'},
          {'role': 'user', 'content': text},
        ],
        'temperature': 0.1,
        'max_tokens': 256,
      }),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['choices'][0]['message']['content'].toString().trim();
    }
    throw Exception('HTTP ${resp.statusCode}');
  }

  String _langName(String code) {
    final map = {
      'zh-CN': 'Chinese', 'zh-TW': 'Traditional Chinese',
      'ja-JP': 'Japanese', 'ko-KR': 'Korean',
      'en-US': 'English', 'en-GB': 'English', 'en-AU': 'English', 'en-CA': 'English', 'en-IN': 'English',
      'es-ES': 'Spanish', 'es-MX': 'Spanish',
      'fr-FR': 'French', 'fr-CA': 'French',
      'de-DE': 'German', 'pt-BR': 'Portuguese', 'pt-PT': 'Portuguese',
      'it-IT': 'Italian', 'ru-RU': 'Russian', 'nl-NL': 'Dutch',
      'sv-SE': 'Swedish', 'nb-NO': 'Norwegian', 'da-DK': 'Danish',
      'fi-FI': 'Finnish', 'pl-PL': 'Polish', 'cs-CZ': 'Czech',
      'sk-SK': 'Slovak', 'hu-HU': 'Hungarian', 'ro-RO': 'Romanian',
      'el-GR': 'Greek', 'uk-UA': 'Ukrainian',
      'ar-SA': 'Arabic', 'he-IL': 'Hebrew', 'tr-TR': 'Turkish',
      'hi-IN': 'Hindi', 'th-TH': 'Thai', 'vi-VN': 'Vietnamese',
      'id-ID': 'Indonesian', 'ms-MY': 'Malay',
      'ca-ES': 'Catalan', 'hr-HR': 'Croatian', 'sr-RS': 'Serbian',
      'bg-BG': 'Bulgarian', 'lt-LT': 'Lithuanian', 'lv-LV': 'Latvian',
      'et-EE': 'Estonian', 'sl-SI': 'Slovenian',
    };
    return map[code] ?? 'English';
  }
}
