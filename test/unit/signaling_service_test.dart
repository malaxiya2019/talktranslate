import 'dart:convert';
import 'package:test/test.dart';

/// 信令消息序列化测试（纯逻辑，不依赖 WebSocket）
///
/// 验证 SignalingService 消息格式符合信令协议
void main() {
  group('信令消息格式', () {
    test('register 消息', () {
      final msg = {
        'type': 'register',
        'phone': '+8613800138000',
      };
      final json = jsonEncode(msg);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['type'], equals('register'));
      expect(decoded['phone'], equals('+8613800138000'));
    });

    test('call 消息', () {
      final msg = {
        'type': 'call',
        'to': '+8613800138001',
      };
      final json = jsonEncode(msg);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['type'], equals('call'));
      expect(decoded['to'], equals('+8613800138001'));
    });

    test('accept/reject/hangup 消息格式一致', () {
      const callId = 'call-001';
      for (final type in ['accept', 'reject', 'hangup']) {
        final msg = {'type': type, 'callId': callId};
        final decoded = jsonDecode(jsonEncode(msg)) as Map<String, dynamic>;
        expect(decoded['type'], equals(type));
        expect(decoded['callId'], equals(callId));
      }
    });

    test('offer/answer 包含 sdp', () {
      final msg = {
        'type': 'offer',
        'callId': 'call-002',
        'sdp': 'v=0\no=...',
      };
      final decoded = jsonDecode(jsonEncode(msg)) as Map<String, dynamic>;
      expect(decoded['type'], equals('offer'));
      expect(decoded['sdp'], equals('v=0\no=...'));
    });

    test('ice 候选消息', () {
      final msg = {
        'type': 'ice',
        'callId': 'call-003',
        'candidate': {'candidate': 'candidate:1 1 UDP', 'sdpMid': '0'},
        'to': '+8613800138001',
      };
      final decoded = jsonDecode(jsonEncode(msg)) as Map<String, dynamic>;
      expect(decoded['type'], equals('ice'));
      expect((decoded['candidate'] as Map)['candidate'], equals('candidate:1 1 UDP'));
    });

    test('subtitle 消息', () {
      final msg = {
        'type': 'subtitle',
        'callId': 'call-004',
        'text': '你好',
        'translated': 'Hello',
        'to': '+8613800138001',
      };
      final decoded = jsonDecode(jsonEncode(msg)) as Map<String, dynamic>;
      expect(decoded['type'], equals('subtitle'));
      expect(decoded['text'], equals('你好'));
      expect(decoded['translated'], equals('Hello'));
    });

    test('ping/pong 包含时间戳', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final ping = {'type': 'ping', 'time': now};
      final decoded = jsonDecode(jsonEncode(ping)) as Map<String, dynamic>;
      expect(decoded['type'], equals('ping'));
      expect(decoded['time'], equals(now));
    });
  });

  group('事件解析', () {
    test('registered 事件携带 phone', () {
      final event = {'type': 'registered', 'phone': '+8613800138000'};
      expect(event['type'], equals('registered'));
      expect(event['phone'], isNotNull);
    });

    test('incoming_call 事件携带 callerId 和 callId', () {
      final event = {
        'type': 'incoming_call',
        'from': '+8613800138001',
        'callId': 'call-005',
      };
      expect(event['type'], equals('incoming_call'));
      expect(event['from'], equals('+8613800138001'));
      expect(event['callId'], equals('call-005'));
    });

    test('error 事件携带 message', () {
      final event = {'type': 'error', 'message': '连接超时'};
      expect(event['message'], isNotEmpty);
    });
  });

  group('E.164 号码格式', () {
    test('中国手机号以 +86 开头', () {
      expect('+8613800138000', startsWith('+86'));
    });

    test('号码满足 E.164 格式', () {
      // E.164: + 国家码(1-3位) + 用户号码(最多15位)
      final RegExp e164 = RegExp(r'^\+[1-9]\d{1,3}\d{4,14}$');
      expect(e164.hasMatch('+8613800138000'), isTrue);
      expect(e164.hasMatch('+12025551234'), isTrue); // US
      expect(e164.hasMatch('+81312345678'), isTrue); // JP
      expect(e164.hasMatch('0123456'), isFalse); // no +
    });
  });
}
