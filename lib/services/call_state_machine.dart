import 'dart:async';
import '../models/call.dart';

/// 纯状态机 — 不依赖任何 UI/服务
///
/// 职责：
///   - 状态流转（含合法性校验）
///   - 超时计时器（connecting 15s → failed, ringing 30s → idle）
///   - 状态变更流
///
/// 不负责：
///   - 重连逻辑（需 SignalingService）
///   - Overlay 联动
///   - 任何 UI 相关
class CallStateMachine {
  CallState _state = CallState.idle;
  Timer? _timeoutTimer;

  final _stateCtl = StreamController<CallState>.broadcast();
  Stream<CallState> get onStateChange => _stateCtl.stream;
  CallState get state => _state;

  /// 超时回调 — 由 CallService 处理副作用
  void Function(CallState target, String message)? onTimeout;

  /// 非法迁移回调
  void Function(CallState from, CallState to)? onInvalidTransition;

  /// 状态迁移 — 校验 + 流转 + 超时管理
  void transition(CallState target) {
    if (!_state.canTransitionTo(target)) {
      onInvalidTransition?.call(_state, target);
      return; // 静默失败而非抛异常
    }
    _state = target;
    _stateCtl.add(target);
    _scheduleTimeout(target);
  }

  void _scheduleTimeout(CallState target) {
    _cancelTimeout();
    switch (target) {
      case CallState.connecting:
        _startTimeout(15, CallState.failed, '连接超时');
        break;
      case CallState.ringing:
        _startTimeout(30, CallState.idle, '未接听');
        break;
      default:
        break; // 其他状态无超时
    }
  }

  void _startTimeout(int seconds, CallState target, String message) {
    _timeoutTimer = Timer(Duration(seconds: seconds), () {
      transition(target);
      onTimeout?.call(target, message);
    });
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  bool get isCallActive =>
      _state == CallState.connecting ||
      _state == CallState.ringing ||
      _state == CallState.inCall ||
      _state == CallState.reconnecting;

  /// 重置到 idle（断开/失败后）
  void reset() {
    _cancelTimeout();
    _state = CallState.idle;
    _stateCtl.add(CallState.idle);
  }

  void dispose() {
    _cancelTimeout();
    _stateCtl.close();
  }
}
