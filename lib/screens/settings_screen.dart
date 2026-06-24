import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'engine_config_screen.dart';

/// 支持的语言
class AppLanguage {
  final String code;
  final String name;
  final String flag;
  const AppLanguage(this.code, this.name, this.flag);

  static const list = [
    AppLanguage('zh-CN', '中文', '🇨🇳'),
    AppLanguage('en-US', 'English', '🇺🇸'),
    AppLanguage('ja-JP', '日本語', '🇯🇵'),
    AppLanguage('ko-KR', '한국어', '🇰🇷'),
    AppLanguage('es-ES', 'Español', '🇪🇸'),
    AppLanguage('fr-FR', 'Français', '🇫🇷'),
    AppLanguage('de-DE', 'Deutsch', '🇩🇪'),
    AppLanguage('pt-BR', 'Português', '🇧🇷'),
    AppLanguage('ru-RU', 'Русский', '🇷🇺'),
    AppLanguage('ar-SA', 'العربية', '🇸🇦'),
    AppLanguage('th-TH', 'ไทย', '🇹🇭'),
    AppLanguage('vi-VN', 'Tiếng Việt', '🇻🇳'),
  ];

  static AppLanguage fromCode(String code) =>
      list.firstWhere((l) => l.code == code, orElse: () => list[1]);
}

/// 设置页 — API Key / 语言 / 服务器 / TTS
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyCtl = TextEditingController();
  final _serverCtl = TextEditingController();
  bool _obscureKey = true;
  bool _ttsEnabled = true;

  AppLanguage _myLang = AppLanguage.fromCode('zh-CN');
  AppLanguage _peerLang = AppLanguage.fromCode('en-US');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  void _loadSettings() {
    final p = context.read<AppProvider>();
    _apiKeyCtl.text = p.apiKey;
    _serverCtl.text = p.serverUrl;
    setState(() {
      _myLang = AppLanguage.fromCode(p.myLang);
      _peerLang = AppLanguage.fromCode(p.peerLang);
      _ttsEnabled = p.ttsEnabled;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final p = context.read<AppProvider>();
    await p.saveSettings(
      apiKey: _apiKeyCtl.text.trim(),
      serverUrl: _serverCtl.text.trim(),
      myLang: _myLang.code,
      peerLang: _peerLang.code,
      ttsEnabled: _ttsEnabled,
    );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('设置已保存'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyCtl.dispose();
    _serverCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── API Key ──
          _sectionHeader('🤖 AI 翻译', '用于语音翻译的 API Key'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DeepSeek API Key',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyCtl,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    hintText: 'sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                Text(
                  '从 platform.deepseek.com 获取',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 语言 ──
          _sectionHeader('🌐 语言设置', '选择你的语言和对方的语言'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _langTile(
                  label: '我的语言',
                  subtitle: '你说的话和听到的翻译',
                  lang: _myLang,
                  onTap: () => _pickLanguage(true),
                ),
                const Divider(height: 24),
                _langTile(
                  label: '对方语言',
                  subtitle: '对方说的话和听到的翻译',
                  lang: _peerLang,
                  onTap: () => _pickLanguage(false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 翻译引擎 ──
          _sectionHeader('🔌 翻译引擎', '切换AI模型与自定义API'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EngineConfigScreen()),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.model_training, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('翻译引擎', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[800])),
                        Text('OpenAI / Anthropic / DeepL / 百度', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── 服务器 ──
          _sectionHeader('📡 服务器', '信令服务器地址'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _serverCtl,
                  decoration: InputDecoration(
                    hintText: 'ws://your-server.com:3459',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    prefix: const Icon(Icons.dns, size: 16),
                  ),
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                Text(
                  '留空则使用 ws://192.168.x.x:3459',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── TTS ──
          _sectionHeader('🔊 语音朗读', '自动朗读翻译结果'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              title: const Text('朗读翻译', style: TextStyle(fontSize: 15)),
              subtitle: const Text(
                '自动朗读对方的翻译结果',
                style: TextStyle(fontSize: 12),
              ),
              value: _ttsEnabled,
              onChanged: (v) => setState(() => _ttsEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 32),

          // ── 版本 ──
          Center(
            child: Text(
              'TalkTranslate v2.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _langTile({
    required String label,
    required String subtitle,
    required AppLanguage lang,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${lang.flag} ${lang.name}',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _pickLanguage(bool isMyLang) {
    final current = isMyLang ? _myLang : _peerLang;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '选择${isMyLang ? '我的' : '对方'}语言',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 360,
            child: ListView(
              children: AppLanguage.list
                  .map(
                    (lang) => ListTile(
                      leading: Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(lang.name),
                      subtitle: Text(
                        lang.code,
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                      trailing: current.code == lang.code
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () {
                        setState(() {
                          if (isMyLang)
                            _myLang = lang;
                          else
                            _peerLang = lang;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
