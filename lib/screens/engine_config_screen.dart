import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/engine_config_service.dart';

/// 翻译引擎与自定义模型配置页
class EngineConfigScreen extends StatefulWidget {
  const EngineConfigScreen({super.key});
  @override
  State<EngineConfigScreen> createState() => _EngineConfigScreenState();
}

class _EngineConfigScreenState extends State<EngineConfigScreen> {
  final _service = EngineConfigService();
  final _apiKeyCtl = TextEditingController();
  final _baseUrlCtl = TextEditingController();

  TranslationEngine _selectedEngine = TranslationEngine.system;
  bool _obscureKey = true;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    // 从 encrypted storage 读取已有配置
    final apiKey = await _service.getApiKey(_selectedEngine) ?? '';
    final baseUrl = await _service.getBaseUrl(_selectedEngine) ?? '';
    _apiKeyCtl.text = apiKey;
    _baseUrlCtl.text = baseUrl;
    setState(() {});
  }

  Future<void> _onEngineChanged(TranslationEngine? engine) async {
    if (engine == null || engine == _selectedEngine) return;
    // 保存当前引擎的配置
    await _service.saveApiKey(_selectedEngine, _apiKeyCtl.text.trim());
    await _service.saveBaseUrl(_selectedEngine, _baseUrlCtl.text.trim());
    // 切换到新引擎
    setState(() => _selectedEngine = engine);
    // 加载新引擎的配置
    final apiKey = await _service.getApiKey(engine) ?? '';
    final baseUrl = await _service.getBaseUrl(engine) ?? '';
    _apiKeyCtl.text = apiKey;
    _baseUrlCtl.text = baseUrl;
    setState(() {});
  }

  Future<void> _saveConfig() async {
    await _service.saveApiKey(_selectedEngine, _apiKeyCtl.text.trim());
    await _service.saveBaseUrl(_selectedEngine, _baseUrlCtl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('配置已保存（硬件加密存储）'),
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
    final result = await _service.testConnection(
      _selectedEngine,
      apiKey: _apiKeyCtl.text.trim(),
      baseUrl: _baseUrlCtl.text.trim().isNotEmpty ? _baseUrlCtl.text.trim() : null,
    );
    setState(() {
      _testing = false;
      _testResult = result.ok ? 'ok' : 'error:${result.message ?? "未知错误"}';
    });
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
          Text('选择翻译引擎', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<TranslationEngine>(
            value: _selectedEngine,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: TranslationEngine.values.map((e) => DropdownMenuItem(
              value: e,
              child: Text('${_engineIcon(e)}  ${_engineLabel(e)}'),
            )).toList(),
            onChanged: (v) => _onEngineChanged(v),
          ),
          const SizedBox(height: 24),

          Text('API Key', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyCtl,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              hintText: _hintForKey(_selectedEngine),
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
            '使用 Flutter Secure Storage 硬件加密存储',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),

          Text('API Endpoint (可选)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _baseUrlCtl,
            decoration: InputDecoration(
              hintText: _service.defaultEndpoint(_selectedEngine),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

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
                      '✗ ${_testResult!.replaceFirst('error:', '')}',
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

  String _engineIcon(TranslationEngine e) {
    switch (e) {
      case TranslationEngine.system: return '🧠';
      case TranslationEngine.deepseek: return '🔍';
      case TranslationEngine.openai: return '🤖';
      case TranslationEngine.claude: return '🟣';
      case TranslationEngine.deepl: return '💡';
      case TranslationEngine.baidu: return '🇨🇳';
    }
  }

  String _engineLabel(TranslationEngine e) {
    switch (e) {
      case TranslationEngine.system: return '系统内置';
      case TranslationEngine.deepseek: return 'DeepSeek';
      case TranslationEngine.openai: return 'OpenAI (GPT)';
      case TranslationEngine.claude: return 'Anthropic (Claude)';
      case TranslationEngine.deepl: return 'DeepL';
      case TranslationEngine.baidu: return '百度翻译';
    }
  }

  String _hintForKey(TranslationEngine e) {
    switch (e) {
      case TranslationEngine.deepseek: return 'sk-... (从 platform.deepseek.com 获取)';
      case TranslationEngine.openai: return 'sk-... (从 platform.openai.com 获取)';
      case TranslationEngine.claude: return 'sk-ant-...';
      case TranslationEngine.deepl: return 'DeepL API Key';
      case TranslationEngine.baidu: return 'APP ID + Secret Key';
      case TranslationEngine.system: return '无需配置';
    }
  }
}
