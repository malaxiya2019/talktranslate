import 'package:flutter/material.dart';
import '../../models/call.dart';
import 'subtitle_view.dart';
import 'state_indicator.dart';
import 'audio_wave.dart';

/// 悬浮窗面板 — 带状态指示 + 波形动画
///
/// 分层结构：
///   Header: StateIndicator + 对方名
///   Body:   SubtitleView + AudioWave
///   Footer: 打开 · 挂断
class FloatingPanel extends StatelessWidget {
  final String peerName;
  final String subtitle;
  final String translated;
  final CallState state;
  final bool expanded;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onOpen;
  final VoidCallback? onHangup;

  const FloatingPanel({
    super.key,
    required this.peerName,
    this.subtitle = '',
    this.translated = '',
    this.state = CallState.inCall,
    this.expanded = false,
    this.onTap,
    this.onLongPress,
    this.onOpen,
    this.onHangup,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 12,
          top: MediaQuery.of(context).padding.top + 40,
          child: GestureDetector(
            onTap: expanded ? null : onTap,
            onLongPress: onLongPress,
            child: expanded ? _buildExpanded() : _buildBubble(),
          ),
        ),
      ],
    );
  }

  // ── 折叠态：气泡 + 微型状态点 ──

  Widget _buildBubble() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 首字母
          Text(
            peerName.length >= 2
                ? peerName.substring(peerName.length - 2)
                : peerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // 状态小点 + 波形
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(state),
              if (state == CallState.inCall) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 24,
                  height: 10,
                  child: AudioWave(
                    active: true,
                    barColor: Colors.greenAccent,
                    barCount: 3,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(CallState s) {
    Color c;
    switch (s) {
      case CallState.inCall:
        c = Colors.greenAccent;
        break;
      case CallState.connecting:
      case CallState.ringing:
        c = Colors.orange;
        break;
      case CallState.reconnecting:
        c = Colors.orangeAccent;
        break;
      case CallState.failed:
        c = Colors.red;
        break;
      case CallState.idle:
        c = Colors.grey;
        break;
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }

  // ── 展开态：完整面板 ──

  Widget _buildExpanded() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              StateIndicator(state: state),
              const Spacer(),
              Text(
                peerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Body: 字幕 + 波形 ──
          SubtitleView(subtitle: subtitle, translated: translated),
          const SizedBox(height: 8),
          if (state == CallState.inCall)
            AudioWave(active: true, barColor: Colors.greenAccent, barCount: 5),
          if (state == CallState.reconnecting)
            Text(
              '正在恢复连接...',
              style: TextStyle(color: Colors.orangeAccent[200], fontSize: 11),
            ),
          if (state == CallState.failed)
            Text(
              '通话已断开',
              style: TextStyle(color: Colors.red[300], fontSize: 11),
            ),
          const SizedBox(height: 12),

          // ── Footer: 控制微栏 ──
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_full, size: 14),
                    label: const Text('打开', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: onHangup,
                    icon: const Icon(Icons.call_end, size: 14),
                    label: const Text('挂断', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
