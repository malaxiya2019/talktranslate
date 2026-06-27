import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/language.dart';
import 'engine_config_service.dart';

/// 单次翻译尝试的结果
class _EngineResult {
  final bool success;
  final String text;
  final String? engineName;
  final String? error;

  const _EngineResult({
    required this.success,
    required this.text,
    this.engineName,
    this.error,
  });
}

/// 翻译服务 — 多引擎自动回退 + 重试
///
/// 特性：
/// - 多引擎优先级配置（默认 DeepSeek → OpenAI → Claude → DeepL → 百度）
/// - 引擎级指数退避重试（max 3 次）
/// - 级联回退（当前引擎全部失败 → 下一引擎）
/// - 全链路超时保护
/// - 与 EngineConfigService 集成，自动获取各引擎 API Key
class TranslationService {
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _requestTimeout = Duration(seconds: 10);

  final EngineConfigService _config;

  /// 引擎优先级列表 — 按顺序依次尝试
  List<TranslationEngine> _enginePriority = [
    TranslationEngine.deepseek,
    TranslationEngine.openai,
    TranslationEngine.claude,
    TranslationEngine.deepl,
    TranslationEngine.baidu,
  ];

  TranslationService({EngineConfigService? config})
    : _config = config ?? EngineConfigService();

  // ── 配置 ──

  /// 设置引擎优先级（去重后按此顺序回退）
  void setEnginePriority(List<TranslationEngine> engines) {
    final seen = <TranslationEngine>{};
    _enginePriority = engines.where((e) => seen.add(e)).toList();
  }

  List<TranslationEngine> get enginePriority =>
      List.unmodifiable(_enginePriority);

  /// 兼容旧 API：设置 DeepSeek API Key
  void setApiKey(String key) {
    _config.saveApiKey(TranslationEngine.deepseek, key);
  }

  // ── 主翻译入口 ──

  /// 翻译文本（自动重试 + 级联回退）
  Future<String> translate(String text, String from, String to) async {
    if (text.isEmpty) return '';
    if (_enginePriority.isEmpty) return '[未配置翻译引擎] $text';

    // 尝试每个引擎，直到成功
    for (int ei = 0; ei < _enginePriority.length; ei++) {
      final engine = _enginePriority[ei];
      final apiKey = await _config.getApiKey(engine);

      // 跳过无 Key 的引擎（除非是系统内置）
      if ((apiKey == null || apiKey.isEmpty) && engine != TranslationEngine.system) {
        continue;
      }

      // 引擎级重试（指数退避）
      for (int retry = 0; retry < _maxRetries; retry++) {
        final result = await _callEngine(engine, text, from, to, apiKey);
        if (result.success) return result.text;

        if (retry < _maxRetries - 1) {
          // 指数退避：1s, 2s, 4s
          final delay = Duration(
            milliseconds: _baseDelay.inMilliseconds * (1 << retry),
          );
          await Future.delayed(delay);
        }
      }
    }

    // 所有引擎全部失败
    return '[翻译失败] $text';
  }

  // ── 引擎调用 ──

  Future<_EngineResult> _callEngine(
    TranslationEngine engine,
    String text,
    String from,
    String to,
    String? apiKey,
  ) async {
    try {
      switch (engine) {
        case TranslationEngine.deepseek:
          return await _callOpenAICompatible(
            baseUrl: await _config.getBaseUrl(engine) ??
                'https://api.deepseek.com/v1',
            model: 'deepseek-chat',
            apiKey: apiKey ?? '',
            text: text, from: from, to: to,
            engineName: 'DeepSeek',
          );
        case TranslationEngine.openai:
          return await _callOpenAICompatible(
            baseUrl: await _config.getBaseUrl(engine) ??
                'https://api.openai.com/v1',
            model: 'gpt-4o-mini',
            apiKey: apiKey ?? '',
            text: text, from: from, to: to,
            engineName: 'OpenAI',
          );
        case TranslationEngine.claude:
          return await _callClaude(
            baseUrl: await _config.getBaseUrl(engine) ??
                'https://api.anthropic.com/v1',
            apiKey: apiKey ?? '',
            text: text, from: from, to: to,
          );
        case TranslationEngine.deepl:
          return await _callDeepL(
            baseUrl: await _config.getBaseUrl(engine) ??
                'https://api-free.deepl.com/v2',
            apiKey: apiKey ?? '',
            text: text, from: from, to: to,
          );
        case TranslationEngine.baidu:
          return await _callBaidu(
            baseUrl: await _config.getBaseUrl(engine) ??
                'https://api.fanyi.baidu.com/api',
            apiKey: apiKey ?? '',
            text: text, from: from, to: to,
          );
        case TranslationEngine.system:
          return const _EngineResult(
            success: false,
            text: '',
            error: '系统内置引擎未实现',
          );
      }
    } on TimeoutException {
      return _EngineResult(
        success: false, text: '',
        engineName: engine.name,
        error: 'timeout',
      );
    } catch (e) {
      return _EngineResult(
        success: false, text: '',
        engineName: engine.name,
        error: '$e',
      );
    }
  }

  // ── OpenAI 兼容 API（DeepSeek / OpenAI / 任何 openai-compatible）──

