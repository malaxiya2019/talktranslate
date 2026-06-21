import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _apiKeyController = TextEditingController(text: provider.apiKey ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // API Key 配置
          const Text('翻译引擎', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '配置 API Key 以获得高质量翻译。'
            '支持 DeepSeek / OpenAI 兼容接口。',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  context.read<AppProvider>().setApiKey(_apiKeyController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key 已保存')),
                  );
                },
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),

          // 语音设置
          const Text('语音设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('语速'),
            subtitle: Slider(value: 0.5, min: 0.25, max: 1.0, onChanged: (_) {}),
          ),
          ListTile(
            leading: const Icon(Icons.hearing),
            title: const Text('自动播放翻译结果'),
            subtitle: Text('关闭后仅显示文字', style: TextStyle(color: Colors.grey[500])),
            trailing: Switch(value: true, onChanged: (_) {}),
          ),

          const SizedBox(height: 24),

          // 通话设置
          const Text('通话设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('服务器地址'),
            subtitle: TextField(
              decoration: InputDecoration(
                hintText: 'wss://signal.talktranslate.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 关于
          const Text('关于', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('版本'),
            trailing: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('开源协议'),
            trailing: const Text('MIT'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
