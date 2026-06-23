import 'package:flutter/material.dart';

/// 说话人标识
enum Speaker { me, peer }

/// 对话气泡 — 原文展示
///
/// 用法：
/// ```dart
/// MessageBubble(
///   speaker: Speaker.peer,
///   text: '你好，今天天气不错',
///   color: Colors.orangeAccent,
/// )
/// ```
class MessageBubble extends StatelessWidget {
  final Speaker speaker;
  final String text;
  final Color color;
  final double fontSize;

  const MessageBubble({
    super.key,
    required this.speaker,
    required this.text,
    required this.color,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              speaker == Speaker.peer ? Icons.person_outline : Icons.person,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              speaker == Speaker.peer ? '对方' : '我',
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: text.isEmpty ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: speaker == Speaker.peer
                  ? (text.length > 30 ? 20 : 24)
                  : 18,
              color: speaker == Speaker.peer ? Colors.white : Colors.white60,
              fontWeight: speaker == Speaker.peer ? FontWeight.w500 : null,
              height: 1.4,
            ),
            child: Text(
              text.isEmpty
                  ? (speaker == Speaker.peer ? '等待对方说话...' : '请说话...')
                  : text,
            ),
          ),
        ),
      ],
    );
  }
}
