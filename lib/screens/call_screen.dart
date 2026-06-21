import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// 翻译屏幕 — 实时语音翻译界面
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实时翻译'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<AppProvider>().stopTranslation();
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return SafeArea(
            child: Column(
              children: [
                // 语言状态栏
                _buildLanguageBar(provider),

                const Divider(height: 1),

                // 翻译区域
                Expanded(child: _buildTranslationPanel(provider)),

                // 控制按钮
                _buildControlButton(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageBar(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${provider.myLanguage.flag} ${provider.myLanguage.nativeName}',
              style: const TextStyle(fontSize: 16)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward, size: 20),
          ),
          Text('${provider.peerLanguage.flag} ${provider.peerLanguage.nativeName}',
              style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTranslationPanel(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 原文
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎤 我说', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        provider.originalText.isEmpty ? '等待语音...' : provider.originalText,
                        style: TextStyle(fontSize: 20, color: provider.originalText.isEmpty ? Colors.grey[400] : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 翻译结果
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌍 ${provider.peerLanguage.nativeName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  if (provider.originalText.isNotEmpty && provider.translatedText.isEmpty)
                    const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        provider.translatedText.isEmpty ? '翻译结果...' : provider.translatedText,
                        style: TextStyle(fontSize: 20, color: provider.translatedText.isEmpty ? Colors.grey[400] : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(AppProvider provider) {
    final isTranslating = provider.isTranslating;

    return Container(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            if (isTranslating) {
              provider.stopTranslation();
            } else {
              provider.startTranslation();
            }
          },
          icon: Icon(isTranslating ? Icons.stop : Icons.mic, size: 24),
          label: Text(isTranslating ? '停止翻译' : '开始翻译',
              style: const TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isTranslating ? Colors.red : Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}
