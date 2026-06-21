import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/call_service.dart';

/// 通话屏幕
class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final state = provider.callState;
          return SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                // 通话状态
                Text(
                  state == CallState.calling ? '正在呼叫...' :
                  state == CallState.ringing ? '响铃中...' :
                  state == CallState.connected ? '通话中' :
                  state == CallState.ended ? '已结束' : '',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '${provider.peerLanguage.flag} ${provider.peerLanguage.nativeName}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),

                // 翻译面板 (通话中显示)
                if (state == CallState.connected) _buildTranslationPanel(provider),

                const Spacer(flex: 2),

                // 控制按钮
                _buildControls(context, provider, state),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranslationPanel(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('你说的', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text(provider.originalText.isEmpty ? '等待语音...' : provider.originalText,
                    style: TextStyle(fontSize: 16, color: provider.originalText.isEmpty ? Colors.grey[400] : Colors.black87)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(provider.peerLanguage.nativeName, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text(provider.translatedText.isEmpty ? '翻译中...' : provider.translatedText,
                    style: TextStyle(fontSize: 16, color: provider.translatedText.isEmpty ? Colors.grey[400] : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, AppProvider provider, CallState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 挂断/拒接
        if (state == CallState.calling || state == CallState.connected)
          _ControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            label: '挂断',
            onPressed: () {
              provider.endCall();
              Navigator.pop(context);
            },
          ),
        if (state == CallState.ringing) ...[
          _ControlButton(
            icon: Icons.call,
            color: Colors.green,
            label: '接听',
            onPressed: () => provider.acceptIncomingCall(),
          ),
          const SizedBox(width: 40),
          _ControlButton(
            icon: Icons.call_end,
            color: Colors.red,
            label: '拒接',
            onPressed: () {
              provider.rejectIncomingCall();
              Navigator.pop(context);
            },
          ),
        ],
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.color, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
