import 'package:test/test.dart';
import 'package:talktranslate/models/phrase_dictionary.dart';

void main() {
  group('PhraseDictionary', () {
    group('精准匹配', () {
      test('你好 → English', () {
        expect(PhraseDictionary.lookup('你好', 'en-US'), equals('Hello'));
      });

      test('谢谢 → Japanese', () {
        expect(PhraseDictionary.lookup('谢谢', 'ja-JP'), equals('ありがとう'));
      });

      test('再见 → Korean', () {
        expect(PhraseDictionary.lookup('再见', 'ko-KR'), equals('안녕히 계세요'));
      });

      test('是的 → Spanish', () {
        expect(PhraseDictionary.lookup('是的', 'es-ES'), equals('Sí'));
      });

      test('不是 → French', () {
        expect(PhraseDictionary.lookup('不是', 'fr-FR'), equals('Non'));
      });

      test('对不起 → German', () {
        expect(PhraseDictionary.lookup('对不起', 'de-DE'), equals('Entschuldigung'));
      });

      test('请帮我 → Thai', () {
        expect(PhraseDictionary.lookup('请帮我', 'th-TH'), equals('ช่วยฉันหน่อย'));
      });

      test('我不明白 → Vietnamese', () {
        expect(PhraseDictionary.lookup('我不明白', 'vi-VN'), equals('Tôi không hiểu'));
      });

      test('请慢点说 → Arabic', () {
        expect(PhraseDictionary.lookup('请慢点说', 'ar-SA'), equals('تحدث ببطء من فضلك'));
      });

      test('多少钱 → Portuguese', () {
        expect(PhraseDictionary.lookup('多少钱', 'pt-BR'), equals('Quanto custa'));
      });

      test('多少钱 → Russian', () {
        expect(PhraseDictionary.lookup('多少钱', 'ru-RU'), equals('Сколько стоит'));
      });
    });

    group('包含匹配', () {
      test('你好世界 → English (你好替换)', () {
        final result = PhraseDictionary.lookup('你好世界', 'en-US');
        expect(result, equals('Hello世界'));
      });

      test('请帮我一下 → English', () {
        final result = PhraseDictionary.lookup('请帮我一下', 'en-US');
        expect(result, equals('Please help me一下'));
      });
    });

    group('无匹配', () {
      test('未知短语返回 null', () {
        expect(PhraseDictionary.lookup('量子计算机', 'en-US'), isNull);
      });

      test('空字符串返回 null', () {
        expect(PhraseDictionary.lookup('', 'en-US'), isNull);
      });
    });

    group('hasMatch', () {
      test('已知短语返回 true', () {
        expect(PhraseDictionary.hasMatch('你好', 'en-US'), isTrue);
      });

      test('包含已知短语的字符串返回 true', () {
        expect(PhraseDictionary.hasMatch('请帮我一下', 'en-US'), isTrue);
      });

      test('未知短语返回 false', () {
        expect(PhraseDictionary.hasMatch('量子计算', 'en-US'), isFalse);
      });

      test('空字符串返回 false', () {
        expect(PhraseDictionary.hasMatch('', 'en-US'), isFalse);
      });
    });

    test('phraseCount 返回正确数量', () {
      expect(PhraseDictionary.phraseCount, greaterThan(0));
      // 我们定义了 10 个短语
      expect(PhraseDictionary.phraseCount, equals(10));
    });
  });
}
