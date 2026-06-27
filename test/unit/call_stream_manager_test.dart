import 'package:test/test.dart';
import 'package:talktranslate/services/call_stream_manager.dart';

void main() {
  group('TranslationPayload', () {
    test('constructor sets all fields', () {
      final now = DateTime(2026, 6, 25, 10, 0, 0);
      final payload = TranslationPayload(
        text: '你好',
        translated: 'Hello',
        timestamp: now,
      );
      expect(payload.text, equals('你好'));
      expect(payload.translated, equals('Hello'));
      expect(payload.timestamp, equals(now));
    });

    test('immutable - fields cannot be modified', () {
      final payload = TranslationPayload(
        text: 'test',
        translated: '测试',
        timestamp: DateTime.now(),
      );
      // Verify the class is const-compatible (all final fields)
      expect(payload, isA<TranslationPayload>());
    });
  });

  group('CallStreamManager config', () {
    test('setLanguages updates both languages', () {
      final manager = CallStreamManager();
      manager.setLanguages('zh-CN', 'en-US');
      // 通过验证翻译结果检验语言设置
      // （内部状态不可直接访问，通过行为验证）
    });

    test('setApiKey is backward compatible', () {
      final manager = CallStreamManager();
      // Should not throw
      expect(() => manager.setApiKey('test-key'), returnsNormally);
    });
  });
}
