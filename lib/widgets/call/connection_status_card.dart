import 'package:flutter/material.dart';
import '../../models/call.dart';

/// 连接状态卡片 — 带呼吸灯 + 状态文字
///
/// Connecting: 黄色呼吸脉冲
/// Connected:  绿色常亮 + 低延时提示
/// Reconnecting: 橙色闪烁
/// Failed:      红色常亮
///
/// 用法：
/// ```dart
/// ConnectionStatusCard(state: CallState.inCall, pingMs: 14)
/// ```
class ConnectionStatusCard extends StatefulWidget {
  final CallState state;
  final int? pingMs;

  const ConnectionStatusCard({
    super.key,
    required this.state,
    this.pingMs,
  });

  @override
  State<ConnectionStatusCard> createState() => _ConnectionStatusCardState();
}

class _ConnectionStatusCardState extends State<ConnectionStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (_shouldPulse) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ConnectionStatusCard old) {
    super.didUpdateWidget(old);
    if (widget.state != old.state) {
      if (_shouldPulse) {
        _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _shouldPulse =>
      widget.state == CallState.connecting ||
      widget.state == CallState.reconnecting;

  Color get _color {
    switch (widget.state) {
      case CallState.inCall: return Colors.green;
      case CallState.connecting: return Colors.orange;
      case CallState.ringing: return Colors.orange;
      case CallState.reconnecting: return Colors.orangeAccent;
      case CallState.failed: return Colors.red;
      case CallState.idle: return Colors.grey;
    }
  }

  String get _label {
    switch (widget.state) {
      case CallState.connecting: return '正在连接';
      case CallState.ringing: return '响铃中';
      case CallState.inCall: return '已连接';
      case CallState.reconnecting: return '重连中';
      case CallState.failed: return '连接断开';
      case CallState.idle: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 状态指示灯
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _color.withValues(
                  alpha: _shouldPulse ? 0.4 + 0.6 * _pulseCtrl.value : 0.9,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(
                      alpha: _shouldPulse ? 0.3 * _pulseCtrl.value : 0.2,
                    ),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _color,
            ),
          ),
          // Ping (仅通话中显示)
          if (widget.state == CallState.inCall && widget.pingMs != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${widget.pingMs}ms',
                style: TextStyle(
                  fontSize: 10,
                  color: _color.withValues(alpha: 0.8),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
