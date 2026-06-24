import 'package:flutter/material.dart';
import '../../models/call.dart';

/// 通话状态标签 — 显示当前通话阶段
///
/// 用法：
/// ```dart
/// CallStatusChip(state: CallState.inCall)
/// ```
class CallStatusChip extends StatelessWidget {
  final CallState state;

  const CallStatusChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(_label, style: TextStyle(fontSize: 11, color: _color)),
        ],
      ),
    );
  }

  Color get _color {
    switch (state) {
      case CallState.inCall:
        return Colors.greenAccent;
      case CallState.connecting:
        return Colors.orange;
      case CallState.ringing:
        return Colors.orange;
      case CallState.reconnecting:
        return Colors.orangeAccent;
      case CallState.failed:
        return Colors.red;
      case CallState.idle:
        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (state) {
      case CallState.inCall:
        return Icons.mic;
      case CallState.connecting:
      case CallState.ringing:
        return Icons.phone;
      case CallState.reconnecting:
        return Icons.wifi_off;
      case CallState.failed:
        return Icons.error_outline;
      case CallState.idle:
        return Icons.phone;
    }
  }

  String get _label {
    switch (state) {
      case CallState.connecting:
        return '呼叫中';
      case CallState.ringing:
        return '响铃中';
      case CallState.inCall:
        return '通话中';
      case CallState.reconnecting:
        return '重连中';
      case CallState.failed:
        return '通话失败';
      case CallState.idle:
        return '';
    }
  }
}
