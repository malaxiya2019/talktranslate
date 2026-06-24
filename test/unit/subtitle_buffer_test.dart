import 'package:test/test.dart';
import 'package:talktranslate/services/subtitle_buffer.dart';

void main() {
  late CallSubtitleBuffer buffer;

  setUp(() {
    buffer = CallSubtitleBuffer();
  });

  SubtitleEntry _entry(String text, {bool isLocal = false}) => SubtitleEntry(
    text: text,
    translated: '[${text}]',
    timestamp: DateTime(2026, 6, 24, 10, 0, 0),
    isLocal: isLocal,
  );

  group('初始状态', () {
    test('空缓存 hasData = false', () {
      expect(buffer.hasData, false);
    });

    test('空缓存 count = 0', () {
      expect(buffer.count, 0);
    });

    test('空缓存 drain 返回空列表', () {
      expect(buffer.drain(), isEmpty);
    });
  });

  group('基本写入与读取', () {
    test('写入一条后 hasData = true', () {
      buffer.push(_entry('hello'));
      expect(buffer.hasData, true);
      expect(buffer.count, 1);
    });

    test('drain 返回写入的条目', () {
      buffer.push(_entry('hello'));
      final entries = buffer.drain();
      expect(entries.length, 1);
      expect(entries[0].text, 'hello');
      expect(entries[0].translated, '[hello]');
    });

    test('drain 按写入顺序返回', () {
      buffer.push(_entry('first'));
      buffer.push(_entry('second'));
      buffer.push(_entry('third'));
      final entries = buffer.drain();
      expect(entries.map((e) => e.text), ['first', 'second', 'third']);
    });
  });

  group('clear', () {
    test('clear 后 hasData = false', () {
      buffer.push(_entry('hello'));
      buffer.clear();
      expect(buffer.hasData, false);
      expect(buffer.count, 0);
    });

    test('clear 后 drain 为空', () {
      buffer.push(_entry('hello'));
      buffer.clear();
      expect(buffer.drain(), isEmpty);
    });

    test('clear 后可重新写入', () {
      buffer.push(_entry('first'));
      buffer.clear();
      buffer.push(_entry('second'));
      expect(buffer.drain().map((e) => e.text), ['second']);
    });
  });

  group('环形溢出 (超过 30 条)', () {
    test('写入 31 条，drain 仍然返回 30 条', () {
      for (int i = 0; i < 31; i++) {
        buffer.push(_entry('msg_$i'));
      }
      expect(buffer.count, 30);
      expect(buffer.drain().length, 30);
    });

    test('环形溢出后保留最新的 30 条', () {
      for (int i = 0; i < 35; i++) {
        buffer.push(_entry('msg_$i'));
      }
      final entries = buffer.drain();
      expect(entries.length, 30);
      expect(entries[0].text, 'msg_5');
      expect(entries[29].text, 'msg_34');
    });

    test('写入 60 条（两圈），仍然正常', () {
      for (int i = 0; i < 60; i++) {
        buffer.push(_entry('msg_$i'));
      }
      expect(buffer.count, 30);
      final entries = buffer.drain();
      expect(entries.length, 30);
      expect(entries[0].text, 'msg_30');
      expect(entries[29].text, 'msg_59');
    });
  });

  group('边界条件', () {
    test('写入 0 条，drain 空', () {
      expect(buffer.drain(), isEmpty);
    });

    test('drain 非消费式，再次 drain 仍有数据', () {
      buffer.push(_entry('hello'));
      buffer.drain();
      final secondDrain = buffer.drain();
      expect(secondDrain.length, 1);
    });

    test('写入 30 条（刚好满），drain 返回全部', () {
      for (int i = 0; i < 30; i++) {
        buffer.push(_entry('msg_$i'));
      }
      expect(buffer.drain().length, 30);
    });

    test('isLocal 标记正确保留', () {
      buffer.push(_entry('local', isLocal: true));
      buffer.push(_entry('remote'));
      final entries = buffer.drain();
      expect(entries[0].isLocal, true);
      expect(entries[1].isLocal, false);
    });
  });

  group('SubtitleEntry serialization', () {
    test('toJson / fromJson 循环一致', () {
      final original = SubtitleEntry(
        text: '你好',
        translated: 'Hello',
        timestamp: DateTime(2026, 6, 24, 10, 30, 0, 123),
        isLocal: true,
      );
      final json = original.toJson();
      final restored = SubtitleEntry.fromJson(json);
      expect(restored.text, original.text);
      expect(restored.translated, original.translated);
      expect(restored.timestamp, original.timestamp);
      expect(restored.isLocal, original.isLocal);
    });

    test('fromJson 空值降级', () {
      final restored = SubtitleEntry.fromJson({});
      expect(restored.text, '');
      expect(restored.translated, '');
      expect(restored.isLocal, false);
    });
  });
}
