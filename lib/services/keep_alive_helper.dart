import 'foreground_service.dart';

/// 保活状态检查 — 在应用启动/设置页展示
///
/// 用于引导用户优化 Android 保活配置：
///   1. 通知权限 (Android 13+)
///   2. 电池优化白名单
class KeepAliveHelper {
  static final KeepAliveHelper _instance = KeepAliveHelper._();
  factory KeepAliveHelper() => _instance;
  KeepAliveHelper._();

  /// 检查结果
  KeepAliveStatus? _status;
  KeepAliveStatus? get status => _status;

  bool get allOk => _status != null && _status!.notificationOk && _status!.batteryOk;

  /// 执行检查（异步）
  Future<KeepAliveStatus> check() async {
    final results = await ForegroundService().checkKeepAlivePrerequisites();
    _status = KeepAliveStatus(
      notificationOk: results[0],
      batteryOk: results[1],
    );
    return _status!;
  }

  /// 请求通知权限
  Future<void> requestNotification() async {
    await ForegroundService().requestNotificationPermission();
    // 请求后重新检查
    await check();
  }

  /// 引导加入电池优化白名单
  Future<void> requestBatteryWhitelist() async {
    await ForegroundService().requestBatteryOptimizationWhitelist();
    // 请求后重新检查
    await check();
  }
}

class KeepAliveStatus {
  final bool notificationOk;
  final bool batteryOk;

  const KeepAliveStatus({
    required this.notificationOk,
    required this.batteryOk,
  });

  int get missingCount => (notificationOk ? 0 : 1) + (batteryOk ? 0 : 1);

  String get summary {
    final parts = <String>[];
    if (notificationOk) parts.add('✅ 通知权限');
    if (batteryOk) parts.add('✅ 电池白名单');
    return parts.join(' · ');
  }
}
