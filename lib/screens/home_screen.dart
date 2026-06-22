import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _phoneCtl = TextEditingController();
  final _dialCtl = TextEditingController();
  final _serverCtl = TextEditingController(text: 'ws://localhost:3459');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TalkTranslate'), centerTitle: true),
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          if (p.toast != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.toast!)));
              p.clearToast();
            });
          }
          if (!p.connected) return _buildLogin(p);
          return _buildDialer(p);
        },
      ),
    );
  }

  Widget _buildLogin(AppProvider p) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.translate, size: 72, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('TalkTranslate', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('VoIP 实时翻译通话', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          TextField(
            controller: _serverCtl,
            decoration: InputDecoration(labelText: '信令服务器地址', border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtl,
            decoration: InputDecoration(labelText: '手机号', prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(onPressed: () => p.login(_phoneCtl.text.trim()), child: const Text('登录', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget _buildDialer(AppProvider p) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Text('📞 ${p.phone}', style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Text('在线 ${p.onlineUsers.length}人', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            IconButton(icon: const Icon(Icons.logout, size: 18), onPressed: () => p.logout()),
          ]),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _dialCtl,
            decoration: InputDecoration(labelText: '输入对方手机号', prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
        ),
        SizedBox(
          width: 200, height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              final to = _dialCtl.text.trim();
              if (to.isNotEmpty) { p.call(to); Navigator.push(context, MaterialPageRoute(builder: (_) => const CallScreen())); }
            },
            icon: const Icon(Icons.call, size: 24),
            label: const Text('呼叫', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: const CircleBorder()),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: p.onlineUsers.isEmpty
              ? const Center(child: Text('暂无其他在线用户', style: TextStyle(color: Colors.grey)))
              : ListView(
                  children: p.onlineUsers.where((u) => u != p.phone).map((u) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(u),
                    trailing: IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () { _dialCtl.text = u; },
                    ),
                  )).toList(),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() { _phoneCtl.dispose(); _dialCtl.dispose(); _serverCtl.dispose(); super.dispose(); }
}
