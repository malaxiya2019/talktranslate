import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/login_provider.dart';
import '../widgets/language_selector_bottom_sheet.dart';
import 'call_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'register_screen.dart';

/// 国家代码
class CountryCode {
  final String flag;
  final String code;
  final String name;
  final String dial;
  const CountryCode(this.flag, this.code, this.name, this.dial);
  static const list = [
    CountryCode('🇨🇳', '+86', '中国', '+86'),
    CountryCode('🇭🇰', '+852', '香港', '+852'),
    CountryCode('🇹🇼', '+886', '台湾', '+886'),
    CountryCode('🇺🇸', '+1', 'United States', '+1'),
    CountryCode('🇬🇧', '+44', 'United Kingdom', '+44'),
    CountryCode('🇯🇵', '+81', '日本', '+81'),
    CountryCode('🇰🇷', '+82', '대한민국', '+82'),
    CountryCode('🇸🇬', '+65', 'Singapore', '+65'),
    CountryCode('🇲🇾', '+60', 'Malaysia', '+60'),
    CountryCode('🇻🇳', '+84', 'Việt Nam', '+84'),
    CountryCode('🇹🇭', '+66', 'ไทย', '+66'),
    CountryCode('🇮🇩', '+62', 'Indonesia', '+62'),
    CountryCode('🇮🇳', '+91', 'India', '+91'),
    CountryCode('🇦🇺', '+61', 'Australia', '+61'),
    CountryCode('🇫🇷', '+33', 'France', '+33'),
    CountryCode('🇩🇪', '+49', 'Germany', '+49'),
    CountryCode('🇪🇸', '+34', 'Spain', '+34'),
    CountryCode('🇧🇷', '+55', 'Brasil', '+55'),
    CountryCode('🇷🇺', '+7', 'Россия', '+7'),
  ];
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _phoneCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _dialCtl = TextEditingController();
  final _serverCtl = TextEditingController();
  bool _agreed = false;
  CountryCode _country = CountryCode.list[0];
  bool _sentCode = false;
  int _codeCountdown = 0;
  bool _showWizard = true;
  int _logoTapCount = 0;

  static const _defaultServer = '';
  final _loginProvider = LoginProvider();

  @override
  void initState() {
    super.initState();
    _loginProvider.addListener(_onLoginStateChanged);
    _loginProvider.setCountryCode(_country.dial);
    _phoneCtl.addListener(() => _loginProvider.setPhoneNumber(_phoneCtl.text));
  }

