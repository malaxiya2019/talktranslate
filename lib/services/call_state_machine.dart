import 'dart:async';
import '../models/call.dart';

/// 纯状态机 — 不依赖任何 UI/服务
///
/// 职责：
///   - 状态流转（含合法性校验）
///   - 超时计时器（connecting → failed, ringing → idle）
///   - 状态变更流
///
/// 超时时长可通过构造函数注入（便于测试）
class CallStateMachine {
  CallState _state = CallState.idle;
  Timer? _timeoutTimer;
  bool _disposed = false;

  final _stateCtl = StreamController<CallState>.broadcast();
  Stream<CallState> get onStateChange => _stateCtl.stream;
  CallState get state => _state;

  /// 超时回调 — 由 CallService 处理副作用
  void Function(CallState target, String message)? onTimeout;

  /// 非法迁移回调
  void Function(CallState from, CallState to)? onInvalidTransition;

  /// 超时时长配置（默认：连接 15s，响铃 30s）
  final Duration connectTimeout;
  final Duration ringTimeout;

  CallStateMachine({
    this.connectTimeout = const Duration(seconds: 15),
    this.ringTimeout = const Duration(seconds: 30),
  });

  /// 状态迁移 — 校验 + 流转 + 超时管理
  void transition(CallState target) {
    if (_disposed) return;
    if (!_state.canTransitionTo(target)) {
      onInvalidTransition?.call(_state, target);
      return; // 静默失败而非抛异常
    }
    _state = target;
    if (!_stateCtl.isClosed) _stateCtl.add(target);
    _scheduleTimeout(target);
  }

  void _scheduleTimeout(CallState target) {
    _cancelTimeout();
    switch (target) {
      case CallState.connecting:
        _startTimeout(connectTimeout, CallState.failed, '连接超时');
        break;
      case CallState.ringing:
        _startTimeout(ringTimeout, CallState.idle, '未接听');
        break;
      default:
        break; // 其他状态无超时
    }
  }

  void _startTimeout(Duration duration, CallState target, String message) {
    _timeoutTimer = Timer(duration, () {
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
    if (_disposed) return;
    _cancelTimeout();
    _state = CallState.idle;
    if (!_stateCtl.isClosed) _stateCtl.add(CallState.idle);
  }

  void dispose() {
    _disposed = true;
    _cancelTimeout();
    _stateCtl.close();
  }
}
