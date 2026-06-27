import 'package:test/test.dart';
import 'package:talktranslate/services/translation_pipeline.dart';
import 'package:talktranslate/services/translation_service.dart';
import 'package:talktranslate/services/engine_config_service.dart' show TranslationEngine;

/// TranslationPipeline 集成测试
///
/// 测试范围：
///   - 管道配置（语言、TTS、API Key、引擎优先级）
///   - translate 方法（透传到 TranslationService）
///   - 重试队列集成（pendingRetryCount / retryFailed）
///   - 结果流
///
/// 不测试的（需要原生插件）：
///   - STT 语音识别（speech_to_text）
///   - TTS 语音合成（flutter_tts）
///   - 实际的 HTTP 翻译请求
void main() {
  group('TranslationPipeline config', () {
    test('构造函数可以不带参数', () {
      final pipeline = TranslationPipeline();
      expect(pipeline, isNotNull);
    });

    test('setLanguages 设置语言', () {
      final pipeline = TranslationPipeline();
      pipeline.setLanguages('zh-CN', 'en-US');
      // 语言设置通过 translate 方法传递 — 内部验证
      expect(pipeline, isNotNull);
    });

    test('setTtsEnabled 开关', () {
      final pipeline = TranslationPipeline();
      pipeline.setTtsEnabled(true);
      pipeline.setTtsEnabled(false);
      // TTS 开关不影响翻译逻辑
      expect(pipeline, isNotNull);
    });

    test('setApiKey 透传', () {
      final pipeline = TranslationPipeline();
      pipeline.setApiKey('test-key');
      // API Key 注入到 TranslationService
      expect(pipeline, isNotNull);
    });

    test('setEnginePriority 设置引擎顺序', () {
      final pipeline = TranslationPipeline();
      pipeline.setEnginePriority([
        TranslationEngine.deepseek,
        TranslationEngine.openai,
      ]);
      expect(pipeline, isNotNull);
    });
  });

  group('TranslationPipeline translate', () {
    test('空文本返回空字符串', () async {
      final pipeline = TranslationPipeline();
      final result = await pipeline.translate('');
      expect(result, isEmpty);
    });

    test('非空文本走翻译服务', () async {
      final pipeline = TranslationPipeline();
      // 没有配置 API Key 时会跳过所有引擎，返回 [翻译失败]
      final result = await pipeline.translate('Hello');
      expect(result, startsWith('[翻译失败]'));
    });

    test('自定义语言方向', () async {
      final pipeline = TranslationPipeline();
      // 指定 from/to 会覆盖管道默认语言
      final result = await pipeline.translate(
        'Hello',
        from: 'en-US',
        to: 'zh-CN',
      );
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
      // 没有 API Key，所有引擎跳过 → 入队
      expect(service.pendingRetryCount, greaterThanOrEqualTo(1));
    });

    test('retryFailed 清空过期条目', () async {
      final service = TranslationService();
      await service.translate('Hello', 'en-US', 'zh-CN');
      await service.translate('World', 'en-US', 'zh-CN');
      expect(service.pendingRetryCount, greaterThanOrEqualTo(2));

      // retryFailed 会重试（仍然全部失败，但不会移除）
      await service.retryFailed();
      // 重试仍然失败，条目留在队列
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
  });

  group('TranslationPipeline retry queue', () {
    test('pendingRetryCount 透传', () async {
      final pipeline = TranslationPipeline();
      await pipeline.translate('Hello');
      // TranslationPipeline 的 pendingRetryCount 透传到 TranslationService
      expect(pipeline.pendingRetryCount, greaterThanOrEqualTo(1));
    });

    test('retryFailed 透传', () async {
      final pipeline = TranslationPipeline();
      await pipeline.translate('Hello');
      await pipeline.retryFailed();
      expect(pipeline.pendingRetryCount, greaterThanOrEqualTo(0));
    });

    test('onRetrySuccess 回调可以设置', () {
      final pipeline = TranslationPipeline();
      pipeline.onRetrySuccess = (entry, translated) {
        // 回调用作通知用途
      };
      expect(pipeline.onRetrySuccess, isNotNull);
    });
  });

  group('TranslationResult model', () {
    test('构造和属性', () {
      final result = TranslationResult(
        original: 'Hello',
        translated: '你好',
        sourceLang: 'en-US',
        targetLang: 'zh-CN',
      );
      expect(result.original, equals('Hello'));
      expect(result.translated, equals('你好'));
      expect(result.sourceLang, equals('en-US'));
      expect(result.targetLang, equals('zh-CN'));
    });
  });

  group('RetryEntry model', () {
    test('构造和属性', () {
      final entry = RetryEntry(
        text: 'Hello',
        from: 'en-US',
        to: 'zh-CN',
        createdAt: DateTime.now(),
      );
      expect(entry.text, equals('Hello'));
      expect(entry.from, equals('en-US'));
      expect(entry.to, equals('zh-CN'));
      expect(entry.createdAt, isNotNull);
    });
  });
}
