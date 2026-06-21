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
      'zh-CN': 'Chinese', 'en-US': 'English', 'ja-JP': 'Japanese',
      'ko-KR': 'Korean', 'es-ES': 'Spanish', 'fr-FR': 'French',
      'de-DE': 'German', 'pt-BR': 'Portuguese', 'ar-SA': 'Arabic',
      'th-TH': 'Thai', 'vi-VN': 'Vietnamese', 'ru-RU': 'Russian',
    };
    return map[code] ?? 'English';
  }
}
