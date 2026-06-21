import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/translation_engine.dart';
import '../services/overlay_manager.dart';

/// 翻译屏幕 — 双向字幕 + 对话历史
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasPerm = await OverlayManager.hasPermission();
      if (hasPerm) await OverlayManager.startService();
      context.read<AppProvider>().startTranslation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OverlayManager.hide();
    OverlayManager.stopService();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateOverlay(AppProvider provider) {
    if (provider.originalText.isNotEmpty || provider.translatedText.isNotEmpty) {
      OverlayManager.showSubtitle(
        provider.originalText,
        provider.translatedText.isNotEmpty ? provider.translatedText : '翻译中...',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          _updateOverlay(provider);
          return SafeArea(
            child: Column(
              children: [
                _buildStatusBar(provider),
                const Divider(color: Colors.white24),
                // 当前翻译 (大字体)
                _buildCurrentTranslation(provider),
                const Divider(color: Colors.white12),
                // 对话历史
                _buildConversationHistory(provider),
                _buildControls(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(provider.isListening ? Icons.mic : Icons.mic_off,
              color: provider.isListening ? Colors.greenAccent : Colors.red, size: 16),
          const SizedBox(width: 8),
          Text(provider.isListening ? '翻译中...' : '已暂停',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text('${provider.myLanguage.nativeName} → ${provider.peerLanguage.nativeName}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCurrentTranslation(AppProvider provider) {
    final isMe = provider.currentSpeaker == Speaker.me;
    final speakerLabel = isMe ? '我说' : '对方说';
    final speakerFlag = isMe ? provider.myLanguage.flag : provider.peerLanguage.flag;
    final Color accentColor = isMe ? Colors.blue : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(isMe ? Icons.person : Icons.person_outline, color: accentColor, size: 16),
            const SizedBox(width: 6),
            Text('$speakerFlag $speakerLabel', style: TextStyle(color: accentColor.shade200, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text(provider.originalText.isEmpty ? '等待语音...' : provider.originalText,
              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500, height: 1.3)),
          if (provider.translatedText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(provider.translatedText,
                style: TextStyle(fontSize: 20, color: Colors.greenAccent[100], fontWeight: FontWeight.bold, height: 1.3)),
          ] else if (provider.originalText.isNotEmpty)
            const SizedBox(height: 20, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
        ],
      ),
    );
  }

  Widget _buildConversationHistory(AppProvider provider) {
    final history = provider.conversation;
    if (history.isEmpty) return const Spacer();

    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: history.length,
        itemBuilder: (_, i) {
          final entry = history[i];
          final isMe = entry.speaker == Speaker.me;
          final flag = isMe ? provider.myLanguage.flag : provider.peerLanguage.flag;
          final label = isMe ? '我说' : '对方说';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(flag, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const Spacer(),
                    Text('${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                  ]),
                  const SizedBox(height: 4),
                  Text(entry.original, style: TextStyle(fontSize: 15, color: Colors.white70)),
                  Text(entry.translated, style: TextStyle(fontSize: 15, color: Colors.greenAccent[100], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CtrlBtn(
            icon: provider.isListening ? Icons.pause : Icons.mic,
            label: provider.isListening ? '暂停' : '继续',
            onTap: () {
              if (provider.isListening) provider.stopTranslation();
              else provider.startTranslation();
            },
          ),
          _CtrlBtn(
            icon: Icons.close, label: '关闭', color: Colors.red,
            onTap: () { provider.stopTranslation(); Navigator.pop(context); },
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon; final String label; final Color? color; final VoidCallback onTap;
  const _CtrlBtn({required this.icon, required this.label, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        CircleAvatar(radius: 22, backgroundColor: (color ?? Colors.white).withOpacity(0.15),
            child: Icon(icon, color: color ?? Colors.white, size: 20)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}
