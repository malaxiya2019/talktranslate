import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 可用的翻译引擎
enum TranslationEngine {
  /// 系统内置引擎（预留，当前未实现，返回错误提示）
  system,
  deepseek,
  openai,
  claude,
  deepl,
  baidu,
}

/// 翻译引擎配置服务 — 加密存储 + 连接测试
///
/// API Key 通过 FlutterSecureStorage 硬件级加密存储，
/// 不写入 SharedPreferences。
class EngineConfigService {
  final _secureStorage = const FlutterSecureStorage();

  static final EngineConfigService _instance = EngineConfigService._();
  factory EngineConfigService() => _instance;
  EngineConfigService._();

  // ── Key 管理 ──

  Future<void> saveApiKey(TranslationEngine engine, String key) async {
    try {
      await _secureStorage.write(key: 'API_KEY_${engine.name}', value: key);
    } catch (_) {}
  }

  Future<String?> getApiKey(TranslationEngine engine) async {
    try {
      return await _secureStorage.read(key: 'API_KEY_${engine.name}');
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteApiKey(TranslationEngine engine) async {
    try {
      await _secureStorage.delete(key: 'API_KEY_${engine.name}');
    } catch (_) {}
  }

  Future<void> saveBaseUrl(TranslationEngine engine, String url) async {
    try {
      await _secureStorage.write(key: 'BASE_URL_${engine.name}', value: url);
    } catch (_) {}
  }

  Future<String?> getBaseUrl(TranslationEngine engine) async {
    try {
      return await _secureStorage.read(key: 'BASE_URL_${engine.name}');
    } catch (_) {
      return null;
    }
  }

  // ── 模型名管理 ──

  Future<void> saveModelName(TranslationEngine engine, String model) async {
    try {
      await _secureStorage.write(key: 'MODEL_${engine.name}', value: model);
    } catch (_) {}
  }

  Future<String?> getModelName(TranslationEngine engine) async {
    try {
      return await _secureStorage.read(key: 'MODEL_${engine.name}');
    } catch (_) {
      return null;
    }
  }

  /// 默认模型名（当用户未自定义时使用）
  String defaultModelName(TranslationEngine engine) {
    switch (engine) {
      case TranslationEngine.deepseek:
        return 'deepseek-chat';
      case TranslationEngine.openai:
        return 'gpt-4o-mini';
      case TranslationEngine.claude:
        return 'claude-3-haiku-20240307';
      case TranslationEngine.deepl:
        return ''; // DeepL 无模型概念
      case TranslationEngine.baidu:
        return ''; // 百度翻译无模型概念
      case TranslationEngine.system:
        return '';
    }
  }

  // ── 引擎终结点 ──

  String defaultEndpoint(TranslationEngine engine) {
    switch (engine) {
      case TranslationEngine.deepseek:
        return 'https://api.deepseek.com/v1';
      case TranslationEngine.openai:
        return 'https://api.openai.com/v1';
      case TranslationEngine.claude:
        return 'https://api.anthropic.com/v1';
      case TranslationEngine.deepl:
        return 'https://api-free.deepl.com/v2';
      case TranslationEngine.baidu:
        return 'https://api.fanyi.baidu.com/api';
      case TranslationEngine.system:
        return '';
    }
  }

  // ── DeepSeek 连接测试 ──

  Future<bool> testDeepSeekConnection({
    required String apiKey,
    String? baseUrl,
  }) async {
    final endpoint = baseUrl?.isNotEmpty == true
        ? baseUrl!
        : defaultEndpoint(TranslationEngine.deepseek);

    try {
      final response = await http.post(
        Uri.parse('$endpoint/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': 'ping'},
          ],
          'max_tokens': 1,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── 通用连接测试（自动适配引擎） ──

  Future<({bool ok, String? message})> testConnection(
    TranslationEngine engine, {
    required String apiKey,
    String? baseUrl,
  }) async {
    final endpoint = baseUrl?.isNotEmpty == true
        ? baseUrl!
        : defaultEndpoint(engine);

    if (endpoint.isEmpty) {
      return (ok: false, message: '系统内置引擎无需配置');
    }

    try {
      final uri = Uri.parse('$endpoint/chat/completions');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelName(engine),
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'max_tokens': 5,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return (ok: true, message: null);
      } else {
        final body = jsonDecode(response.body);
        final err = body['error']?['message'] ?? 'HTTP ${response.statusCode}';
        return (ok: false, message: '$err');
      }
    } catch (e) {
      return (ok: false, message: '$e');
    }
  }

  String _modelName(TranslationEngine engine) {
    switch (engine) {
      case TranslationEngine.deepseek:
        return 'deepseek-chat';
      case TranslationEngine.openai:
        return 'gpt-3.5-turbo';
      case TranslationEngine.claude:
        return 'claude-3-haiku-20240307';
      default:
        return 'deepseek-chat';
    }
  }

  // ── 目标语言管理 ──

  String _targetLanguage = 'en-US';

  String get targetLanguage => _targetLanguage;

  /// 设置翻译引擎的目标语言（对方听到的语言）
  void setTargetLanguage(String lang) {
    _targetLanguage = lang;
  }
}
