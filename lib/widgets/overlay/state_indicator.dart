import 'package:flutter/material.dart';
import '../../models/call.dart';

/// 通话状态可视化指示器
///
/// 将 CallState 映射为视觉动效：
///   idle/connecting → 动态脉冲点
///   inCall → 绿色常亮 + 呼吸
///   reconnecting → 黄色闪烁
///   failed → 红色常亮
///
/// 用法：
/// ```dart
/// StateIndicator(state: CallState.inCall)
/// ```
class StateIndicator extends StatefulWidget {
  final CallState state;

  const StateIndicator({super.key, required this.state});

  @override
  State<StateIndicator> createState() => _StateIndicatorState();
}

class _StateIndicatorState extends State<StateIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (_shouldPulse) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StateIndicator old) {
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
      widget.state == CallState.inCall || widget.state == CallState.reconnecting;

  Color get _color {
    switch (widget.state) {
      case CallState.inCall:
        return Colors.greenAccent;
      case CallState.connecting:
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

  String get _label {
    switch (widget.state) {
      case CallState.connecting:
        return '连接中';
      case CallState.ringing:
        return '响铃中';
      case CallState.inCall:
        return '通话中';
      case CallState.reconnecting:
        return '重连中';
      case CallState.failed:
        return '已断开';
      case CallState.idle:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color.withOpacity(_pulseAnim.value),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _color.withOpacity(0.3 * _pulseAnim.value),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        if (_label.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(fontSize: 11, color: _color),
          ),
        ],
      ],
    );
  }
}
