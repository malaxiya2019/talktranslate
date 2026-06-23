import 'package:flutter/material.dart';

/// 通话计时器 — 纯展示组件
///
/// 接收 elapsed（秒数），自动格式化为 MM:SS。
/// 计时逻辑由父级控制（Timer 或状态机驱动）。
///
/// 用法：
/// ```dart
/// CallTimer(elapsed: 125)  // 显示 "02:05"
/// ```
class CallTimer extends StatelessWidget {
  final int elapsed;

  const CallTimer({super.key, this.elapsed = 0});

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(elapsed),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 13,
        fontFamily: 'monospace',
      ),
    );
  }

  String _format(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }
}
