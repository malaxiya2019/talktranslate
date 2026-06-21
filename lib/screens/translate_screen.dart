import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/overlay_manager.dart';

/// 翻译屏幕 — 大字体悬浮字幕
class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 尝试启动悬浮窗
      final hasPerm = await OverlayManager.hasPermission();
      if (hasPerm) {
        await OverlayManager.startService();
      }
      context.read<AppProvider>().startTranslation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OverlayManager.hide();
    OverlayManager.stopService();
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App 切到后台时继续监听
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          // 更新悬浮窗字幕
          _updateOverlay(provider);
          return SafeArea(
            child: Column(
              children: [
                // 顶部状态
                _buildStatusBar(provider),
                const Divider(color: Colors.white24),

                // 主字幕区域
                Expanded(child: _buildSubtitles(provider)),

                // 底部控制
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
          Icon(provider.isListening ? Icons.mic : Icons.mic_off, color: provider.isListening ? Colors.greenAccent : Colors.red, size: 16),
          const SizedBox(width: 8),
          Text(provider.isListening ? '正在聆听...  ${provider.myLanguage.flag}' : '已暂停', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text('${provider.myLanguage.nativeName} → ${provider.peerLanguage.nativeName}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSubtitles(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 原文 (我的语音)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎤 你说', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  provider.originalText.isEmpty ? '等待语音...' : provider.originalText,
                  style: TextStyle(
                    fontSize: provider.originalText.length > 30 ? 22 : 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 翻译结果 (对方语言)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌍 ${provider.peerLanguage.nativeName}', style: TextStyle(color: Colors.greenAccent[200], fontSize: 13)),
                const SizedBox(height: 8),
                if (provider.originalText.isNotEmpty && provider.translatedText.isEmpty)
                  const SizedBox(
                    height: 24,
                    child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                Text(
                  provider.translatedText.isEmpty && provider.originalText.isEmpty
                      ? '等待翻译...'
                      : provider.translatedText,
                  style: TextStyle(
                    fontSize: provider.translatedText.length > 30 ? 22 : 28,
                    color: Colors.greenAccent[100],
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 暂停/继续
          _CtrlBtn(
            icon: provider.isListening ? Icons.pause : Icons.mic,
            label: provider.isListening ? '暂停' : '继续',
            onTap: () {
              if (provider.isListening) provider.stopTranslation();
              else provider.startTranslation();
            },
          ),
          // 关闭
          _CtrlBtn(
            icon: Icons.close,
            label: '关闭',
            color: Colors.red,
            onTap: () {
              provider.stopTranslation();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _CtrlBtn({required this.icon, required this.label, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: (color ?? Colors.white).withOpacity(0.15),
            child: Icon(icon, color: color ?? Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
