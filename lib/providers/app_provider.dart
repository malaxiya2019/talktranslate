import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/signaling_service.dart';
import '../services/call_service.dart';
import '../services/session_restore_service.dart';
import '../models/call.dart';

/// 全局状态 — 通过 init() 异步初始化
///
/// 启动时序（main.dart）：
///   WidgetsFlutterBinding → AppProvider() → await init() → runApp()
class AppProvider extends ChangeNotifier {
  final signaling = SignalingService();
  late final CallService callService;

  bool _initialized = false;
  bool get initialized => _initialized;

  // ── 账户 ──
  String? _phone;
  String? get phone => _phone;
  bool _connected = false;
  bool get connected => _connected;
  List<String> _onlineUsers = [];
  List<String> get onlineUsers => _onlineUsers;

  // ── 服务器 ──
  String _serverUrl = 'ws://localhost:3459';
  String get serverUrl => _serverUrl;

  // ── API Key ──
  String _apiKey = '';
  String get apiKey => _apiKey;

  // ── 语言 ──
  String _myLang = 'zh-CN';
  String get myLang => _myLang;
  String _peerLang = 'en-US';
  String get peerLang => _peerLang;

  // ── TTS ──
  bool _ttsEnabled = true;
  bool get ttsEnabled => _ttsEnabled;

  // ── 通话记录 ──
  List<CallRecord> _callHistory = [];
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);

  // ── Toast ──
  String? _toast;
  String? get toast => _toast;

  /// 构造函数：只注册事件监听，不做 IO
  AppProvider() {
    callService = CallService(signaling);

    signaling.events.listen((e) {
      switch (e['type']) {
        case 'registered': _connected = true; _phone = e['phone']; notifyListeners(); break;
        case 'disconnected': _connected = false; notifyListeners(); break;
        case 'online': _onlineUsers = List<String>.from(e['users']); notifyListeners(); break;
        case 'incoming': callService.incoming(e['callId'], e['from']); notifyListeners(); break;
        case 'error': _toast = e['message']; notifyListeners(); break;
      }
    });

    callService.events.listen((e) {
      if (e['type'] == 'toast') { _toast = e['message']; notifyListeners(); }
      if (e['type'] == 'status' || e['type'] == 'subtitle' || e['type'] == 'mySpeech') notifyListeners();
      if (e['type'] == 'call_record') _saveCallRecord(e);
      if (e['type'] == 'snapshot') _persistSnapshot(Map<String, dynamic>.from(e['snapshot'] as Map));
      if (e['type'] == 'snapshot_clear') _clearSnapshot();
    });
  }

  /// 异步初始化：加载设置 → 恢复通话 → 标记就绪
  Future<void> init() async {
    await _loadSettings();
    await _tryRestore();
    _initialized = true;
    notifyListeners();
  }

  // ── 持久化 ──

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key') ?? '';
    _myLang = prefs.getString('my_lang') ?? 'zh-CN';
    _peerLang = prefs.getString('peer_lang') ?? 'en-US';
    _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
    _serverUrl = prefs.getString('server_url') ?? 'ws://localhost:3459';
    _callHistory = _loadCallHistory(prefs);

    // 注入到服务层
    callService.pipeline.setApiKey(_apiKey);
    callService.pipeline.setLanguages(_myLang, _peerLang);
    callService.pipeline.setTtsEnabled(_ttsEnabled);

    notifyListeners();
  }

  /// 尝试恢复上次通话
  Future<void> _tryRestore() async {
    final snapshot = await SessionRestoreService.tryRestore();
    if (snapshot != null) {
      await callService.resume(snapshot);
    }
  }

  void _persistSnapshot(Map<String, dynamic> data) async {
    final snapshot = CallSnapshot.fromJson(data);
    await SessionRestoreService.save(snapshot);
  }

  void _clearSnapshot() async {
    await SessionRestoreService.clear();
  }

  List<CallRecord> _loadCallHistory(SharedPreferences prefs) {
    final json = prefs.getString('call_history');
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.cast<Map<String, dynamic>>().map((m) => CallRecord.fromJson(m)).toList();
    } catch (_) {
      return [];
    }
  }

  void _saveCallRecord(Map<String, dynamic> data) async {
    final record = CallRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peerName: data['peer'] as String,
      startTime: DateTime.parse(data['startTime'] as String),
      durationSeconds: data['duration'] as int,
      lastTranscript: data['transcript'] as String?,
    );
    _callHistory.insert(0, record);
    if (_callHistory.length > 100) _callHistory.removeRange(100, _callHistory.length);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('call_history', jsonEncode(_callHistory.map((r) => r.toJson()).toList()));
  }

  Future<void> saveSettings({
    required String apiKey,
    required String serverUrl,
    required String myLang,
    required String peerLang,
    required bool ttsEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', apiKey);
    await prefs.setString('server_url', serverUrl);
    await prefs.setString('my_lang', myLang);
    await prefs.setString('peer_lang', peerLang);
    await prefs.setBool('tts_enabled', ttsEnabled);

    _apiKey = apiKey;
    _serverUrl = serverUrl;
    _myLang = myLang;
    _peerLang = peerLang;
    _ttsEnabled = ttsEnabled;

    callService.pipeline.setApiKey(apiKey);
    callService.pipeline.setLanguages(myLang, peerLang);
    callService.pipeline.setTtsEnabled(ttsEnabled);

    notifyListeners();
  }

  void setServer(String url) { _serverUrl = url; notifyListeners(); }

  Future<void> login(String phone) async {
    _phone = phone;
    await signaling.connect(_serverUrl, phone);
  }

  void logout() { signaling.disconnect(); _connected = false; _phone = null; notifyListeners(); }

  CallState get callState => callService.state;
  CallState get callStatus => callService.state;
  String? get peerPhone => callService.peerPhone;

  String get subtitle => callService.subtitle;
  String get subtitleTranslated => callService.subtitleTranslated;
  String get mySpeech => callService.mySpeech;
  String get mySpeechTranslated => callService.mySpeechTranslated;

  void enterBackgroundMode() => callService.enterBackgroundMode();

  Future<void> call(String to) async => await callService.call(to);
  Future<void> accept() async => await callService.accept();
  Future<void> reject() async => await callService.reject();
  Future<void> hangup() async => await callService.hangup();

  void clearToast() { _toast = null; notifyListeners(); }
}
