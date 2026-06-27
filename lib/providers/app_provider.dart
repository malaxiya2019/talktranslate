import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/signaling_service.dart';
import '../services/session_restore_service.dart';
import '../services/network_monitor.dart';
import '../models/call.dart';
import 'settings_provider.dart';
import 'call_provider.dart';

/// 全局状态协调器 — 认证 + 通话记录 + 网络监控
///
/// 启动时序（main.dart）：
///   WidgetsFlutterBinding → AppProvider() → await init() → runApp()
///
/// 职责范围（相比重构前已大幅缩小）：
///   - 账户认证 / JWT Token
///   - 信令连接生命周期
///   - 通话记录持久化
///   - Toast 消息
///   - 网络状态监听
///   - 会话恢复
///
/// 设置相关 → SettingsProvider
/// 通话状态相关 → CallProvider
class AppProvider extends ChangeNotifier {
  final SignalingService signaling = SignalingService();
  late final SettingsProvider settings;
  late final CallProvider callProvider;

  bool _initialized = false;
  bool get initialized => _initialized;

  // ── 账户 ──
  String? _phone;
  String? get phone => _phone;
  bool _connected = false;
  bool get connected => _connected;
  List<String> _onlineUsers = [];
  List<String> get onlineUsers => _onlineUsers;

  // ── JWT 认证 ──
  String? _authToken;

  // ── 通话记录 ──
  List<CallRecord> _callHistory = [];
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);

  // ── Toast ──
  String? _toast;
  String? get toast => _toast;

  /// 构造函数：只注册事件监听，不做 IO
  AppProvider({
    required this.settings,
    required this.callProvider,
  }) {
    signaling.events.listen(_onSignalEvent);
    callProvider.callService.events.listen(_onCallServiceEvent);
  }

  /// 异步初始化：加载设置 → 恢复通话 → 标记就绪
  Future<void> init() async {
    // 注入设置到翻译管道
    callProvider.setPipelineApiKey(settings.apiKey);
    callProvider.setPipelineLanguages(settings.myLang, settings.peerLang);
    callProvider.setPipelineTts(settings.ttsEnabled);

    await _tryRestore();
    unawaited(_startNetworkMonitor());

    _initialized = true;
    notifyListeners();
  }

  // ── 信令事件处理 ──

  void _onSignalEvent(Map<String, dynamic> e) {
    switch (e['type']) {
      case 'registered':
        _connected = true;
        _phone = e['phone'];
        notifyListeners();
        break;
      case 'disconnected':
        _connected = false;
        notifyListeners();
        break;
      case 'online':
        _onlineUsers = List<String>.from(e['users']);
        notifyListeners();
        break;
      case 'incoming':
        callProvider.callService.incoming(e['callId'], e['from']);
        notifyListeners();
        break;
      case 'error':
        _toast = e['message'];
        notifyListeners();
        break;
    }
  }

  // ── 通话服务事件处理 ──

  void _onCallServiceEvent(Map<String, dynamic> e) {
    if (e['type'] == 'toast') {
      _toast = e['message'];
      notifyListeners();
    }
    if (e['type'] == 'call_record') _saveCallRecord(e);
    if (e['type'] == 'snapshot') {
      _persistSnapshot(Map<String, dynamic>.from(e['snapshot'] as Map));
    }
    if (e['type'] == 'snapshot_clear') _clearSnapshot();
  }

  // ── 网络监控 ──

  Future<void> _startNetworkMonitor() async {
    await NetworkMonitor().start();
    NetworkMonitor().onChange.listen((type) {
      if (type != 'none') {
        // 网络恢复 → 自动重试失败的翻译
        callProvider.callService.pipeline.retryFailed();
      }
      _toast = type == 'none' ? '网络已断开' : '网络已恢复 ($type)';
      notifyListeners();
    });
  }

  // ── 会话恢复 ──

  Future<void> _tryRestore() async {
    final snapshot = await SessionRestoreService.tryRestore();
    if (snapshot != null) {
      await callProvider.resume(snapshot);
    }
  }

  void _persistSnapshot(Map<String, dynamic> data) async {
    final snapshot = CallSnapshot.fromJson(data);
    await SessionRestoreService.save(snapshot);
  }

  void _clearSnapshot() async {
    await SessionRestoreService.clear();
  }

  // ── 通话记录 ──

  void _saveCallRecord(Map<String, dynamic> data) async {
    final record = CallRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peerName: data['peer'] as String,
      startTime: DateTime.parse(data['startTime'] as String),
      durationSeconds: data['duration'] as int,
      lastTranscript: data['transcript'] as String?,
    );
    _callHistory.insert(0, record);
    if (_callHistory.length > 100) {
      _callHistory.removeRange(100, _callHistory.length);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'call_history',
      jsonEncode(_callHistory.map((r) => r.toJson()).toList()),
    );
  }

  // ── 登录 / 登出 ──

  Future<void> login(String phone) async {
    _phone = phone;
    if (settings.serverUrl.isEmpty) {
      _toast = '请先设置服务器地址（设置页或连续点击Logo 5次进入开发者模式）';
      notifyListeners();
      return;
    }

    if (_authToken == null || _authToken!.isEmpty) {
      _toast = '正在获取认证...';
      notifyListeners();
      try {
        final baseUrl = settings.serverUrl
            .replaceAll('wss://', 'https://')
            .replaceAll('ws://', 'http://');
        final resp = await http
            .post(
              Uri.parse('$baseUrl/api/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phone': phone, 'password': phone}),
            )
            .timeout(const Duration(seconds: 10));
        final data = jsonDecode(resp.body) as Map;
        if (data['ok'] == true && data['token'] != null) {
          _authToken = data['token'] as String;
        } else {
          final regResp = await http
              .post(
                Uri.parse('$baseUrl/api/register'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'username': phone,
                  'phone': phone,
                  'password': phone,
                }),
              )
              .timeout(const Duration(seconds: 10));
          final regData = jsonDecode(regResp.body) as Map;
          if (regData['ok'] == true && regData['token'] != null) {
            _authToken = regData['token'] as String;
          }
        }
      } catch (e) {
        // REST API 不可用时，继续无 token 连接
      }
    }

    _toast = '正在连接...';
    notifyListeners();
    await signaling.connect(settings.serverUrl, phone, token: _authToken);
    await Future.delayed(Duration.zero);
    if (!_connected) {
      _toast = '网络连接失败，请检查服务器地址和网络';
      notifyListeners();
    }
  }

  void logout() {
    signaling.disconnect();
    _connected = false;
    _phone = null;
    notifyListeners();
  }

  /// 保存 JWT Token（从 REST API 登录/注册获取）
  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearToast() {
    _toast = null;
    notifyListeners();
  }
}
