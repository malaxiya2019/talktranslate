import 'package:test/test.dart';
import 'dart:async';
import 'package:talktranslate/models/call.dart';
import 'package:talktranslate/services/call_state_machine.dart';

void main() {
  late CallStateMachine machine;

  setUp(() {
    machine = CallStateMachine(
      connectTimeout: const Duration(milliseconds: 50),
      ringTimeout: const Duration(milliseconds: 100),
    );
  });

  group('初始状态', () {
    test('创建时状态为 idle', () {
      expect(machine.state, CallState.idle);
    });

    test('isCallActive 初始为 false', () {
      expect(machine.isCallActive, false);
    });

    test('reset 保持在 idle', () {
      machine.reset();
      expect(machine.state, CallState.idle);
    });
  });

  group('合法迁移路径', () {
    test('idle → connecting → inCall → idle (正常挂断)', () {
      machine.transition(CallState.connecting);
      expect(machine.state, CallState.connecting);
      expect(machine.isCallActive, true);

      machine.transition(CallState.inCall);
      expect(machine.state, CallState.inCall);
      expect(machine.isCallActive, true);

      machine.transition(CallState.idle);
      expect(machine.state, CallState.idle);
      expect(machine.isCallActive, false);
    });

    test('idle → connecting → failed → idle (呼叫失败)', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.failed);
      expect(machine.state, CallState.failed);
      expect(machine.isCallActive, false);

      machine.transition(CallState.idle);
      expect(machine.state, CallState.idle);
    });

    test('idle → ringing → idle (拒接)', () {
      machine.transition(CallState.ringing);
      expect(machine.state, CallState.ringing);
      expect(machine.isCallActive, true);

      machine.transition(CallState.idle);
      expect(machine.state, CallState.idle);
      expect(machine.isCallActive, false);
    });

    test('idle → ringing → inCall (接听)', () {
      machine.transition(CallState.ringing);
      machine.transition(CallState.inCall);
      expect(machine.state, CallState.inCall);
    });

    test('inCall → reconnecting → inCall (断线重连成功)', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      machine.transition(CallState.reconnecting);
      expect(machine.state, CallState.reconnecting);
      expect(machine.isCallActive, true);

      machine.transition(CallState.inCall);
      expect(machine.state, CallState.inCall);
    });

    test('inCall → reconnecting → failed (重连失败)', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      machine.transition(CallState.reconnecting);
      machine.transition(CallState.failed);
      expect(machine.state, CallState.failed);
      expect(machine.isCallActive, false);
    });
  });

  group('非法迁移 — 静默失败', () {
    test('idle → inCall 非法', () {
      machine.transition(CallState.inCall);
      expect(machine.state, CallState.idle);
    });

    test('idle → failed 非法', () {
      machine.transition(CallState.failed);
      expect(machine.state, CallState.idle);
    });

    test('idle → reconnecting 非法', () {
      machine.transition(CallState.reconnecting);
      expect(machine.state, CallState.idle);
    });

    test('connecting → ringing 非法', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.ringing);
      expect(machine.state, CallState.connecting);
    });

    test('connecting → reconnecting 非法', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.reconnecting);
      expect(machine.state, CallState.connecting);
    });

    test('ringing → connecting 非法', () {
      machine.transition(CallState.ringing);
      machine.transition(CallState.connecting);
      expect(machine.state, CallState.ringing);
    });

    test('ringing → failed 非法', () {
      machine.transition(CallState.ringing);
      machine.transition(CallState.failed);
      expect(machine.state, CallState.ringing);
    });

    test('inCall → connecting 非法', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      machine.transition(CallState.connecting);
      expect(machine.state, CallState.inCall);
    });

    test('inCall → ringing 非法', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      machine.transition(CallState.ringing);
      expect(machine.state, CallState.inCall);
    });

    test('reconnecting → ringing 非法', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      machine.transition(CallState.reconnecting);
      machine.transition(CallState.ringing);
      expect(machine.state, CallState.reconnecting);
    });

    test('reconnecting → connecting 非法', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      machine.transition(CallState.reconnecting);
      machine.transition(CallState.connecting);
      expect(machine.state, CallState.reconnecting);
    });
  });

  group('非法迁移回调', () {
    test('非法迁移触发 onInvalidTransition', () {
      CallState? from;
      CallState? to;
      machine.onInvalidTransition = (f, t) {
        from = f;
        to = t;
      };
      machine.transition(CallState.inCall); // idle→inCall 非法
      expect(from, CallState.idle);
      expect(to, CallState.inCall);
    });
  });

  group('超时机制', () {
    test('connecting 50ms 后转为 failed', () async {
      machine.transition(CallState.connecting);
      await Future.delayed(const Duration(milliseconds: 80));
      expect(machine.state, CallState.failed);
    });

    test('ringing 100ms 后转为 idle', () async {
      machine.transition(CallState.ringing);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(machine.state, CallState.idle);
    });

    test('超时触发 onTimeout 回调', () async {
      String? timeoutMsg;
      machine.onTimeout = (target, msg) {
        timeoutMsg = msg;
      };
      machine.transition(CallState.connecting);
      await Future.delayed(const Duration(milliseconds: 80));
      expect(timeoutMsg, '连接超时');
    });

    test('inCall 无超时', () async {
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(machine.state, CallState.inCall);
    });

    test('reset 取消超时', () async {
      machine.transition(CallState.connecting);
      machine.reset();
      await Future.delayed(const Duration(milliseconds: 80));
      expect(machine.state, CallState.idle);
    });
  });

  group('状态变更流', () {
    test('transition 发出事件', () {
      final events = <CallState>[];
      final sub = machine.onStateChange.listen(events.add);
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      expect(events, [CallState.connecting, CallState.inCall]);
      sub.cancel();
    });

    test('非法迁移不发出事件', () {
      final events = <CallState>[];
      final sub = machine.onStateChange.listen(events.add);
      machine.transition(CallState.inCall); // 非法
      expect(events, isEmpty);
      sub.cancel();
    });

    test('reset 发出 idle 事件', () {
      final events = <CallState>[];
      final sub = machine.onStateChange.listen(events.add);
      machine.transition(CallState.connecting);
      machine.reset();
      expect(events.last, CallState.idle);
      sub.cancel();
    });

    test('dispose 后 transition 静默失败', () {
      final events = <CallState>[];
      final sub = machine.onStateChange.listen(events.add);
      machine.dispose();
      machine.transition(CallState.connecting);
      expect(events, isEmpty);
      sub.cancel();
    });

    test('dispose 后 reset 静默失败', () {
      final events = <CallState>[];
      final sub = machine.onStateChange.listen(events.add);
      machine.dispose();
      machine.reset();
      expect(events, isEmpty);
      sub.cancel();
    });
  });

  group('isCallActive', () {
    test('connecting 时为 true', () {
      machine.transition(CallState.connecting);
      expect(machine.isCallActive, true);
    });

    test('ringing 时为 true', () {
      machine.transition(CallState.ringing);
      expect(machine.isCallActive, true);
    });

    test('inCall 时为 true', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      expect(machine.isCallActive, true);
    });

    test('reconnecting 时为 true', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.inCall);
      machine.transition(CallState.reconnecting);
      expect(machine.isCallActive, true);
    });

    test('failed 时为 false', () {
      machine.transition(CallState.connecting);
      machine.transition(CallState.failed);
      expect(machine.isCallActive, false);
    });
  });

  group('dispose', () {
    test('dispose 后不再崩溃', () {
      machine.dispose();
      machine.transition(CallState.connecting);
      // should not throw
    });
  });
}
