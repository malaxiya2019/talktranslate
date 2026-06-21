import 'package:flutter/services.dart';

/// 系统悬浮窗管理 (Android)
///
/// 需要 SYSTEM_ALERT_WINDOW 权限。
/// 在设置中手动开启: 设置 → 应用 → TalkTranslate → 显示在其他应用上层
class OverlayManager {
  static const _channel = MethodChannel('talktranslate/overlay');

  /// 检查悬浮窗权限
  static Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod('hasPermission');
    } catch (_) {
      return false;
    }
  }

  /// 请求悬浮窗权限
  static Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod('requestPermission');
    } catch (_) {
      return false;
    }
  }

  /// 启动悬浮窗服务
  static Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
    } catch (_) {}
  }

  /// 显示字幕
  static Future<void> showSubtitle(String original, String translated) async {
    try {
      await _channel.invokeMethod('show', {
        'original': original,
        'translated': translated,
      });
    } catch (_) {}
  }

  /// 隐藏悬浮窗
  static Future<void> hide() async {
    try {
      await _channel.invokeMethod('hide');
    } catch (_) {}
  }

  /// 停止服务
  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}
  }
}