  void _onLoginStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 已登录则跳过向导
    final p = context.read<AppProvider>();
    if (p.connected && _showWizard) {
      setState(() => _showWizard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 已登录或嵌入 AppShell 时跳过向导
    final isEmbedded = ModalRoute.of(context)?.settings.name == '/app';
    if (_showWizard && !isEmbedded) {
      final p = context.read<AppProvider>();
      if (!p.connected) return _buildWizard();
    }
    if (_showWizard) _showWizard = false;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          if (p.toast != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(p.toast!)));
              p.clearToast();
            });
          }
          if (!p.connected) return _buildLogin(p);
          return _buildContacts(p);
        },
      ),
    ),
    );
  }

  // ── 首次启动向导 ──

  int _wizardPage = 0;
  Widget _buildWizard() {
    final pages = [
      _wizardPageData(
        '🗣️',
        '欢迎使用 TalkTranslate',
        '实时翻译语音通话平台\n跨国通话 · AI 字幕 · 清晰音质',
      ),
      _wizardPageData('🌍', '支持多国语言', '中、英、日、韩、西、法、德…\n自动识别、实时翻译'),
      _wizardPageData('🔒', '安全可靠', '端到端加密通话\n您的隐私安全无忧'),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    pages[_wizardPage].emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    pages[_wizardPage].title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pages[_wizardPage].desc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 指示点
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _wizardPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _wizardPage == i ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_wizardPage < 2)
                      setState(() => _wizardPage++);
                    else
                      setState(() => _showWizard = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _wizardPage < 2 ? '下一步' : '开始使用',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            if (_wizardPage < 2)
              TextButton(
                onPressed: () => setState(() => _showWizard = false),
                child: Text('跳过', style: TextStyle(color: Colors.grey[400])),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  ({String emoji, String title, String desc}) _wizardPageData(
    String emoji,
    String title,
    String desc,
  ) => (emoji: emoji, title: title, desc: desc);

  // ── 登录页 ──

  Widget _buildLogin(AppProvider p) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 连接状态 + 语言切换
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _serverCtl.text.contains('localhost')
                              ? Colors.orange : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _serverCtl.text.contains('localhost') ? '未连接' : '就绪',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _showLanguagePicker(context),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Text('🌐', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Logo (连续点击5次进入开发者模式)
              GestureDetector(
                onTap: () async {
                  _logoTapCount++;
                  if (_logoTapCount >= 5) {
                    _logoTapCount = 0;
                    final url = await _showDevDialog(context);
                    if (url != null) {
                      _serverCtl.text = url;
                      await p.setServer(url);
                    }
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.translate,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'TalkTranslate',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Text(
                '实时翻译语音通话平台',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),

              // 服务器 (可折叠) — Release 包隐藏
              if (!kReleaseMode)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                        Text(
                          '服务器配置',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _serverCtl.text = _defaultServer,
                          child: const Text(
                            '默认',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _serverCtl,
                      decoration: InputDecoration(
                        hintText: 'wss://your-server.com:3459',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.fromLTRB(
                          12,
                          10,
                          12,
                          10,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),

              // 手机号
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _showCountryPicker(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        height: 48,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _country.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _country.dial,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 28, color: Colors.grey[300]),
                    Expanded(
                      child: TextField(
                        controller: _phoneCtl,
                        decoration: const InputDecoration(
                          hintText: '请输入手机号',
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

              // 获取验证码
              if (!_sentCode) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      if (_phoneCtl.text.trim().length >= 6) {
                        setState(() {
                          _sentCode = true;
                          _codeCountdown = 60;
                        });
                        _startCountdown();
                        if (!kReleaseMode) _codeCtl.text = '123456';
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      '获取验证码',
                      style: TextStyle(fontSize: 15, color: Colors.blue[600]),
                    ),
                  ),
                ),
              ],

              // 验证码输入
              if (_sentCode) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        height: 48,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sms, size: 18, color: Colors.grey[500]),
                            const SizedBox(width: 6),
                            Text(
                              '验证码',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 28, color: Colors.grey[300]),
                      Expanded(
                        child: TextField(
                          controller: _codeCtl,
                          decoration: InputDecoration(
                            hintText: '输入验证码',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.fromLTRB(
                              12,
                              14,
                              12,
                              14,
                            ),
                            suffixText: _codeCountdown > 0 ? '重新获取 (${_codeCountdown}s)' : '重新获取',
                            suffixStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (_loginProvider.isLoginButtonEnabled &&
                          _codeCtl.text.length >= 4)
                      ? () async {
                            await _loginProvider.verifySmsCode(_codeCtl.text);
                            await p.setServer(_serverCtl.text.trim());
                            await p.login(_loginProvider.e164Phone);
                            if (mounted && p.connected) {
                              Navigator.pushReplacementNamed(context, '/app');
                            }
                          }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[200],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                  child: const Text(
                    '登录',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 协议
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() {
                        _agreed = v ?? false;
                        _loginProvider.setAgreed(_agreed);
                      }),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: '我已阅读并同意 ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        children: [
                          TextSpan(
                            text: '《用户协议》',
                            style: TextStyle(color: Colors.blue[600]),
                          ),
                          TextSpan(
                            text: ' ',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          TextSpan(
                            text: '《隐私政策》',
                            style: TextStyle(color: Colors.blue[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      '新用户注册',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1E88E5)),
                    ),
                  ),
                  Text('|', style: TextStyle(color: Colors.grey[300])),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('密码重置功能开发中')),
                      );
                    },
                    child: Text(
                      '忘记密码',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1E88E5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Version 2.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// 语言切换弹窗
  void _showLanguagePicker(BuildContext context) {
    LanguageSelectorBottomSheet.show(context);
  }

  /// 开发者模式弹窗 — 连续点击 Logo 5 次触发
  Future<String?> _showDevDialog(BuildContext context) async {
    final ctl = TextEditingController(text: _serverCtl.text);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('开发者模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入 WebSocket 服务器地址', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: ctl,
              decoration: const InputDecoration(
                hintText: 'wss://your-server.com',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
            child: const Text('确定', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    ctl.dispose();
    return url;
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
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
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '选择国家/地区',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 400,
            child: ListView(
              children: CountryCode.list
                  .map(
                    (c) => ListTile(
                      leading: Text(
                        c.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(c.name),
                      trailing: Text(
                        c.dial,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      onTap: () {
                        setState(() {
                          _country = c;
                          _loginProvider.setCountryCode(c.dial);
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

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _codeCountdown--);
      return _codeCountdown > 0;
    });
  }

  // ── 联系人与拨号 ──

  Widget _buildContacts(AppProvider p) {
    final contacts = p.onlineUsers.where((u) => u != p.phone).toList();
    return SafeArea(
      child: Column(
        children: [
          // 顶栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: Text(
                    p.phone!.substring(p.phone!.length - 2),
                    style: TextStyle(fontSize: 10, color: Colors.green[700]),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.phone ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '在线',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: Icon(Icons.history, size: 20, color: Colors.grey[500]),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: Icon(
                    Icons.settings,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => SystemNavigator.pop(),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 联系人列表
          Expanded(
            child: contacts.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[200],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '暂无联系人',
                        style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '邀请好友或等待对方上线',
                        style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: contacts.length + 1,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      if (i == contacts.length) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(
                              Icons.person_add_alt,
                              size: 20,
                              color: Colors.green,
                            ),
                          ),
                          title: const Text(
                            '新建通话',
                            style: TextStyle(fontSize: 15, color: Colors.green),
                          ),
                          onTap: () => _showDialDialog(context),
                        );
                      }
                      final user = contacts[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          child: Text(
                            user.substring(user.length - 2),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                        title: Text(
                          user,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('在线', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.phone,
                            color: Colors.green[400],
                            size: 22,
                          ),
                          onPressed: () {
                            p.call(user);
                            _pushCallScreen();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final phoneCtl = TextEditingController();
        return AlertDialog(
          title: const Text('输入对方手机号'),
          content: TextField(
            controller: phoneCtl,
            autofocus: true,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '+86 13800138000',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton.icon(
              onPressed: () {
                final phone = phoneCtl.text.trim();
                if (phone.isNotEmpty) {
                  Navigator.pop(ctx);
                  context.read<AppProvider>().call(phone);
                  _pushCallScreen();
                }
              },
              icon: const Icon(Icons.call, size: 16),
              label: const Text('呼叫'),
            ),
          ],
        );
      },
    );
  }

  void _pushCallScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CallScreen(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _loginProvider.removeListener(_onLoginStateChanged);
    _phoneCtl.dispose();
    _codeCtl.dispose();
    _dialCtl.dispose();
    _serverCtl.dispose();
    super.dispose();
  }
}
