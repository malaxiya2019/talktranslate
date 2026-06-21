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
  late TextEditingController _apiController;
  late TextEditingController _serverController;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>();
    _apiController = TextEditingController(text: p.apiKey ?? '');
    _serverController = TextEditingController(text: p.serverUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('信令服务器', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _serverController,
            decoration: InputDecoration(
              labelText: 'WebSocket 地址',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  context.read<AppProvider>().setServerUrl(_serverController.text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('翻译 API', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _apiController,
            decoration: InputDecoration(
              labelText: 'API Key (DeepSeek/OpenAI)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  context.read<AppProvider>().setApiKey(_apiController.text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
                },
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          const Text('关于', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const ListTile(title: const Text('版本'), trailing: const Text('2.0.0')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiController.dispose();
    _serverController.dispose();
    super.dispose();
  }
}
