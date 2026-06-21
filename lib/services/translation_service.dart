import 'dart:convert';
import 'package:http/http.dart' as http;

/// 翻译服务 — 支持多种引擎
class TranslationService {
  static const String _deepseekUrl = 'https://api.deepseek.com/v1/chat/completions';

  String? _apiKey;

  void setApiKey(String key) => _apiKey = key;

  /// 翻译文本
  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    if (text.isEmpty) return '';

    // 尝试 DeepSeek API
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      try {
        return await _translateWithLLM(text, from, to);
      } catch (_) {}
    }

    // 降级: 返回原文 (标记未翻译)
    return '[${_langCodeToName(to)}] $text';
  }

  /// 用 LLM 翻译 (质量高、支持上下文)
  Future<String> _translateWithLLM(String text, String from, String to) async {
    final fromName = _langCodeToName(from);
    final toName = _langCodeToName(to);

    final resp = await http.post(
      Uri.parse(_deepseekUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a real-time interpreter. Translate the following $fromName to $toName. '
                'Output ONLY the translation, no explanation, no quotes.',
          },
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
    throw Exception('Translation API error: ${resp.statusCode}');
  }

  String _langCodeToName(String code) {
    final map = {
      'zh-CN': 'Chinese',
      'en-US': 'English',
      'ja-JP': 'Japanese',
      'ko-KR': 'Korean',
      'es-ES': 'Spanish',
      'fr-FR': 'French',
      'de-DE': 'German',
      'pt-BR': 'Portuguese',
      'ar-SA': 'Arabic',
      'th-TH': 'Thai',
      'vi-VN': 'Vietnamese',
      'ru-RU': 'Russian',
    };
    return map[code] ?? 'English';
  }
}
