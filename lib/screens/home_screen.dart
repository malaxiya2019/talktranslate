import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'call_screen.dart';
import 'settings_screen.dart';

/// 首页 — 登录 + 拨号盘
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _phoneController = TextEditingController(text: '');
  final _dialController = TextEditingController(text: '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TalkTranslate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (!provider.connected) {
            return _buildLogin(provider);
          }
          return _buildDialer(provider);
        },
      ),
    );
  }

  Widget _buildLogin(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.translate, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('TalkTranslate', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('实时翻译通话', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 40),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: '手机号',
              hintText: '+86 138 0013 8000',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final phone = _phoneController.text.trim();
                if (phone.isNotEmpty) provider.connect(phone);
              },
              child: const Text('登录', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialer(AppProvider provider) {
    return Column(
      children: [
        // 语言选择
        _buildLanguageBar(provider),
        const Divider(),
        // 拨号输入
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _dialController,
            decoration: InputDecoration(
              labelText: '输入对方手机号',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.phone,
          ),
        ),
        // 呼叫按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                final to = _dialController.text.trim();
                if (to.isNotEmpty) {
                  provider.startCall(to);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CallScreen()));
                }
              },
              icon: const Icon(Icons.call),
              label: const Text('呼叫', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 在线用户
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('在线用户 (${provider.onlineUsers.length})', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ),
              Expanded(
                child: provider.onlineUsers.isEmpty
                    ? const Center(child: Text('暂无其他在线用户'))
                    : ListView.builder(
                        itemCount: provider.onlineUsers.length,
                        itemBuilder: (_, i) {
                          final user = provider.onlineUsers[i];
                          final isMe = user == provider.phone;
                          return ListTile(
                            leading: CircleAvatar(child: Text(user.substring(user.length - 4))),
                            title: Text(user),
                            subtitle: Text(isMe ? '我' : '在线'),
                            trailing: isMe
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.call, color: Colors.green),
                                    onPressed: () {
                                      _dialController.text = user;
                                    },
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageBar(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _LangChip(
              flag: provider.myLanguage.flag,
              name: provider.myLanguage.nativeName,
              onTap: () => _pickLanguage(context, true, provider),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => provider.swapLanguages(),
          ),
          Expanded(
            child: _LangChip(
              flag: provider.peerLanguage.flag,
              name: provider.peerLanguage.nativeName,
              onTap: () => _pickLanguage(context, false, provider),
            ),
          ),
        ],
      ),
    );
  }

  void _pickLanguage(BuildContext context, bool isMy, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: Language.supported.map((lang) {
          return ListTile(
            leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
            title: Text(lang.nativeName),
            subtitle: Text(lang.name),
            onTap: () {
              if (isMy) provider.setMyLanguage(lang);
              else provider.setPeerLanguage(lang);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _dialController.dispose();
    super.dispose();
  }
}

class _LangChip extends StatelessWidget {
  final String flag;
  final String name;
  final VoidCallback onTap;

  const _LangChip({required this.flag, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(name, style: const TextStyle(fontSize: 13)),
        ]),
      ),
    );
  }
}
