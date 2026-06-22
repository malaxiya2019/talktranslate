import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call.dart';
import '../providers/app_provider.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          final status = p.callStatus;
          return SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                // 对方信息
                const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
                const SizedBox(height: 12),
                Text(p.peerPhone ?? '', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  status == CallStatus.calling ? '正在呼叫...' :
                  status == CallStatus.ringing ? '响铃中...' :
                  status == CallStatus.connected ? '通话中' : '',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const Spacer(),

                // 通话中显示对方的远程视频 (这里只显示音频指示器)
                if (status == CallStatus.connected)
                  Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Column(children: [
                      Icon(Icons.mic, size: 48, color: Colors.green),
                      SizedBox(height: 8),
                      Text('音频通话中', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ]),
                  ),

                const Spacer(flex: 2),

                // 控制按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (status == CallStatus.calling || status == CallStatus.connected)
                      _Btn(Icons.call_end, Colors.red, '挂断', () { p.hangup(); Navigator.pop(context); }),
                    if (status == CallStatus.ringing) ...[
                      _Btn(Icons.call, Colors.green, '接听', () => p.accept()),
                      const SizedBox(width: 48),
                      _Btn(Icons.call_end, Colors.red, '拒接', () { p.reject(); Navigator.pop(context); }),
                    ],
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon; final Color color; final String label; final VoidCallback onTap;
  const _Btn(this.icon, this.color, this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(radius: 28, backgroundColor: color, child: IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}
