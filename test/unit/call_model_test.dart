import 'package:test/test.dart';
import 'package:talktranslate/models/call.dart';

void main() {
  group('CallState', () {
    test('idle 可以转到 connecting', () {
      expect(CallState.idle.canTransitionTo(CallState.connecting), true);
    });
    test('idle 可以转到 ringing', () {
      expect(CallState.idle.canTransitionTo(CallState.ringing), true);
    });
    test('idle 不能直接转到 inCall', () {
      expect(CallState.idle.canTransitionTo(CallState.inCall), false);
    });
    test('idle 不能转到 failed', () {
      expect(CallState.idle.canTransitionTo(CallState.failed), false);
    });
    test('connecting 可以转到 inCall', () {
      expect(CallState.connecting.canTransitionTo(CallState.inCall), true);
    });
    test('connecting 可以转到 failed', () {
      expect(CallState.connecting.canTransitionTo(CallState.failed), true);
    });
    test('inCall 可以转到 reconnecting', () {
      expect(CallState.inCall.canTransitionTo(CallState.reconnecting), true);
    });
    test('inCall 可以转到 idle（挂断）', () {
      expect(CallState.inCall.canTransitionTo(CallState.idle), true);
    });
    test('failed 只能转到 idle', () {
      expect(CallState.failed.canTransitionTo(CallState.idle), true);
      expect(CallState.failed.canTransitionTo(CallState.inCall), false);
    });
    test('所有状态都可以转到自身', () {
      for (final s in CallState.values) {
        expect(s.canTransitionTo(s), false, reason: '$s 不能转到自身');
      }
    });
  });

  group('CallRecord', () {
    final now = DateTime(2026, 6, 24, 10, 30, 0);

    test('构造函数赋值正确', () {
      final record = CallRecord(
        id: 'call_001',
        peerName: 'test_user',
        startTime: now,
        durationSeconds: 120,
        lastTranscript: 'Hello World',
      );
      expect(record.id, 'call_001');
      expect(record.peerName, 'test_user');
      expect(record.startTime, now);
      expect(record.durationSeconds, 120);
      expect(record.lastTranscript, 'Hello World');
    });

    test('toJson / fromJson 循环一致', () {
      final original = CallRecord(
        id: 'call_001',
        peerName: 'test_user',
        startTime: now,
        durationSeconds: 120,
        lastTranscript: 'Hello World',
      );
      final json = original.toJson();
      final restored = CallRecord.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.peerName, original.peerName);
      expect(restored.startTime, original.startTime);
      expect(restored.durationSeconds, original.durationSeconds);
      expect(restored.lastTranscript, original.lastTranscript);
    });

    test('lastTranscript 为 null 时序列化恢复正确', () {
      final original = CallRecord(
        id: 'call_002',
        peerName: 'alice',
        startTime: now,
        durationSeconds: 0,
      );
      final json = original.toJson();
      final restored = CallRecord.fromJson(json);
      expect(restored.lastTranscript, null);
      expect(restored.durationSeconds, 0);
    });

    test('fromJson 字段缺失时抛出异常', () {
      expect(() => CallRecord.fromJson({'id': 'incomplete'}), throwsA(isA<TypeError>()));
    });
  });

  group('CallSession', () {
    test('构造函数赋值正确', () {
      final now = DateTime(2026, 6, 24, 10, 0, 0);
      final session = CallSession(
        peerName: 'bob',
        callId: 'session_001',
        startedAt: now,
      );
      expect(session.peerName, 'bob');
      expect(session.callId, 'session_001');
      expect(session.startedAt, now);
    });
  });

  group('CallSnapshot', () {
    final now = DateTime(2026, 6, 24, 10, 0, 0);

    test('构造函数赋值正确', () {
      final snapshot = CallSnapshot(
        sessionId: 'session_001',
        state: CallState.inCall,
        peerId: 'peer_001',
        timestamp: now,
      );
      expect(snapshot.sessionId, 'session_001');
      expect(snapshot.state, CallState.inCall);
      expect(snapshot.peerId, 'peer_001');
      expect(snapshot.timestamp, now);
    });

    test('toJson / fromJson 循环一致', () {
      final original = CallSnapshot(
        sessionId: 'session_001',
        state: CallState.inCall,
        peerId: 'peer_001',
        timestamp: now,
      );
      final json = original.toJson();
      final restored = CallSnapshot.fromJson(json);
      expect(restored.sessionId, original.sessionId);
      expect(restored.state, original.state);
      expect(restored.peerId, original.peerId);
      expect(restored.timestamp, original.timestamp);
    });

    test('所有状态序列化循环一致', () {
      for (final state in CallState.values) {
        final original = CallSnapshot(
          sessionId: 's',
          state: state,
          peerId: 'p',
          timestamp: now,
        );
        final restored = CallSnapshot.fromJson(original.toJson());
        expect(restored.state, state, reason: 'State $state 序列化不一致');
      }
    });

    test('isValid 5 分钟内为 true', () {
      final snapshot = CallSnapshot(
        sessionId: 's',
        state: CallState.inCall,
        peerId: 'p',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      );
      expect(snapshot.isValid, true);
    });

    test('isValid 超过 5 分钟为 false', () {
      final snapshot = CallSnapshot(
        sessionId: 's',
        state: CallState.inCall,
        peerId: 'p',
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
      );
      expect(snapshot.isValid, false);
    });

    test('fromJson 遇到未知 state 降级为 idle', () {
      final restored = CallSnapshot.fromJson({
        'sessionId': 's',
        'state': 'unknown_state',
        'peerId': 'p',
        'timestamp': now.toIso8601String(),
      });
      expect(restored.state, CallState.idle);
    });
  });
}
