import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/language.dart';
import '../providers/app_provider.dart';
import 'translate_screen.dart';
import 'settings_screen.dart';

/// 首页 — 语言选择 + 开始翻译
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              const SizedBox(height: 32),
              // 图标
              const Icon(Icons.translate, size: 72, color: Colors.blue),
              const SizedBox(height: 8),
              const Text('通话实时翻译', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('打开扬声器 → App 自动翻译', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 40),

              // 语言选择
              _LangSelector(
                label: '我说',
                selected: provider.myLanguage,
                onSelected: (l) => provider.setMyLanguage(l),
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert, size: 28),
                onPressed: () => provider.swapLanguages(),
              ),
              _LangSelector(
                label: '对方说',
                selected: provider.peerLanguage,
                onSelected: (l) => provider.setPeerLanguage(l),
              ),

              const Spacer(),

              // 开始按钮
              Padding(
                padding: const EdgeInsets.all(32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslateScreen())),
                    icon: const Icon(Icons.mic, size: 24),
                    label: const Text('开始翻译', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                  ),
                ),
              ),
              Text('无需对方安装 App', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _LangSelector extends StatelessWidget {
  final String label;
  final Language selected;
  final ValueChanged<Language> onSelected;

  const _LangSelector({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: InkWell(
        onTap: () => _showPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text(selected.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selected.nativeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ]),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: Language.supported.map((l) => ListTile(
          leading: Text(l.flag, style: const TextStyle(fontSize: 28)),
          title: Text(l.nativeName),
          subtitle: Text(l.name),
          trailing: l.code == selected.code ? const Icon(Icons.check) : null,
          onTap: () { onSelected(l); Navigator.pop(context); },
        )).toList(),
      ),
    );
  }
}