  Future<_EngineResult> _callOpenAICompatible({
    required String baseUrl,
    required String model,
    required String apiKey,
    required String text,
    required String from,
    required String to,
    required String engineName,
  }) async {
    if (apiKey.isEmpty) {
      return _EngineResult(success: false, text: '', error: 'no api key');
    }

    final resp = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content':
                'Translate the following text from ${LanguageUtil.langName(from)} '
                'to ${LanguageUtil.langName(to)}. Output ONLY the translation.',
          },
          {'role': 'user', 'content': text},
        ],
        'temperature': 0.1,
        'max_tokens': 256,
      }),
    ).timeout(_requestTimeout);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final translated = (data['choices'][0]['message']['content'] as String).trim();
      return _EngineResult(
        success: true, text: translated,
        engineName: engineName,
      );
    }

    return _EngineResult(
      success: false, text: '',
      engineName: engineName,
      error: 'HTTP ${resp.statusCode}: ${resp.body}',
    );
  }

  // ── Anthropic Claude API ──

  Future<_EngineResult> _callClaude({
    required String baseUrl,
    required String apiKey,
    required String text,
    required String from,
    required String to,
  }) async {
    if (apiKey.isEmpty) {
      return _EngineResult(success: false, text: '', error: 'no api key');
    }

    // Claude Messages API
    final resp = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 256,
        'messages': [
          {
            'role': 'user',
            'content':
                'Translate the following text from ${LanguageUtil.langName(from)} '
                'to ${LanguageUtil.langName(to)}. Output ONLY the translation.\n\n$text',
          },
        ],
      }),
    ).timeout(_requestTimeout);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final content = data['content'] as List;
      if (content.isNotEmpty) {
        final translated = content[0]['text'] as String;
        return _EngineResult(
          success: true, text: translated.trim(),
          engineName: 'Claude',
        );
      }
    }

    return _EngineResult(
      success: false, text: '',
      engineName: 'Claude',
      error: 'HTTP ${resp.statusCode}: ${resp.body}',
    );
  }

  // ── DeepL API ──

  Future<_EngineResult> _callDeepL({
    required String baseUrl,
    required String apiKey,
    required String text,
    required String from,
    required String to,
  }) async {
    if (apiKey.isEmpty) {
      return _EngineResult(success: false, text: '', error: 'no api key');
    }

    final resp = await http.post(
      Uri.parse('$baseUrl/translate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'DeepL-Auth-Key $apiKey',
      },
      body: jsonEncode({
        'text': [text],
        'source_lang': _deeplLang(from),
        'target_lang': _deeplLang(to),
      }),
    ).timeout(_requestTimeout);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final translated = data['translations'][0]['text'] as String;
      return _EngineResult(
        success: true, text: translated.trim(),
        engineName: 'DeepL',
      );
    }

    return _EngineResult(
      success: false, text: '',
      engineName: 'DeepL',
      error: 'HTTP ${resp.statusCode}: ${resp.body}',
    );
  }

  // ── 百度翻译 API ──

  Future<_EngineResult> _callBaidu({
    required String baseUrl,
    required String apiKey,
    required String text,
    required String from,
    required String to,
  }) async {
    // 百度翻译使用 appid + secretKey（apiKey 格式: "appid:secretKey"）
    final parts = apiKey.split(':');
    if (parts.length != 2) {
      return _EngineResult(
        success: false, text: '',
        engineName: 'Baidu',
        error: '百度翻译需要 APP ID:Secret Key 格式',
      );
    }

    final appid = parts[0].trim();
    final secretKey = parts[1].trim();
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final signSrc = '$appid$text$salt$secretKey';
    final sign = _md5(signSrc);

    final resp = await http.post(
      Uri.parse('$baseUrl/trans/vip/translate'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'q': text,
        'from': _baiduLang(from),
        'to': _baiduLang(to),
        'appid': appid,
        'salt': salt,
        'sign': sign,
      },
    ).timeout(_requestTimeout);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data.containsKey('trans_result')) {
        final results = data['trans_result'] as List;
        if (results.isNotEmpty) {
          final translated = results[0]['dst'] as String;
          return _EngineResult(
            success: true, text: translated.trim(),
            engineName: 'Baidu',
          );
        }
      }
      // 错误响应
      return _EngineResult(
        success: false, text: '',
        engineName: 'Baidu',
        error: '${data['error_code']}: ${data['error_msg']}',
      );
    }

    return _EngineResult(
      success: false, text: '',
      engineName: 'Baidu',
      error: 'HTTP ${resp.statusCode}',
    );
  }

  // ── 语言映射辅助 ──

  String _deeplLang(String code) {
    // DeepL 使用 ISO 639-1（部分语言不同）
    const map = {
      'zh-CN': 'ZH',
      'en-US': 'EN-US',
      'ja-JP': 'JA',
      'de-DE': 'DE',
      'fr-FR': 'FR',
      'es-ES': 'ES',
      'pt-BR': 'PT-BR',
      'ru-RU': 'RU',
      'ar-SA': 'AR',
    };
    return map[code] ?? 'EN';
  }

  String _baiduLang(String code) {
    const map = {
      'zh-CN': 'zh',
      'en-US': 'en',
      'ja-JP': 'jp',
      'ko-KR': 'kor',
      'es-ES': 'spa',
      'fr-FR': 'fra',
      'de-DE': 'de',
      'pt-BR': 'pt',
      'ru-RU': 'ru',
      'ar-SA': 'ara',
      'th-TH': 'th',
      'vi-VN': 'vie',
    };
    return map[code] ?? 'en';
  }

  /// MD5 签名
  String _md5(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}
