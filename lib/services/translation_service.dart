import 'dart:convert';
import 'package:http/http.dart' as http;

/// 翻译服务 — DeepSeek API
class TranslationService {
  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
  String _apiKey = '';

  void setApiKey(String key) => _apiKey = key;

  Future<String> translate(String text, String from, String to) async {
    if (text.isEmpty) return '';
    if (_apiKey.isEmpty) return '[未配置API Key] $text';

    try {
      final resp = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': 'Translate the following text from ${_lang(from)} to ${_lang(to)}. Output ONLY the translation.'},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.1,
          'max_tokens': 256,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data['choices'][0]['message']['content'] as String).trim();
      }
      return '[API ${resp.statusCode}] $text';
    } catch (e) {
      return '[翻译失败] $text';
    }
  }

  String _lang(String code) {
    const map = {
      'zh-CN': 'Chinese', 'en-US': 'English', 'ja-JP': 'Japanese',
      'ko-KR': 'Korean', 'es-ES': 'Spanish', 'fr-FR': 'French',
      'de-DE': 'German', 'pt-BR': 'Portuguese', 'ru-RU': 'Russian',
      'ar-SA': 'Arabic', 'th-TH': 'Thai', 'vi-VN': 'Vietnamese',
    };
    return map[code] ?? 'English';
  }
}
