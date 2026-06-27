import 'package:test/test.dart';
import 'package:talktranslate/services/translation_service.dart';
import 'package:talktranslate/services/engine_config_service.dart';
import 'package:talktranslate/models/language.dart';

void main() {
  group('LanguageUtil', () {
    test('langName returns correct English names for all supported languages', () {
      final cases = {
        'zh-CN': 'Chinese',
        'en-US': 'English',
        'ja-JP': 'Japanese',
        'ko-KR': 'Korean',
        'es-ES': 'Spanish',
        'fr-FR': 'French',
        'de-DE': 'German',
        'pt-BR': 'Portuguese',
        'ru-RU': 'Russian',
        'ar-SA': 'Arabic',
        'th-TH': 'Thai',
        'vi-VN': 'Vietnamese',
      };
      cases.forEach((code, expected) {
        expect(LanguageUtil.langName(code), equals(expected),
            reason: 'langName($code) should be $expected');
      });
    });

    test('langName falls back to English for unknown codes', () {
      expect(LanguageUtil.langName('unknown'), equals('English'));
      expect(LanguageUtil.langName(''), equals('English'));
      expect(LanguageUtil.langName('xx-XX'), equals('English'));
    });

    test('sttLocale returns correct codes for all languages', () {
      expect(LanguageUtil.sttLocale('zh-CN'), equals('zh_CN'));
      expect(LanguageUtil.sttLocale('en-US'), equals('en_US'));
      expect(LanguageUtil.sttLocale('ja-JP'), equals('ja_JP'));
      expect(LanguageUtil.sttLocale('ko-KR'), equals('ko_KR'));
      expect(LanguageUtil.sttLocale('th-TH'), equals('th_TH'));
      expect(LanguageUtil.sttLocale('vi-VN'), equals('vi_VN'));
    });

    test('sttLocale falls back to en_US', () {
      expect(LanguageUtil.sttLocale('unknown'), equals('en_US'));
    });

    test('ttsLocale returns correct codes', () {
      expect(LanguageUtil.ttsLocale('zh-CN'), equals('zh-CN'));
      expect(LanguageUtil.ttsLocale('en-US'), equals('en-US'));
      expect(LanguageUtil.ttsLocale('ja-JP'), equals('ja-JP'));
    });

    test('ttsLocale falls back for unsupported languages', () {
      expect(LanguageUtil.ttsLocale('th-TH'), equals('en-US'));
      expect(LanguageUtil.ttsLocale('ar-SA'), equals('en-US'));
    });
  });

  group('TranslationService', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService();
    });

    test('empty text returns empty string', () async {
      final result = await service.translate('', 'zh-CN', 'en-US');
      expect(result, isEmpty);
    });

    test('no engines configured returns error text', () async {
      service.setEnginePriority([]);
      final result = await service.translate('你好', 'zh-CN', 'en-US');
      expect(result, contains('[未配置翻译引擎]'));
    });

    test('default engine priority has DeepSeek first', () {
      final priority = service.enginePriority;
      expect(priority.isNotEmpty, isTrue);
      expect(priority.first, equals(TranslationEngine.deepseek));
    });

    test('setEnginePriority deduplicates engines', () {
      service.setEnginePriority([
        TranslationEngine.deepseek,
        TranslationEngine.openai,
        TranslationEngine.deepseek,
        TranslationEngine.claude,
        TranslationEngine.openai,
      ]);
      expect(service.enginePriority.length, equals(3));
      expect(service.enginePriority[0], TranslationEngine.deepseek);
      expect(service.enginePriority[1], TranslationEngine.openai);
      expect(service.enginePriority[2], TranslationEngine.claude);
    });

    test('setEnginePriority preserves order', () {
      service.setEnginePriority([
        TranslationEngine.baidu,
        TranslationEngine.deepl,
        TranslationEngine.openai,
      ]);
      expect(service.enginePriority[0], TranslationEngine.baidu);
      expect(service.enginePriority[1], TranslationEngine.deepl);
      expect(service.enginePriority[2], TranslationEngine.openai);
    });

    test('setApiKey saves to deepseek (backward compatible)', () async {
      service.setApiKey('sk-test-key-12345');
      final key = await EngineConfigService().getApiKey(TranslationEngine.deepseek);
      expect(key, equals('sk-test-key-12345'));
    });

    test('enginePriority getter returns unmodifiable list', () {
      final priority = service.enginePriority;
      expect(() => priority.add(TranslationEngine.system), throwsA(anything));
    });

    test('all 5 non-system engines are in default priority', () {
      final priority = service.enginePriority;
      expect(priority, contains(TranslationEngine.deepseek));
      expect(priority, contains(TranslationEngine.openai));
      expect(priority, contains(TranslationEngine.claude));
      expect(priority, contains(TranslationEngine.deepl));
      expect(priority, contains(TranslationEngine.baidu));
      expect(priority, isNot(contains(TranslationEngine.system)));
    });
  });

  group('TranslationEngine enum', () {
    test('deepseek name is correct', () {
      expect(TranslationEngine.deepseek.name, equals('deepseek'));
    });

    test('engine values are unique', () {
      final values = TranslationEngine.values;
      expect(values.toSet().length, equals(values.length));
    });

    test('index mapping is stable', () {
      expect(TranslationEngine.values[0], TranslationEngine.system);
      expect(TranslationEngine.values[1], TranslationEngine.deepseek);
      expect(TranslationEngine.values[2], TranslationEngine.openai);
      expect(TranslationEngine.values[3], TranslationEngine.claude);
      expect(TranslationEngine.values[4], TranslationEngine.deepl);
      expect(TranslationEngine.values[5], TranslationEngine.baidu);
    });
  });

  group('EngineConfigService constants', () {
    test('default endpoints are HTTPS', () {
      final service = EngineConfigService();
      for (final engine in TranslationEngine.values) {
        final endpoint = service.defaultEndpoint(engine);
        if (endpoint.isNotEmpty) {
          expect(endpoint, startsWith('https://'));
        }
      }
    });

    test('default model names are non-empty for API engines', () {
      final service = EngineConfigService();
      expect(service.defaultModelName(TranslationEngine.deepseek), isNotEmpty);
      expect(service.defaultModelName(TranslationEngine.openai), isNotEmpty);
      expect(service.defaultModelName(TranslationEngine.claude), isNotEmpty);
    });

    test('default model names are empty for non-model engines', () {
      final service = EngineConfigService();
      expect(service.defaultModelName(TranslationEngine.deepl), isEmpty);
      expect(service.defaultModelName(TranslationEngine.baidu), isEmpty);
      expect(service.defaultModelName(TranslationEngine.system), isEmpty);
    });
  });

  group('TranslationService retry queue', () {
    test('初始队列为空', () {
      final service = TranslationService();
      expect(service.pendingRetryCount, equals(0));
    });

    test('翻译失败后自动入队', () async {
      final service = TranslationService();
      final result = await service.translate('Hello', 'en-US', 'zh-CN');
      expect(result, startsWith('[翻译失败]'));
      expect(service.pendingRetryCount, greaterThan(0));
    });

    test('clearRetryQueue 清空队列', () async {
      final service = TranslationService();
      await service.translate('A', 'en-US', 'zh-CN');
      await service.translate('B', 'en-US', 'zh-CN');
      expect(service.pendingRetryCount, greaterThanOrEqualTo(2));
      service.clearRetryQueue();
      expect(service.pendingRetryCount, equals(0));
    });

    test('retryFailed 重试失败条目', () async {
      final service = TranslationService();
      await service.translate('Hello', 'en-US', 'zh-CN');
      await service.retryFailed();
      // 所有引擎都失败，重试后条目仍在队列
      expect(service.pendingRetryCount, greaterThan(0));
    });

    test('onRetrySuccess 回调', () async {
      final service = TranslationService();
      String? capturedText;
      service.onRetrySuccess = (entry, translated) {
        capturedText = entry.text;
      };
      await service.translate('Hello', 'en-US', 'zh-CN');
      // retryFailed 仍然失败，不会触发回调
      await service.retryFailed();
      expect(capturedText, isNull);
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
