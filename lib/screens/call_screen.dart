import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call.dart';
import '../providers/app_provider.dart';

/// 通话页面 — 产品级
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  Timer? _timer;
  int _elapsed = 0;
  bool _muted = false;
  bool _speaker = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  String _fmtTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          final status = p.callStatus;
          if (status == CallStatus.connected && _timer == null) _startTimer();
          if (status == CallStatus.idle) {
            WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
          }

          return SafeArea(
            child: Column(
              children: [
                // 顶部栏
                _buildTopBar(p, status),
                const Divider(color: Colors.white12, height: 1),

                Expanded(child: _buildBody(p, status)),

                // 底部控制
                _buildControls(p, status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(AppProvider p, CallStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: status == CallStatus.connected ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                status == CallStatus.connected ? Icons.mic : Icons.phone,
                size: 12, color: status == CallStatus.connected ? Colors.greenAccent : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                status == CallStatus.calling ? '呼叫中' : status == CallStatus.ringing ? '响铃中' : status == CallStatus.connected ? '通话中' : '',
                style: TextStyle(fontSize: 11, color: status == CallStatus.connected ? Colors.greenAccent : Colors.orange),
              ),
            ]),
          ),
          const Spacer(),
          if (status == CallStatus.connected)
            Text(_fmtTime(_elapsed), style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildBody(AppProvider p, CallStatus status) {
    if (status == CallStatus.calling || status == CallStatus.ringing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white.withOpacity(0.05),
            child: Text(
              (p.peerPhone ?? '?').substring((p.peerPhone?.length ?? 1) - 2),
              style: const TextStyle(fontSize: 28, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),
          Text(p.peerPhone ?? '', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(status == CallStatus.calling ? '正在呼叫...' : '响铃中...',
              style: const TextStyle(fontSize: 15, color: Colors.white38)),
        ],
      );
    }

    // ── 通话中: 核心翻译界面 ──
    return Column(
      children: [
        // 对方信息 + 语言对
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🇨🇳 中文', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.swap_horiz, color: Colors.grey[600], size: 18),
            ),
            Text('🇺🇸 English', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Text(p.peerPhone ?? '', style: const TextStyle(fontSize: 16, color: Colors.white54)),
        const SizedBox(height: 16),

        // 对方字幕
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.orangeAccent),
                  const SizedBox(width: 6),
                  Text('对方', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                ]),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.subtitle.isEmpty ? '等待对方说话...' : p.subtitle,
                          style: TextStyle(
                            fontSize: p.subtitle.length > 30 ? 20 : 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        if (p.subtitleTranslated.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            p.subtitleTranslated,
                            style: TextStyle(
                              fontSize: p.subtitleTranslated.length > 30 ? 18 : 22,
                              color: Colors.greenAccent[100],
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 我的字幕
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.person, size: 14, color: Colors.blue[300]),
                  const SizedBox(width: 6),
                  Text('我', style: TextStyle(color: Colors.blue[300], fontSize: 12)),
                ]),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.mySpeech.isEmpty ? '请说话...' : p.mySpeech,
                          style: TextStyle(fontSize: 18, color: Colors.white60, height: 1.4),
                        ),
                        if (p.mySpeechTranslated.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            p.mySpeechTranslated,
                            style: TextStyle(fontSize: 16, color: Colors.greenAccent[100]?.withOpacity(0.7), height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildControls(AppProvider p, CallStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (status == CallStatus.calling || status == CallStatus.connected) ...[
            // 静音
            _CtrlBtn(
              icon: _muted ? Icons.mic_off : Icons.mic,
              color: _muted ? Colors.red : Colors.white38,
              label: '静音',
              onTap: () => setState(() => _muted = !_muted),
            ),

            // 挂断
            _CtrlBtn(
              icon: Icons.call_end,
              color: Colors.red,
              label: '挂断',
              size: 52,
              onTap: () { p.hangup(); Navigator.pop(context); },
            ),

            // 扬声器
            _CtrlBtn(
              icon: _speaker ? Icons.volume_up : Icons.hearing,
              color: _speaker ? Colors.blue : Colors.white38,
              label: '扬声器',
              onTap: () => setState(() => _speaker = !_speaker),
            ),
          ],

          if (status == CallStatus.ringing) ...[
            _CtrlBtn(icon: Icons.call, color: Colors.green, label: '接听', size: 52, onTap: () => p.accept()),
            const SizedBox(width: 48),
            _CtrlBtn(icon: Icons.call_end, color: Colors.red, label: '拒接', size: 52, onTap: () { p.reject(); Navigator.pop(context); }),
          ],
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon; final Color color; final String label; final double size; final VoidCallback onTap;
  const _CtrlBtn({required this.icon, required this.color, required this.label, this.size = 44, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: size * 0.45),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }
}
