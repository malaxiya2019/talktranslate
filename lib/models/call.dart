/// 通话状态机
///
/// 合法迁移：
///   idle ──→ connecting ──→ inCall ──→ reconnecting ─┬─→ inCall
///    │          │              │                       └─→ failed
///    │          │              └──→ idle (挂断)
///    │          └──→ failed (超时/拒接)
///    └──→ ringing ──→ inCall (接听)
///                   └──→ idle (拒接/取消)
///   failed ──→ idle (重置)
enum CallState {
  idle,
  connecting,
  ringing,
  inCall,
  reconnecting,
  failed;

  static const _transitions = {
    CallState.idle: {CallState.connecting, CallState.ringing},
    CallState.connecting: {CallState.inCall, CallState.failed, CallState.idle},
    CallState.ringing: {CallState.inCall, CallState.idle},
    CallState.inCall: {CallState.reconnecting, CallState.idle},
    CallState.reconnecting: {CallState.inCall, CallState.failed},
    CallState.failed: {CallState.idle},
  };

  /// 是否能合法迁移到 [target]
  bool canTransitionTo(CallState target) {
    return _transitions[this]?.contains(target) ?? false;
  }
}

/// 通话记录
class CallRecord {
  final String id;
  final String peerName;
  final DateTime startTime;
  final int durationSeconds;
  final String? lastTranscript;

  const CallRecord({
    required this.id,
    required this.peerName,
    required this.startTime,
    required this.durationSeconds,
    this.lastTranscript,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json) => CallRecord(
    id: json['id'] as String,
    peerName: json['peer'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    durationSeconds: json['duration'] as int,
    lastTranscript: json['transcript'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'peer': peerName,
    'startTime': startTime.toIso8601String(),
    'duration': durationSeconds,
    'transcript': lastTranscript,
  };
}

/// 当前通话会话
class CallSession {
  final String peerName;
  final String callId;
  final DateTime startedAt;

  const CallSession({
    required this.peerName,
    required this.callId,
    required this.startedAt,
  });
}

/// 通话状态快照 — 用于断线恢复
class CallSnapshot {
  final String sessionId;
  final CallState state;
  final String peerId;
  final DateTime timestamp;

  const CallSnapshot({
    required this.sessionId,
    required this.state,
    required this.peerId,
    required this.timestamp,
  });

  factory CallSnapshot.fromJson(Map<String, dynamic> json) => CallSnapshot(
    sessionId: json['sessionId'] as String,
    state: CallState.values.firstWhere(
      (s) => s.name == json['state'],
      orElse: () => CallState.idle,
    ),
    peerId: json['peerId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'state': state.name,
    'peerId': peerId,
    'timestamp': timestamp.toIso8601String(),
  };

  /// 快照是否仍在有效期内（5分钟）
  bool get isValid => DateTime.now().difference(timestamp).inMinutes < 5;
}
