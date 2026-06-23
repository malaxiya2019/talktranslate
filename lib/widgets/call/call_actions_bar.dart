import 'package:flutter/material.dart';

/// 通话操作按钮
class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final double size;
  final VoidCallback? onTap;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    this.size = 44,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: size * 0.45),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

/// 通话控制按钮类型
enum ActionType {
  mute,
  speaker,
  hangup,
  minimize,
  answer,
  reject,
}

/// 通话底部操作栏
///
/// 用法：
/// ```dart
/// CallActionsBar(
///   muted: false,
///   speakerOn: false,
///   onAction: (type) => handleAction(type),
/// )
/// ```
class CallActionsBar extends StatelessWidget {
  final bool muted;
  final bool speakerOn;
  final void Function(ActionType type)? onAction;

  /// 响铃模式 (仅显示接听/拒接)
  final bool ringingMode;

  const CallActionsBar({
    super.key,
    this.muted = false,
    this.speakerOn = false,
    this.onAction,
    this.ringingMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ringingMode ? _ringingButtons : _inCallButtons,
      ),
    );
  }

  List<Widget> get _inCallButtons => [
        _CallActionButton(
          icon: Icons.minimize,
          color: Colors.blue,
          label: '最小化',
          onTap: () => onAction?.call(ActionType.minimize),
        ),
        _CallActionButton(
          icon: muted ? Icons.mic_off : Icons.mic,
          color: muted ? Colors.red : Colors.white38,
          label: '静音',
          onTap: () => onAction?.call(ActionType.mute),
        ),
        _CallActionButton(
          icon: Icons.call_end,
          color: Colors.red,
          label: '挂断',
          size: 52,
          onTap: () => onAction?.call(ActionType.hangup),
        ),
        _CallActionButton(
          icon: speakerOn ? Icons.volume_up : Icons.hearing,
          color: speakerOn ? Colors.blue : Colors.white38,
          label: '扬声器',
          onTap: () => onAction?.call(ActionType.speaker),
        ),
      ];

  List<Widget> get _ringingButtons => [
        _CallActionButton(
          icon: Icons.call,
          color: Colors.green,
          label: '接听',
          size: 52,
          onTap: () => onAction?.call(ActionType.answer),
        ),
        const SizedBox(width: 48),
        _CallActionButton(
          icon: Icons.call_end,
          color: Colors.red,
          label: '拒接',
          size: 52,
          onTap: () => onAction?.call(ActionType.reject),
        ),
      ];
}
