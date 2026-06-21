import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/call.dart';

/// 通话屏幕 — 实时翻译界面
class CallScreen extends StatefulWidget {
  final String? peerId;
  const CallScreen({super.key, this.peerId});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final isConnected = provider.callStatus == CallStatus.connected;
          final isCalling = provider.callStatus == CallStatus.calling;

          return SafeArea(
            child: Column(
              children: [
                // 顶部状态栏
                _buildStatusBar(provider),

                const Divider(height: 1),

                // 翻译区域
                Expanded(
                  child: isConnected
                      ? _buildTranslationPanel(provider)
                      : _buildCallingPanel(provider, isCalling),
                ),

                // 底部控制栏
                _buildControlBar(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // 我的语言
          Text(provider.myLanguage!.flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text(provider.myLanguage!.nativeName, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Icon(Icons.wifi, size: 16, color: Colors.green[400]),
          const SizedBox(width: 4),
          Text(
            provider.callStatus == CallStatus.connected ? '通话中' : '连接中...',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          // 对方语言
          Text(provider.peerLanguage!.nativeName, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(provider.peerLanguage!.flag, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildTranslationPanel(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 我说
          Expanded(
            child: _TranslationBubble(
              label: '我说 (${provider.myLanguage!.nativeName})',
              flag: provider.myLanguage!.flag,
              text: provider.originalText,
              align: CrossAxisAlignment.start,
              color: Colors.blue[50]!,
            ),
          ),
          const SizedBox(height: 8),

          // 翻译中动画
          if (provider.originalText.isNotEmpty && provider.translatedText.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),

          // 翻译结果
          Expanded(
            child: _TranslationBubble(
              label: '翻译 (${provider.peerLanguage!.nativeName})',
              flag: provider.peerLanguage!.flag,
              text: provider.translatedText,
              align: CrossAxisAlignment.end,
              color: Colors.green[50]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallingPanel(AppProvider provider, bool isCalling) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCalling ? Icons.phone_in_talk : Icons.phone,
            size: 64,
            color: isCalling ? Colors.orange : Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            isCalling ? '正在呼叫...' : '准备通话',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.myLanguage!.flag} ${provider.myLanguage!.nativeName} → '
            '${provider.peerLanguage!.flag} ${provider.peerLanguage!.nativeName}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(AppProvider provider) {
    final isConnected = provider.callStatus == CallStatus.connected;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 麦克风
          _ControlButton(
            icon: Icons.mic,
            label: '静音',
            color: Colors.grey,
          ),
          // 结束通话
          _ControlButton(
            icon: Icons.call_end,
            label: '挂断',
            color: Colors.red,
            size: 48,
            onPressed: () {
              provider.endCall();
              Navigator.pop(context);
            },
          ),
          // 扬声器
          _ControlButton(
            icon: Icons.volume_up,
            label: '扬声器',
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 自动开始模拟通话 (演示)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      provider.startCall(widget.peerId ?? 'demo-peer');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// 翻译气泡
class _TranslationBubble extends StatelessWidget {
  final String label;
  final String flag;
  final String text;
  final CrossAxisAlignment align;
  final Color color;

  const _TranslationBubble({
    required this.label,
    required this.flag,
    required this.text,
    required this.align,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                text.isEmpty ? '等待语音...' : text,
                style: TextStyle(
                  fontSize: 20,
                  color: text.isEmpty ? Colors.grey[400] : Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 控制按钮
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    this.size = 40,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: size * 0.5),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
