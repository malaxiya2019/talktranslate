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
  bool _agreed = false;
  String _selectedCode = '+86';

  static const _defaultServer = 'ws://localhost:3459';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.translate, size: 44, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              const Text('TalkTranslate', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('VoIP 实时翻译通话', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 40),

              // 服务器地址 (可折叠)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dns, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text('服务器', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _serverCtl.text = _defaultServer,
                          icon: const Icon(Icons.restore, size: 14),
                          label: const Text('默认', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _serverCtl,
                      decoration: InputDecoration(
                        hintText: 'ws://your-server.com:3459',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        filled: true, fillColor: Colors.white,
                        isDense: true, contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      ),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 手机号
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // 国家代码
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          const Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 28, color: Colors.grey[300]),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtl,
                        decoration: const InputDecoration(
                          hintText: '请输入手机号码',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.fromLTRB(12, 14, 12, 14),
                        ),
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 登录按钮
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _agreed ? () => p.login('$_selectedCode ${_phoneCtl.text.trim()}') : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 16),

              // 协议勾选
              Row(
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: '登录即代表您同意 ', style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        children: [
                          TextSpan(text: '《用户服务协议》', style: TextStyle(color: Colors.blue[600])),
                          const TextSpan(text: ' 和 '),
                          TextSpan(text: '《隐私政策》', style: TextStyle(color: Colors.blue[600])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 注册/忘记密码
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: () {}, child: Text('新用户注册', style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
                  Text('|', style: TextStyle(color: Colors.grey[300])),
                  TextButton(onPressed: () {}, child: Text('忘记密码', style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialer(AppProvider p) {
    return SafeArea(
      child: Column(
        children: [
          // 顶栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Icon(Icons.phone_in_talk, size: 16, color: Colors.green[600]),
              const SizedBox(width: 6),
              Text(p.phone ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('在线 ${p.onlineUsers.length}人', style: TextStyle(fontSize: 11, color: Colors.green[700])),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.logout, size: 18, color: Colors.grey), onPressed: () => p.logout()),
            ]),
          ),
          const Divider(height: 1),

          // 拨号
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: TextField(
              controller: _dialCtl,
              decoration: InputDecoration(
                hintText: '输入对方手机号',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('+86', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              ),
              keyboardType: TextInputType.phone,
            ),
          ),

          // 呼叫按钮
          SizedBox(
            width: 64, height: 64,
            child: FloatingActionButton(
              onPressed: () {
                final to = _dialCtl.text.trim();
                if (to.isNotEmpty) {
                  p.call(to);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CallScreen()));
                }
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.call, color: Colors.white, size: 28),
            ),
          ),

          const SizedBox(height: 20),

          // 在线用户列表
          Expanded(
            child: p.onlineUsers.where((u) => u != p.phone).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('暂无其他在线用户', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: p.onlineUsers.where((u) => u != p.phone).length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
                    itemBuilder: (_, i) {
                      final user = p.onlineUsers.where((u) => u != p.phone).elementAt(i);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Text(user.substring(user.length - 4), style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                        ),
                        title: Text(user, style: const TextStyle(fontSize: 15)),
                        subtitle: Text('在线', style: TextStyle(fontSize: 12, color: Colors.green[400])),
                        trailing: IconButton(
                          icon: Icon(Icons.phone, color: Colors.green[400], size: 22),
                          onPressed: () { _dialCtl.text = user; },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _phoneCtl.dispose(); _dialCtl.dispose(); _serverCtl.dispose(); super.dispose(); }
}
