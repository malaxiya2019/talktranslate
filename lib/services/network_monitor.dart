import 'dart:async';
import 'package:flutter/services.dart';

/// 网络状态监听器 — 与 Kotlin ConnectivityManager 桥接
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

  /// 开始监听网络状态
  Future<void> start() async {
    try {
      await _channel.invokeMethod('startMonitoring');
      _channel.setMethodCallHandler(_handleNativeCallback);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopMonitoring');
    } catch (_) {}
    _channel.setMethodCallHandler(null);
  }

  Future<String> getCurrentNetworkType() async {
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
        _onChange.add(_networkType);
        break;
      case 'onNetworkLost':
        _networkType = 'none';
        _onChange.add('none');
        break;
      case 'onNetworkChanged':
        _networkType = call.arguments as String? ?? 'unknown';
        _onChange.add(_networkType);
        break;
    }
  }

  void dispose() {
    stop();
    _onChange.close();
  }
}
