import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiController;

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController(text: context.read<AppProvider>().apiKey ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('翻译引擎', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '需要 API Key 以获得高质量翻译。支持 DeepSeek / OpenAI 兼容接口。',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiController,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  context.read<AppProvider>().setApiKey(_apiController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key 已保存')),
                  );
                },
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 32),
          const Text('使用说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _tip('1. 选择你和对方的语言'),
          _tip('2. 开启扬声器 (打电话/微信/WhatsApp 时)'),
          _tip('3. 打开 App 点「开始翻译」'),
          _tip('4. App 会自动识别并翻译'),
          const SizedBox(height: 24),
          const Text('关于', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const ListTile(title: const Text('版本'), trailing: const Text('1.5.0')),
        ],
      ),
    );
  }

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [const Icon(Icons.check, size: 16, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 14)))]),
  );

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }
}
