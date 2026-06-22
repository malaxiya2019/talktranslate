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
                // 状态栏
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Icon(status == CallStatus.connected ? Icons.mic : Icons.phone,
                        color: status == CallStatus.connected ? Colors.greenAccent : Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      status == CallStatus.calling ? '呼叫中' :
                      status == CallStatus.ringing ? '响铃' :
                      status == CallStatus.connected ? '通话中' : '',
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const Spacer(),
                    Text(p.peerPhone ?? '', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  ]),
                ),
                const Divider(color: Colors.white24),

                if (status == CallStatus.connected) ...[
                  // 对方说的话 (字幕)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [Icon(Icons.person_outline, size: 14, color: Colors.orange), SizedBox(width: 4),
                        Text('对方', style: TextStyle(color: Colors.orange, fontSize: 12))]),
                      const SizedBox(height: 6),
                      Text(p.subtitle.isEmpty ? '等待对方说话...' : p.subtitle,
                          style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500, height: 1.3)),
                    ]),
                  ),

                  // 我说的 (本地识别反馈)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [Icon(Icons.person, size: 14, color: Colors.blue), SizedBox(width: 4),
                        Text('我', style: TextStyle(color: Colors.blue, fontSize: 12))]),
                      const SizedBox(height: 6),
                      Text(p.mySpeech.isEmpty ? '请说话...' : p.mySpeech,
                          style: TextStyle(fontSize: 18, color: Colors.white70, height: 1.3)),
                    ]),
                  ),
                ] else ...[
                  const Spacer(),
                  const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
                  const SizedBox(height: 12),
                  Text(p.peerPhone ?? '', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    status == CallStatus.calling ? '正在呼叫...' :
                    status == CallStatus.ringing ? '响铃中...' : '',
                    style: const TextStyle(fontSize: 16, color: Colors.white70)),
                  const Spacer(),
                ],

                const Spacer(),

                // 控制按钮
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (status == CallStatus.calling || status == CallStatus.connected)
                    _Btn(Icons.call_end, Colors.red, '挂断', () { p.hangup(); Navigator.pop(context); }),
                  if (status == CallStatus.ringing) ...[
                    _Btn(Icons.call, Colors.green, '接听', () => p.accept()),
                    const SizedBox(width: 48),
                    _Btn(Icons.call_end, Colors.red, '拒接', () { p.reject(); Navigator.pop(context); }),
                  ],
                ]),
                const SizedBox(height: 32),
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
