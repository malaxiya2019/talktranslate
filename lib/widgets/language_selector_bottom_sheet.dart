import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_language_provider.dart';
import '../services/engine_config_service.dart';
import '../screens/settings_screen.dart';

/// 语言选择底部弹窗 — 同时更新 UI Locale 和翻译引擎目标语言
///
/// 修复：蓝色地球弹窗原先仅修改翻译引擎目标语言，
/// 未变更全局 App UI Locale，导致登录页文字依然是硬编码中文。
class LanguageSelectorBottomSheet extends StatelessWidget {
  const LanguageSelectorBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const LanguageSelectorBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '选择语言 / Select Language',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        SizedBox(
          height: 400,
          child: ListView(
            children: AppLanguage.list.map((lang) {
              return ListTile(
                leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                title: Text(lang.name),
                subtitle: Text(
                  lang.code,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                onTap: () async {
                  await context
                      .read<AppLanguageProvider>()
                      .changeLanguage(lang.code);
                  context
                      .read<EngineConfigService>()
                      .setTargetLanguage(lang.code);
                  if (context.mounted) Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
