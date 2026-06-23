import 'package:flutter/material.dart';

/// 字幕展示组件 — 原文 + 译文
///
/// 用法：
/// ```dart
/// SubtitleView(
///   subtitle: '今天天气不错',
///   translated: 'The weather is nice',
///   emptyText: '等待对方说话...',
/// )
/// ```
class SubtitleView extends StatelessWidget {
  final String subtitle;
  final String translated;
  final String emptyText;

  const SubtitleView({
    super.key,
    required this.subtitle,
    required this.translated,
    this.emptyText = '等待对方说话...',
  });

  @override
  Widget build(BuildContext context) {
    if (subtitle.isEmpty && translated.isEmpty) {
      return Text(emptyText, style: TextStyle(color: Colors.grey[600], fontSize: 11));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (translated.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            translated,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
