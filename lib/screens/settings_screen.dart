import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/app_language_provider.dart';
import 'engine_config_screen.dart';
import '../services/keep_alive_helper.dart';

/// 支持的语言
class AppLanguage {
  static List<Locale> get supportedLocales =>
      list.map((l) => Locale(l.code.split('-')[0], l.code.split('-')[1])).toList();
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

/// ──── 完整设置页 ────
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
  bool _autoAnswer = false;
  bool _showOverlay = true;
  bool _noiseSuppression = true;
  bool _speakerMode = false;
  String _themeMode = 'system'; // system | light | dark
  String _translationProvider = 'deepseek'; // deepseek | openai

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
      _showSnack('✅ 设置已保存');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  void _showLanguagePicker(bool isMyLang) {
    final current = isMyLang ? _myLang : _peerLang;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LanguagePickerSheet(
        isMyLang: isMyLang,
        current: current,
        onSelect: (lang) {
          setState(() {
            if (isMyLang) {
              _myLang = lang;
              context.read<AppLanguageProvider>().changeLanguage(lang.code);
            } else {
              _peerLang = lang;
            }
          });
        },
      ),
    );
  }

  Future<bool> _confirmClear(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('确定', style: TextStyle(color: Colors.red[600])),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _apiKeyCtl.dispose();
    _serverCtl.dispose();
    super.dispose();
  }

  // ──── 构建方法 ────

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
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ═══════════════════
          // 🤖 翻译引擎
          // ═══════════════════
          _sectionHeader('🤖 翻译引擎', 'AI 语音翻译配置'),
          _card([
            _textField(
              controller: _apiKeyCtl,
              label: 'DeepSeek API Key',
              hint: 'sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
              obscure: _obscureKey,
              onToggleObscure: () => setState(() => _obscureKey = !_obscureKey),
              helper: '从 platform.deepseek.com 获取',
              monospace: true,
            ),
            const SizedBox(height: 12),
            _dropdownTile(
              icon: Icons.model_training,
              label: '翻译模型',
              value: _translationProvider,
              options: const [
                ('deepseek', 'DeepSeek Chat'),
                ('openai', 'OpenAI GPT'),
              ],
              onChanged: (v) => setState(() => _translationProvider = v),
            ),
          ]),

          const SizedBox(height: 20),

          // ═══════════════════
          // 🎨 外观主题
          // ═══════════════════
          _sectionHeader('🎨 外观', '主题与显示'),
          _card([
            _dropdownTile(
              icon: Icons.dark_mode,
              label: '主题模式',
              value: _themeMode,
              options: const [
                ('system', '跟随系统'),
                ('light', '浅色'),
                ('dark', '深色'),
              ],
              onChanged: (v) => setState(() => _themeMode = v),
            ),
            const Divider(height: 1),
            _switchTile(
              icon: Icons.speaker_notes_outlined,
              label: '显示实时字幕',
              subtitle: '通话中显示翻译字幕',
              value: _showOverlay,
              onChanged: (v) => setState(() => _showOverlay = v),
            ),
          ]),

          const SizedBox(height: 20),

          // ═══════════════════
          // 🌐 翻译语言
          // ═══════════════════
          _sectionHeader('🌐 翻译语言', '选择翻译的双向语言'),
          _card([
            _langTile('我的语言', _myLang, () => _showLanguagePicker(true)),
            const Divider(height: 1),
            _langTile('对方语言', _peerLang, () => _showLanguagePicker(false)),
          ]),

          const SizedBox(height: 20),

          // ═══════════════════
          // 📞 通话偏好
          // ═══════════════════
          _sectionHeader('📞 通话', '通话行为设置'),
          _card([
            _switchTile(
              icon: Icons.call_end_outlined,
              label: '自动接听',
              subtitle: '收到来电时自动接听',
              value: _autoAnswer,
              onChanged: (v) => setState(() => _autoAnswer = v),
            ),
            const Divider(height: 1),
            _switchTile(
              icon: Icons.volume_up_outlined,
              label: '扬声器模式',
              subtitle: '默认使用扬声器外放',
              value: _speakerMode,
              onChanged: (v) => setState(() => _speakerMode = v),
            ),
            const Divider(height: 1),
            _switchTile(
              icon: Icons.record_voice_over,
              label: 'TTS 语音合成',
              subtitle: '将翻译结果朗读出来',
              value: _ttsEnabled,
              onChanged: (v) => setState(() => _ttsEnabled = v),
            ),
          ]),

          const SizedBox(height: 20),

          // ═══════════════════
          // 🔊 音频
          // ═══════════════════
          _sectionHeader('🔊 音频', '音频输入输出设置'),
          _card([
            _switchTile(
              icon: Icons.hearing,
              label: '降噪',
              subtitle: '过滤背景噪音，提升识别准确率',
              value: _noiseSuppression,
              onChanged: (v) => setState(() => _noiseSuppression = v),
            ),
          ]),

          const SizedBox(height: 20),

          // ═══════════════════
          // 🔧 高级
          // ═══════════════════
          _sectionHeader('🔧 高级', '服务器与开发者选项'),
          _card([
            _textField(
              controller: _serverCtl,
              label: '信令服务器地址',
              hint: 'ws://192.168.1.100:8788',
              helper: 'WebSocket 信令服务器地址',
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const EngineConfigScreen(),
                )),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('详细引擎配置'),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // ═══════════════════
          // 📊 数据管理
          // ═══════════════════
          _sectionHeader('📊 数据管理', '管理本地数据与缓存'),
          _card([
            _actionTile(
              icon: Icons.history,
              label: '清除通话记录',
              subtitle: '删除所有历史通话记录',
              iconColor: Colors.orange,
              onTap: () async {
                if (await _confirmClear('清除通话记录', '确定删除所有通话记录吗？此操作不可撤销。')) {
                  _showSnack('✅ 通话记录已清除');
                }
              },
            ),
            const Divider(height: 1),
            _actionTile(
              icon: Icons.cached,
              label: '清除翻译缓存',
              subtitle: '清除本地翻译缓存数据',
              iconColor: Colors.orange,
              onTap: () async {
                if (await _confirmClear('清除缓存', '确定清除翻译缓存吗？')) {
                  _showSnack('✅ 缓存已清除');
                }
              },
            ),
            const Divider(height: 1),
            _actionTile(
              icon: Icons.download_outlined,
              label: '导出数据',
              subtitle: '导出设置和通话记录',
              iconColor: Colors.blue,
              onTap: () => _showSnack('📦 数据导出功能 (开发中)'),
            ),
          ]),

          const SizedBox(height: 20),

          // ═══════════════════
          // 🛡️ 保活
          // ═══════════════════
          _sectionHeader('🛡️ 保活', '防止后台被系统杀死'),
          _KeepAliveCard(),

          const SizedBox(height: 20),

          // ═══════════════════
          // ℹ️ 关于
          // ═══════════════════
          _sectionHeader('ℹ️ 关于', '应用信息'),
          _card([
            _infoTile('应用名称', 'TalkTranslate'),
            const Divider(height: 1),
            _infoTile('版本', '1.0.0'),
            const Divider(height: 1),
            _infoTile('引擎', 'DeepSeek + WebRTC'),
            const Divider(height: 1),
            _infoTile('数据存储', 'SharedPreferences + SecureStorage'),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ──── 构建辅助方法 ────

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String hint = '',
    String helper = '',
    bool obscure = false,
    VoidCallback? onToggleObscure,
    bool monospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(fontSize: 14, fontFamily: monospace ? 'monospace' : null),
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              suffixIcon: onToggleObscure != null
                  ? IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: onToggleObscure,
                    )
                  : null,
            ),
          ),
          if (helper.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(helper, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ],
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _dropdownTile({
    required IconData icon,
    required String label,
    required String value,
    required List<(String, String)> options,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }

  Widget _langTile(String label, AppLanguage lang, VoidCallback onTap) {
    return ListTile(
      leading: Text(lang.flag, style: const TextStyle(fontSize: 28)),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text('${lang.name} (${lang.code})', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// ──── 语言选择 BottomSheet ────
class _LanguagePickerSheet extends StatefulWidget {
  final bool isMyLang;
  final AppLanguage current;
  final ValueChanged<AppLanguage> onSelect;
  const _LanguagePickerSheet({required this.isMyLang, required this.current, required this.onSelect});

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  String _search = '';
  late AppLanguage _current;

  @override
  void initState() {
    super.initState();
    _current = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? AppLanguage.list
        : AppLanguage.list.where((l) =>
            l.name.toLowerCase().contains(_search.toLowerCase()) ||
            l.code.toLowerCase().contains(_search.toLowerCase())).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示器
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('选择${widget.isMyLang ? '我的' : '对方'}语言',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${filtered.length} 种',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索语言...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          // 语言列表
          Flexible(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final lang = filtered[i];
                final selected = _current.code == lang.code;
                return ListTile(
                  leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(lang.name),
                  subtitle: Text(lang.code, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  selected: selected,
                  onTap: () {
                    setState(() => _current = lang);
                    widget.onSelect(lang);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ──── 保活状态卡片 ────
class _KeepAliveCard extends StatefulWidget {
  @override
  _KeepAliveCardState createState() => _KeepAliveCardState();
}

class _KeepAliveCardState extends State<_KeepAliveCard> {
  KeepAliveStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _loading = true);
    final status = await KeepAliveHelper().check();
    if (mounted) setState(() { _status = status; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: _loading
          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tile(
                  icon: Icons.notifications_outlined,
                  label: '通知权限 (Android 13+)',
                  ok: _status!.notificationOk,
                  onTap: _status!.notificationOk ? null : () async {
                    await KeepAliveHelper().requestNotification();
                    await _check();
                  },
                ),
                const Divider(height: 20),
                _tile(
                  icon: Icons.battery_std_outlined,
                  label: '电池优化白名单',
                  ok: _status!.batteryOk,
                  subtitle: '国产 ROM 还需手动加入"受保护应用"',
                  onTap: _status!.batteryOk ? null : () async {
                    await KeepAliveHelper().requestBatteryWhitelist();
                    await _check();
                  },
                ),
                if (_status!.missingCount > 0) ...[
                  const SizedBox(height: 12),
                  Text('⚠️ 有 ${_status!.missingCount} 项未配置，后台通话可能被系统杀死',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ],
                if (_status!.notificationOk && _status!.batteryOk) ...[
                  const SizedBox(height: 12),
                  Text('✅ 保活配置完成',
                    style: TextStyle(fontSize: 12, color: Colors.green[600]),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _tile({
    required IconData icon, required String label, required bool ok,
    String? subtitle, VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ok ? Colors.green : Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: ok ? Colors.grey[600] : Colors.grey[800])),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          if (ok)
            const Icon(Icons.check_circle, size: 18, color: Colors.green)
          else if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text('修复', style: TextStyle(fontSize: 12, color: Colors.blue[600])),
            ),
        ],
      ),
    );
  }
}
