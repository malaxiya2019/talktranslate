/// 通话状态模型
enum CallStatus {
  idle,           // 空闲
  calling,        // 拨出中
  ringing,        // 响铃中
  connected,      // 已连接
  ended,          // 已结束
}

/// 通话记录
class CallRecord {
  final String id;
  final String peerId;
  final String peerName;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration duration;
  final String myLanguage;
  final String peerLanguage;

  CallRecord({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.duration,
    required this.myLanguage,
    required this.peerLanguage,
  });

  String get formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
