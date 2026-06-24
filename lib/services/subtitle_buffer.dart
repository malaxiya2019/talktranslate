/// 翻译字幕环形缓存 — 用于断线重连后快速恢复字幕显示
///
/// 职责：
///   1. 缓存最近 N 条翻译字幕条目
///   2. 会话恢复时一次性回放缓存，避免冷启动空白期
///   3. 通话正常结束后自动清空
///
/// 验收标准：断线重连后 5 秒内通过缓存的 SubtitleBuffer 恢复冷启动通话字幕
class CallSubtitleBuffer {
  static const int _maxSize = 30;

  final List<SubtitleEntry> _buffer = [];
  int _writeIndex = 0;
  bool _populated = false;

  /// 写入新字幕条目
  void push(SubtitleEntry entry) {
    if (_buffer.length < _maxSize) {
      _buffer.add(entry);
    } else {
      _buffer[_writeIndex % _maxSize] = entry;
    }
    _writeIndex++;
    _populated = true;
  }

  /// 获取缓存的所有字幕（按时间正序）
  List<SubtitleEntry> drain() {
    if (!_populated || _buffer.isEmpty) return const [];

    if (_buffer.length < _maxSize) {
      return List.from(_buffer);
    }

    // 环形缓存：从 writeIndex 开始取一圈
    final result = <SubtitleEntry>[];
    for (int i = 0; i < _maxSize; i++) {
      result.add(_buffer[(_writeIndex + i) % _maxSize]);
    }
    return result;
  }

  /// 清空缓存（通话正常结束时）
  void clear() {
    _buffer.clear();
    _writeIndex = 0;
    _populated = false;
  }

  /// 是否包含有效缓存
  bool get hasData => _populated && _buffer.isNotEmpty;

  /// 缓存条目数
  int get count => _populated ? _buffer.length : 0;
}

/// 单条字幕条目
class SubtitleEntry {
  final String text;
  final String translated;
  final DateTime timestamp;
  final bool isLocal; // true=本端语音, false=对端语音

  const SubtitleEntry({
    required this.text,
    required this.translated,
    required this.timestamp,
    this.isLocal = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'translated': translated,
    'timestamp': timestamp.toIso8601String(),
    'isLocal': isLocal,
  };

  factory SubtitleEntry.fromJson(Map<String, dynamic> json) => SubtitleEntry(
    text: json['text'] as String? ?? '',
    translated: json['translated'] as String? ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
        DateTime.now(),
    isLocal: json['isLocal'] as bool? ?? false,
  );
}
