import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 翻译引擎配置
class _EngineOption {
  final String id;
  final String label;
  final String icon;
  final bool customEndpoint;
  const _EngineOption(this.id, this.label, this.icon, {this.customEndpoint = false});

  static const list = [
    _EngineOption('builtin', '系统内置', '🧠'),
    _EngineOption('openai', 'OpenAI (GPT)', '🤖', customEndpoint: true),
    _EngineOption('anthropic', 'Anthropic (Claude)', '🟣', customEndpoint: true),
    _EngineOption('deepl', 'DeepL', '💡', customEndpoint: true),
    _EngineOption('baidu', '百度翻译', '🇨🇳', customEndpoint: true),
  ];
}

/// 翻译引擎与自定义模型配置页
class EngineConfigScreen extends StatefulWidget {
  const EngineConfigScreen({super.key});
  @override
  State<EngineConfigScreen> createState() => _EngineConfigScreenState();
}

class _EngineConfigScreenState extends State<EngineConfigScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final _apiKeyCtl = TextEditingController();
  final _baseUrlCtl = TextEditingController();

  String _selectedEngine = 'builtin';
  bool _obscureKey = true;
  bool _testing = false;
  String? _testResult; // null=idle, 'ok'=success, 'error:msg'=failure

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _selectedEngine = await _secureStorage.read(key: 'translation_engine') ?? 'builtin';
    final apiKey = await _secureStorage.read(key: 'translation_api_key') ?? '';
    final baseUrl = await _secureStorage.read(key: 'translation_base_url') ?? '';
    _apiKeyCtl.text = apiKey;
    _baseUrlCtl.text = baseUrl;
    setState(() {});
  }

  Future<void> _saveConfig() async {
    await _secureStorage.write(key: 'translation_engine', value: _selectedEngine);
    await _secureStorage.write(key: 'translation_api_key', value: _apiKeyCtl.text.trim());
    await _secureStorage.write(key: 'translation_base_url', value: _baseUrlCtl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('配置已保存（加密存储）'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final url = _baseUrlCtl.text.trim().isNotEmpty
          ? _baseUrlCtl.text.trim()
          : _defaultEndpoint(_selectedEngine);

      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_apiKeyCtl.text.trim()}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'max_tokens': 5,
        }),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        setState(() => _testResult = 'ok');
      } else {
        setState(() => _testResult = 'error:HTTP ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _testResult = 'error:$e');
    } finally {
      setState(() => _testing = false);
    }
  }

  String _defaultEndpoint(String engineId) {
    switch (engineId) {
      case 'openai': return 'https://api.openai.com/v1/chat/completions';
      case 'anthropic': return 'https://api.anthropic.com/v1/messages';
      case 'deepl': return 'https://api-free.deepl.com/v2/translate';
      case 'baidu': return 'https://api.fanyi.baidu.com/api/trans/vip/translate';
      default: return '';
    }
  }

  @override
  void dispose() {
    _apiKeyCtl.dispose();
    _baseUrlCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('翻译引擎配置'),
        actions: [
          TextButton.icon(
            onPressed: _saveConfig,
            icon: const Icon(Icons.save),
            label: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 引擎选择 ──
          Text('选择翻译引擎', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedEngine,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _EngineOption.list.map((e) => DropdownMenuItem(
              value: e.id,
              child: Text('${e.icon}  ${e.label}'),
            )).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedEngine = v);
            },
          ),
          const SizedBox(height: 24),

          // ── API Key ──
          Text('API Key', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyCtl,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              hintText: 'sk-...',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '使用 Flutter Secure Storage 加密存储',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),

          // ── Base URL ──
          Text('API Endpoint (可选)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlCtl,
            decoration: InputDecoration(
              hintText: _defaultEndpoint(_selectedEngine),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          // ── 测试连接 ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(_testing ? '测试中...' : '测试连接'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── 测试结果 ──
          if (_testResult == 'ok')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('✓ 连接成功', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          if (_testResult != null && _testResult!.startsWith('error'))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✗ 校验失败: ${_testResult!.replaceFirst('error:', '')}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
