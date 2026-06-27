import 'package:test/test.dart';
import 'package:talktranslate/services/translation_service.dart';

/// TranslationPipeline 逻辑测试（仅纯 Dart，不依赖 Flutter 插件）
///
/// TranslationPipeline 构造函数依赖 FlutterTts（原生插件），
/// 无法在测试环境直接实例化，这里测试其核心依赖 TranslationService。
void main() {
  group('TranslationService translate', () {
    test('空文本返回空字符串', () async {
      final service = TranslationService();
      final result = await service.translate('', 'en-US', 'zh-CN');
      expect(result, isEmpty);
    });

    test('非空文本无 API Key 时返回 [翻译失败]', () async {
      final service = TranslationService();
      final result = await service.translate('Hello', 'en-US', 'zh-CN');
      expect(result, startsWith('[翻译失败]'));
    });

    test('自定义语言方向', () async {
      final service = TranslationService();
      final result = await service.translate('Bonjour', 'fr-FR', 'en-US');
      expect(result, startsWith('[翻译失败]'));
    });
  });

  group('TranslationService retry queue', () {
    test('创建 TranslationService 时重试队列为空', () {
      final service = TranslationService();
      expect(service.pendingRetryCount, equals(0));
    });

    test('翻译失败后自动入队', () async {
      final service = TranslationService();
      await service.translate('Hello', 'en-US', 'zh-CN');
      expect(service.pendingRetryCount, greaterThanOrEqualTo(1));
    });

    test('retryFailed 尝试重试失败条目', () async {
      final service = TranslationService();
      await service.translate('Hello', 'en-US', 'zh-CN');
      await service.retryFailed();
      // 所有引擎都失败，条目保留
      expect(service.pendingRetryCount, greaterThan(0));
    });

    test('clearRetryQueue 清空队列', () async {
      final service = TranslationService();
      await service.translate('Hello', 'en-US', 'zh-CN');
      expect(service.pendingRetryCount, greaterThan(0));
      service.clearRetryQueue();
      expect(service.pendingRetryCount, equals(0));
    });

    test('多次翻译失败各自独立入队', () async {
      final service = TranslationService();
      await service.translate('A', 'en-US', 'zh-CN');
      await service.translate('B', 'en-US', 'zh-CN');
      await service.translate('C', 'en-US', 'zh-CN');
      expect(service.pendingRetryCount, greaterThanOrEqualTo(3));
    });

    test('onRetrySuccess 回调', () async {
      final service = TranslationService();
      String? capturedText;
      service.onRetrySuccess = (entry, translated) {
        capturedText = entry.text;
      };
      await service.translate('Hello', 'en-US', 'zh-CN');
      await service.retryFailed();
      expect(capturedText, isNull); // 全部失败，回调不被触发
    });
  });

  group('RetryEntry model', () {
    test('构造和属性', () {
      final now = DateTime.now();
      final entry = RetryEntry(
        text: 'Hello',
        from: 'en-US',
        to: 'zh-CN',
        createdAt: now,
      );
      expect(entry.text, equals('Hello'));
      expect(entry.from, equals('en-US'));
      expect(entry.to, equals('zh-CN'));
      expect(entry.createdAt, equals(now));
    });
  });


}
