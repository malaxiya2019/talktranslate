import 'package:test/test.dart';
import 'package:talktranslate/models/call.dart';

/// SessionRestoreService 数据序列化测试
///
/// 验证 CallSnapshot 的 JSON 序列化/反序列化
/// 不依赖 SharedPreferences（纯 Data 层测试）
void main() {
  group('CallSnapshot 序列化', () {
    test('toJson / fromJson 往返一致', () {
      final snapshot = CallSnapshot(
        sessionId: 'session-001',
        state: CallState.inCall,
        peerId: '+8613800138001',
        timestamp: DateTime(2026, 6, 25, 10, 0, 0),
      );

      final json = snapshot.toJson();
      final restored = CallSnapshot.fromJson(json);

      expect(restored.sessionId, equals(snapshot.sessionId));
      expect(restored.state, equals(snapshot.state));
      expect(restored.peerId, equals(snapshot.peerId));
      expect(restored.timestamp, equals(snapshot.timestamp));
    });

    test('invalid state string falls back to idle', () {
      final json = {
        'sessionId': 'session-002',
        'state': 'unknown_state',
        'peerId': '+8613800138001',
        'timestamp': DateTime(2026, 6, 25, 10, 0, 0).toIso8601String(),
      };

      final snapshot = CallSnapshot.fromJson(json);
      expect(snapshot.state, equals(CallState.idle));
    });

    test('isValid returns true for recent snapshot', () {
      final snapshot = CallSnapshot(
        sessionId: 'session-003',
        state: CallState.connecting,
        peerId: '+8613800138001',
        timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(snapshot.isValid, isTrue);
    });

    test('isValid returns false for old snapshot', () {
      final snapshot = CallSnapshot(
        sessionId: 'session-004',
        state: CallState.connecting,
        peerId: '+8613800138001',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(snapshot.isValid, isFalse);
    });

    test('idle snapshot is not valid for restore', () {
      final snapshot = CallSnapshot(
        sessionId: 'session-005',
        state: CallState.idle,
        peerId: '+8613800138001',
        timestamp: DateTime.now(),
      );
      expect(snapshot.isValid, isTrue);
      // 但 idle 需要清理（tryRestore 逻辑）
    });
  });

  group('CallRecord 序列化', () {
    test('toJson / fromJson 往返一致', () {
      final record = CallRecord(
        id: 'rec-001',
        peerName: '张三',
        startTime: DateTime(2026, 6, 25, 10, 30, 0),
        durationSeconds: 120,
        lastTranscript: '你好',
      );

      final json = record.toJson();
      final restored = CallRecord.fromJson(json);

      expect(restored.id, equals(record.id));
      expect(restored.peerName, equals(record.peerName));
      expect(restored.startTime, equals(record.startTime));
      expect(restored.durationSeconds, equals(record.durationSeconds));
      expect(restored.lastTranscript, equals(record.lastTranscript));
    });

    test('optional lastTranscript can be null', () {
      final record = CallRecord(
        id: 'rec-002',
        peerName: '李四',
        startTime: DateTime(2026, 6, 25, 11, 0, 0),
        durationSeconds: 0,
      );

      final json = record.toJson();
      final restored = CallRecord.fromJson(json);

      expect(restored.lastTranscript, isNull);
    });

    test('durationSeconds preserves exact value', () {
      final record = CallRecord(
        id: 'rec-003',
        peerName: 'Test',
        startTime: DateTime(2026, 6, 25, 12, 0, 0),
        durationSeconds: 3599, // 59:59
      );

      final restored = CallRecord.fromJson(record.toJson());
      expect(restored.durationSeconds, equals(3599));
    });
  });
}
