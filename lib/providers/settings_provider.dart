import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:ui' show Locale;

/// 设置状态 — 持久化到 SharedPreferences + FlutterSecureStorage
///
/// 职责：
///   - 服务器地址、API Key、语言偏好、TTS 开关
///   - SharedPreferences 读写
///   - FlutterSecureStorage 加密存储
class SettingsProvider extends ChangeNotifier {
  // ── 服务器 ──
  String _serverUrl = '';
  String get serverUrl => _serverUrl;

  // ── API Key（旧版 DeepSeek Key，通过 SharedPreferences）──
  String _apiKey = '';
  String get apiKey => _apiKey;

  // ── 语言 ──
  Locale _locale = const Locale('zh', 'CN');
  Locale get locale => _locale;

  String _myLang = 'zh-CN';
  String get myLang => _myLang;
  String _peerLang = 'en-US';
  String get peerLang => _peerLang;

  // ── TTS ──
  bool _ttsEnabled = true;
  bool get ttsEnabled => _ttsEnabled;

  /// 从 SharedPreferences 加载所有设置
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key') ?? '';
    _myLang = prefs.getString('my_lang') ?? 'zh-CN';
    _peerLang = prefs.getString('peer_lang') ?? 'en-US';
    _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
    _serverUrl = prefs.getString('server_url') ?? '';
    notifyListeners();
  }

  /// 加载加密存储的 API Key
  Future<String?> loadSecureApiKey() async {
    try {
      const secure = FlutterSecureStorage();
      return await secure.read(key: 'translation_api_key');
    } catch (_) {
      return null;
    }
  }

  /// 批量保存所有设置
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

    notifyListeners();
  }

  Future<void> setServer(String url) async {
    _serverUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
