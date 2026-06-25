import 'package:flutter/services.dart';

/// 前台服务管理 — 防止 Android 杀后台通话进程
///
/// 通过 MethodChannel 与 CallForegroundService.kt 通信。
/// 由 CallService 状态机驱动：
///   inCall → start(peerName)
///   idle   → stop()
///   timer tick → update(duration)
///
/// 同时提供保活辅助能力：
///   - 通知权限请求 (Android 13+)
///   - 电池优化白名单引导
class ForegroundService {
  static const _serviceChannel = MethodChannel('talktranslate/foreground_service');
  static const _platformChannel = MethodChannel('talktranslate/platform');

  static final ForegroundService _instance = ForegroundService._();
  factory ForegroundService() => _instance;
  ForegroundService._();

  bool _active = false;
  bool get isActive => _active;

  /// 启动前台服务 — CallState.inCall 时调用
  Future<void> start(String peerName) async {
    if (_active) return;
    try {
      await _serviceChannel.invokeMethod('startService', {
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
      await _serviceChannel.invokeMethod('updateNotification', {
        'peer': peerName,
        'duration': duration,
      });
    } catch (_) {}
  }

  /// 停止前台服务 — CallState.idle/failed 时调用
  Future<void> stop() async {
    if (!_active) return;
    try {
      await _serviceChannel.invokeMethod('stopService');
    } catch (_) {}
    _active = false;
  }

  // ── 保活辅助 ──

  /// 检查是否有通知权限 (Android 13+)
  Future<bool> hasNotificationPermission() async {
    try {
      final result = await _platformChannel.invokeMethod<bool>('hasNotificationPermission');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// 请求通知权限 (Android 13+)
  Future<void> requestNotificationPermission() async {
    try {
      await _platformChannel.invokeMethod('requestNotificationPermission');
    } catch (_) {}
  }

  /// 检查是否已加入电池优化白名单
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _platformChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (_) {
      return true; // 非 Android 或无法检查，视为已忽略
    }
  }

  /// 引导用户加入电池优化白名单
  /// 国产 ROM（小米/华为/OPPO/VIVO）通常还需要手动加入"受保护应用"
  Future<void> requestBatteryOptimizationWhitelist() async {
    try {
      await _platformChannel.invokeMethod('requestBatteryOptimizationWhitelist');
    } catch (_) {}
  }

  /// 一键检查所有保活前提条件
  /// 返回 [notificationOk, batteryOk]
  Future<List<bool>> checkKeepAlivePrerequisites() async {
    final results = await Future.wait([
      hasNotificationPermission(),
      isIgnoringBatteryOptimizations(),
    ]);
    return results.cast<bool>();
  }
}
