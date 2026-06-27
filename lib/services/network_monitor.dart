import 'dart:async';
import 'dart:io' show InternetAddress;
import 'package:flutter/services.dart';

/// 网络状态监听器 — 与 Kotlin ConnectivityManager 桥接
///
/// 优先使用原生 MethodChannel 获取网络状态，
/// 原生不可用时自动降级到 Dart 层 DNS 探测。
///
/// 通知 Flutter 层网络变化：wifi / cellular / ethernet / none
class NetworkMonitor {
  static const _channel = MethodChannel('talktranslate/network_state');

  static final NetworkMonitor _instance = NetworkMonitor._();
  factory NetworkMonitor() => _instance;
  NetworkMonitor._();

  String _networkType = 'unknown';
  String get networkType => _networkType;
  bool get isOnline => _networkType != 'none' && _networkType != 'unknown';

  final _onChange = StreamController<String>.broadcast();
  Stream<String> get onChange => _onChange.stream;

  // ── Dart 层降级探测 ──
  Timer? _fallbackTimer;
  bool _useDartFallback = false;
  static const _fallbackInterval = Duration(seconds: 10);

  /// 开始监听网络状态
  Future<void> start() async {
    try {
      await _channel.invokeMethod('startMonitoring');
      _channel.setMethodCallHandler(_handleNativeCallback);
      // 原生通道可用，不需要 Dart 降级
      _useDartFallback = false;
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
    } catch (_) {
      // 原生通道不可用 → 启动 Dart 层降级探测
      _useDartFallback = true;
      _startDartFallback();
    }
  }

  /// Dart 层 DNS 探测降级
  void _startDartFallback() {
    _fallbackTimer?.cancel();

    // 立即执行一次
    _checkConnectivity();

    // 定时轮询
    _fallbackTimer = Timer.periodic(_fallbackInterval, (_) {
      _checkConnectivity();
    });
  }

  /// 安全推送事件（防止 dispose 后 add 抛异常）
  void _emitChange(String type) {
    if (!_onChange.isClosed) _onChange.add(type);
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      final newType = online ? 'wifi' : 'none';
      if (newType != _networkType) {
        _networkType = newType;
        _emitChange(_networkType);
      }
    } catch (_) {
      if (_networkType != 'none') {
        _networkType = 'none';
        _emitChange('none');
      }
    }
  }

  Future<void> stop() async {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _useDartFallback = false;

    try {
      await _channel.invokeMethod('stopMonitoring');
    } catch (_) {}
    _channel.setMethodCallHandler(null);
  }

  Future<String> getCurrentNetworkType() async {
    if (_useDartFallback) {
      return _networkType;
    }
    try {
      return await _channel.invokeMethod('getCurrentNetworkType') as String;
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> _handleNativeCallback(MethodCall call) async {
    switch (call.method) {
      case 'onNetworkAvailable':
        _networkType = call.arguments as String? ?? 'unknown';
        _emitChange(_networkType);
        break;
      case 'onNetworkLost':
        _networkType = 'none';
        _emitChange('none');
        break;
      case 'onNetworkChanged':
        _networkType = call.arguments as String? ?? 'unknown';
        _emitChange(_networkType);
        break;
    }
  }

  void dispose() {
    stop();
    _onChange.close();
  }
}
