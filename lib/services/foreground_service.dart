import 'package:flutter/services.dart';

/// 前台服务管理 — 防止 Android 杀后台通话进程
///
/// 通过 MethodChannel 与 CallForegroundService.kt 通信。
/// 由 CallService 状态机驱动：
///   inCall → start(peerName)
///   idle   → stop()
///   timer tick → update(duration)
class ForegroundService {
  static const _channel = MethodChannel('talktranslate/foreground_service');

  static final ForegroundService _instance = ForegroundService._();
  factory ForegroundService() => _instance;
  ForegroundService._();

  bool _active = false;
  bool get isActive => _active;

  /// 启动前台服务 — CallState.inCall 时调用
  Future<void> start(String peerName) async {
    if (_active) return;
    try {
      await _channel.invokeMethod('startService', {
        'peer': peerName,
        'status': '已连接',
      });
      _active = true;
    } catch (_) {
      // Android 平台不可用（iOS/桌面）
    }
  }

  /// 更新通知 — 每秒由计时器触发
  Future<void> update(String peerName, String duration) async {
    if (!_active) return;
    try {
      await _channel.invokeMethod('updateNotification', {
        'peer': peerName,
        'duration': duration,
      });
    } catch (_) {}
  }

  /// 停止前台服务 — CallState.idle/failed 时调用
  Future<void> stop() async {
    if (!_active) return;
    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}
    _active = false;
  }
}
