import 'package:flutter/material.dart';

/// 翻译卡片 — 原文 + 译文上下排列
///
/// 用法：
/// ```dart
/// TranslationCard(
///   original: '今天天气不错',
///   translated: 'The weather is nice today',
/// )
/// ```
class TranslationCard extends StatelessWidget {
  final String original;
  final String translated;
  final double originalFontSize;
  final double translatedFontSize;

  const TranslationCard({
    super.key,
    required this.original,
    required this.translated,
    this.originalFontSize = 18,
    this.translatedFontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (original.isEmpty && translated.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (original.isNotEmpty) ...[
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              original,
              style: TextStyle(
                fontSize: originalFontSize,
                color: Colors.white60,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (translated.isNotEmpty)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 400),
            child: Text(
              translated,
              style: TextStyle(
                fontSize: translatedFontSize,
                color: Colors.greenAccent[100],
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
}
