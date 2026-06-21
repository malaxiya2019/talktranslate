import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/language.dart';
import '../providers/app_provider.dart';
import 'call_screen.dart';
import 'settings_screen.dart';

/// 首页 — 语言选择 + 拨号
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TalkTranslate'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              const SizedBox(height: 40),
              // 标题
              Text(
                '实时双语通话翻译',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '和任何人用任何语言交流',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              // 我的语言
              _LanguageSelector(
                label: '我说的语言',
                selected: provider.myLanguage!,
                onSelected: (lang) => provider.setMyLanguage(lang),
              ),

              // 交换按钮
              IconButton(
                icon: const Icon(Icons.swap_vert, size: 32),
                onPressed: () => provider.swapLanguages(),
                tooltip: '交换语言',
              ),

              // 对方语言
              _LanguageSelector(
                label: '对方说的语言',
                selected: provider.peerLanguage!,
                onSelected: (lang) => provider.setPeerLanguage(lang),
              ),

              const Spacer(),

              // 开始通话按钮
              Padding(
                padding: const EdgeInsets.all(32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _startCall(context),
                    icon: const Icon(Icons.phone, size: 24),
                    label: const Text('开始通话', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ),

              // 历史记录入口
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.history),
                label: const Text('通话记录'),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  void _startCall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CallScreen(),
      ),
    );
  }
}

/// 语言选择器
class _LanguageSelector extends StatelessWidget {
  final String label;
  final Language selected;
  final ValueChanged<Language> onSelected;

  const _LanguageSelector({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showPicker(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(selected.flag, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selected.nativeName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        Text(selected.name,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: Language.supported.map((lang) {
          return ListTile(
            leading: Text(lang.flag, style: const TextStyle(fontSize: 28)),
            title: Text(lang.nativeName),
            subtitle: Text(lang.name),
            trailing: lang.code == selected.code ? const Icon(Icons.check) : null,
            onTap: () {
              onSelected(lang);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}
