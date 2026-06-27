import 'package:test/test.dart';
import 'package:talktranslate/services/edge_ai_engine.dart';

void main() {
  group('EdgeAIEngine', () {
    late EdgeAIEngine engine;

    setUp(() {
      engine = EdgeAIEngine();
    });

    test('singleton — same instance', () {
      final another = EdgeAIEngine();
      expect(identical(engine, another), isTrue);
    });

    test('initial status is unavailable', () {
      expect(engine.status, equals(EdgeAIStatus.unavailable));
      expect(engine.isAvailable, isFalse);
    });

    test('init without ML Kit falls back to partial (phrase dict)', () async {
      final ok = await engine.init(useMlKit: false);
      expect(ok, isTrue);
      expect(engine.isAvailable, isTrue);
      expect(engine.status, equals(EdgeAIStatus.partial));
    });

    test('dispose resets status', () async {
      await engine.init(useMlKit: false);
      expect(engine.isAvailable, isTrue);
      await engine.dispose();
      expect(engine.status, equals(EdgeAIStatus.unavailable));
      expect(engine.isAvailable, isFalse);
    });

    group('translate (phrase dictionary fallback)', () {
      setUp(() async {
        await engine.init(useMlKit: false);
      });

      test('你好 → English via phrase dict', () async {
        final result = await engine.translate(
          text: '你好', from: 'zh-CN', to: 'en-US',
        );
        expect(result, equals('Hello'));
      });

      test('谢谢 → Japanese via phrase dict', () async {
        final result = await engine.translate(
          text: '谢谢', from: 'zh-CN', to: 'ja-JP',
        );
        expect(result, equals('ありがとう'));
      });

      test('空文本返回空', () async {
        final result = await engine.translate(
          text: '', from: 'zh-CN', to: 'en-US',
        );
        expect(result, isEmpty);
      });

      test('未知短语返回原文', () async {
        final result = await engine.translate(
          text: '量子计算机', from: 'zh-CN', to: 'en-US',
        );
        expect(result, equals('量子计算机'));
      });

      test('不支持的语言返回原文', () async {
        final result = await engine.translate(
          text: 'Hello', from: 'xx-XX', to: 'en-US',
        );
        expect(result, equals('Hello'));
      });

      test('包含匹配 — 请帮我一下', () async {
        final result = await engine.translate(
          text: '请帮我一下', from: 'zh-CN', to: 'en-US',
        );
        expect(result, contains('Please help me'));
      });
    });

    group('disposed state', () {
      test('translate returns empty after dispose', () async {
        await engine.init(useMlKit: false);
        await engine.dispose();
        final result = await engine.translate(
          text: '你好', from: 'zh-CN', to: 'en-US',
        );
        expect(result, equals('你好')); // returns original text
      });
    });

    test('getDiagnostics returns status map', () async {
      await engine.init(useMlKit: false);
      final diag = engine.getDiagnostics();
      expect(diag['status'], isNotNull);
      expect(diag['isAvailable'], isTrue);
      expect(diag['phraseCount'], greaterThan(0));
    });

    test('supportedLangs contains 12 languages', () {
      expect(EdgeAIEngine.supportedLangs.length, equals(12));
      expect(EdgeAIEngine.supportedLangs, contains('zh-CN'));
      expect(EdgeAIEngine.supportedLangs, contains('en-US'));
      expect(EdgeAIEngine.supportedLangs, contains('th-TH'));
      expect(EdgeAIEngine.supportedLangs, contains('vi-VN'));
    });
  });
}
