import 'package:flutter/material.dart';

/// 用户头像 — 首字母 + 在线状态圆点
///
/// 用法：
/// ```dart
/// Avatar(
///   name: '+8613800138000',
///   size: 40,
///   online: true,
/// )
/// ```
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final bool online;
  final Color? backgroundColor;

  const Avatar({
    super.key,
    required this.name,
    this.size = 40,
    this.online = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: (backgroundColor ?? Colors.blue).withValues(alpha: 0.1),
            child: Text(
              _initials,
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
                color: (backgroundColor ?? Colors.blue).withValues(alpha: 0.8),
              ),
            ),
          ),
          if (online)
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.length <= 2) return trimmed;
    return trimmed.substring(trimmed.length - 2);
  }
}
