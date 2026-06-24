// Standalone test runner for SubtitleBuffer (no package:test dependency)
import 'package:talktranslate/services/subtitle_buffer.dart';

int passed = 0;
int failed = 0;

void assertEq(String label, dynamic actual, dynamic expected) {
  if (actual == expected) {
    passed++;
  } else {
    failed++;
    print('❌ $label: expected $expected, got $actual');
  }
}

void assertTrue(String label, bool value) {
  if (value) {
    passed++;
  } else {
    failed++;
    print('❌ $label: expected true');
  }
}

void assertFalse(String label, bool value) {
  if (!value) {
    passed++;
  } else {
    failed++;
    print('❌ $label: expected false');
  }
}

void main() {
  print('=== CallSubtitleBuffer Tests ===\n');

  // 1. Initial state
  group('初始状态', () {
    final b = CallSubtitleBuffer();
    assertFalse('空 hasData', b.hasData);
    assertEq('空 count', b.count, 0);
    assertEq('空 drain 为空', b.drain().length, 0);
  });

  // 2. Push and drain
  group('基本写入读取', () {
    final b = CallSubtitleBuffer();
    final entry = SubtitleEntry(text: 'hello', translated: '你好', timestamp: DateTime.now());
    b.push(entry);
    assertTrue('push 后 hasData', b.hasData);
    assertEq('push 后 count', b.count, 1);
    final drained = b.drain();
    assertEq('drain 长度', drained.length, 1);
    assertEq('drain 内容', drained[0].text, 'hello');
  });

  // 3. Order preservation
  group('顺序保持', () {
    final b = CallSubtitleBuffer();
    b.push(SubtitleEntry(text: 'a', translated: '', timestamp: DateTime.now()));
    b.push(SubtitleEntry(text: 'b', translated: '', timestamp: DateTime.now()));
    b.push(SubtitleEntry(text: 'c', translated: '', timestamp: DateTime.now()));
    final entries = b.drain();
    assertEq('顺序 #1', entries[0].text, 'a');
    assertEq('顺序 #2', entries[1].text, 'b');
    assertEq('顺序 #3', entries[2].text, 'c');
  });

  // 4. Clear
  group('clear', () {
    final b = CallSubtitleBuffer();
    b.push(SubtitleEntry(text: 'x', translated: '', timestamp: DateTime.now()));
    b.clear();
    assertFalse('clear 后 hasData', b.hasData);
    assertEq('clear 后 count', b.count, 0);
    assertEq('clear 后 drain', b.drain().length, 0);
  });

  // 5. Overflow (max 30)
  group('环形溢出', () {
    final b = CallSubtitleBuffer();
    for (int i = 0; i < 31; i++) {
      b.push(SubtitleEntry(text: 'msg_$i', translated: '', timestamp: DateTime.now()));
    }
    assertEq('31条后 count=30', b.count, 30);
    assertEq('31条后 drain 长度=30', b.drain().length, 30);
  });

  // 6. Overflow with correct recent entries
  group('环形溢出保留最新', () {
    final b = CallSubtitleBuffer();
    for (int i = 0; i < 35; i++) {
      b.push(SubtitleEntry(text: 'msg_$i', translated: '', timestamp: DateTime.now()));
    }
    final entries = b.drain();
    assertEq('35条后存30条', entries.length, 30);
    assertEq('第一条为 msg_5', entries[0].text, 'msg_5');
    assertEq('最后一条为 msg_34', entries[29].text, 'msg_34');
  });

  // 7. Double ring (60 entries)
  group('两圈溢出', () {
    final b = CallSubtitleBuffer();
    for (int i = 0; i < 60; i++) {
      b.push(SubtitleEntry(text: 'msg_$i', translated: '', timestamp: DateTime.now()));
    }
    assertEq('60条后 count=30', b.count, 30);
    final entries = b.drain();
    assertEq('60条 drain 30条', entries.length, 30);
    assertEq('第一条为 msg_30', entries[0].text, 'msg_30');
    assertEq('最后一条为 msg_59', entries[29].text, 'msg_59');
  });

  // 8. isLocal flag
  group('isLocal 标记', () {
    final b = CallSubtitleBuffer();
    b.push(SubtitleEntry(text: 'local', translated: '', timestamp: DateTime.now(), isLocal: true));
    b.push(SubtitleEntry(text: 'remote', translated: '', timestamp: DateTime.now()));
    assertTrue('第一条 isLocal', b.drain()[0].isLocal);
    assertFalse('第二条 not isLocal', b.drain()[1].isLocal);
  });

  // 9. Serialization
  group('JSON 序列化', () {
    final original = SubtitleEntry(
      text: '你好', translated: 'Hello',
      timestamp: DateTime(2026, 6, 24), isLocal: true,
    );
    final json = original.toJson();
    final restored = SubtitleEntry.fromJson(json);
    assertEq('text 一致', restored.text, original.text);
    assertEq('translated 一致', restored.translated, original.translated);
    assertEq('isLocal 一致', restored.isLocal, original.isLocal);
  });

  // 10. fromJson empty fallback
  group('fromJson 空值降级', () {
    final r = SubtitleEntry.fromJson({});
    assertEq('空 text', r.text, '');
    assertEq('空 translated', r.translated, '');
    assertEq('空 isLocal', r.isLocal, false);
  });

  // 11. drain is not destructive
  group('drain 非消费式', () {
    final b = CallSubtitleBuffer();
    b.push(SubtitleEntry(text: 'persist', translated: '', timestamp: DateTime.now()));
    b.drain();
    assertEq('二次 drain 仍有数据', b.drain().length, 1);
  });

  print('\n=== Results ===');
  print('✅ Passed: $passed');
  print('❌ Failed: $failed');
  print('Total: ${passed + failed}');
}
