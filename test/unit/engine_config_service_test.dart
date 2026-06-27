import 'package:test/test.dart';
import 'package:talktranslate/services/engine_config_service.dart';

void main() {
  group('EngineConfigService', () {
    late EngineConfigService service;

    setUp(() {
      service = EngineConfigService();
    });

    group('defaultEndpoint', () {
      test('DeepSeek endpoint', () {
        expect(service.defaultEndpoint(TranslationEngine.deepseek),
            equals('https://api.deepseek.com/v1'));
      });

      test('OpenAI endpoint', () {
        expect(service.defaultEndpoint(TranslationEngine.openai),
            equals('https://api.openai.com/v1'));
      });

      test('Claude endpoint', () {
        expect(service.defaultEndpoint(TranslationEngine.claude),
            equals('https://api.anthropic.com/v1'));
      });

      test('DeepL endpoint', () {
        expect(service.defaultEndpoint(TranslationEngine.deepl),
            equals('https://api-free.deepl.com/v2'));
      });

      test('Baidu endpoint', () {
        expect(service.defaultEndpoint(TranslationEngine.baidu),
            equals('https://api.fanyi.baidu.com/api'));
      });

      test('system engine has empty endpoint', () {
        expect(service.defaultEndpoint(TranslationEngine.system), isEmpty);
      });
    });

    group('TranslationEngine enum', () {
      test('all 6 engines defined', () {
        expect(TranslationEngine.values.length, equals(6));
      });

      test('contains expected engines', () {
        final engines = TranslationEngine.values.toSet();
        expect(engines, containsAll([
          TranslationEngine.system,
          TranslationEngine.deepseek,
          TranslationEngine.openai,
          TranslationEngine.claude,
          TranslationEngine.deepl,
          TranslationEngine.baidu,
        ]));
      });

      test('deepseek is the default primary engine', () {
        expect(TranslationEngine.values.indexOf(TranslationEngine.deepseek),
            equals(1)); // after system
      });
    });
  });
}
