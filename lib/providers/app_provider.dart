import 'package:flutter/foundation.dart';
import '../models/language.dart';
import '../services/signaling_service.dart';
import '../services/call_service.dart';
import '../services/call_translation_engine.dart';
import '../services/translation_service.dart';
import 'dart:async';

/// App 全局状态
class AppProvider extends ChangeNotifier {
  // 服务
  final SignalingService signaling = SignalingService();
  late final CallService callService;
  final TranslationService translationService = TranslationService();
  late final CallTranslationEngine translationEngine;

  // 语言
  Language _myLanguage = Language.supported[0];
  Language _peerLanguage = Language.supported[1];
  Language get myLanguage => _myLanguage;
  Language get peerLanguage => _peerLanguage;

  // 通话
  CallState get callState => callService.state;

  // 手机号
  String? _phone;
  String? get phone => _phone;

  // 在线用户
  List<String> _onlineUsers = [];
  List<String> get onlineUsers => _onlineUsers;

  // 翻译文本
  String _originalText = '';
  String _translatedText = '';
  String get originalText => _originalText;
  String get translatedText => _translatedText;

  // 信令服务器地址
  String _serverUrl = 'ws://localhost:3459';
  String get serverUrl => _serverUrl;

  // 连接状态
  bool _connected = false;
  bool get connected => _connected;

  // API Key
  String? _apiKey;
  String? get apiKey => _apiKey;

  List<StreamSubscription> _subs = [];

  AppProvider() {
    callService = CallService(signaling);
    translationEngine = CallTranslationEngine(translation: translationService);

    _subs.add(callService.events.listen((event) {
      if (event.type == 'state-change') notifyListeners();
      if (event.type == 'call-ended') {
        _originalText = '';
        _translatedText = '';
        notifyListeners();
      }
    }));

    _subs.add(signaling.events.listen((event) {
      switch (event.type) {
        case 'registered':
          _connected = true;
          _phone = event.data as String?;
          notifyListeners();
        case 'incoming':
          final data = event.data as Map;
          callService.answerCall(data['callId'], data['from']);
          notifyListeners();
        case 'online-list':
          _onlineUsers = List<String>.from(event.data as List);
          notifyListeners();
        case 'disconnected':
          _connected = false;
          notifyListeners();
      }
    }));
  }

  void setServerUrl(String url) {
    _serverUrl = url;
    notifyListeners();
  }

  Future<void> connect(String phone) async {
    await signaling.connect(_serverUrl, phone);
  }

  void disconnect() {
    signaling.disconnect();
    _connected = false;
    notifyListeners();
  }

  void setMyLanguage(Language lang) {
    _myLanguage = lang;
    translationEngine.setLanguages(myLang: lang.code, peerLang: _peerLanguage.code);
    notifyListeners();
  }

  void setPeerLanguage(Language lang) {
    _peerLanguage = lang;
    translationEngine.setLanguages(myLang: _myLanguage.code, peerLang: lang.code);
    notifyListeners();
  }

  void swapLanguages() {
    final temp = _myLanguage;
    _myLanguage = _peerLanguage;
    _peerLanguage = temp;
    translationEngine.setLanguages(myLang: _myLanguage.code, peerLang: _peerLanguage.code);
    notifyListeners();
  }

  void setApiKey(String key) {
    _apiKey = key;
    translationService.setApiKey(key);
    notifyListeners();
  }

  Future<void> startCall(String to) async {
    await callService.startCall(to);
  }

  Future<void> acceptIncomingCall() async {
    await callService.acceptCall();
  }

  Future<void> rejectIncomingCall() async {
    await callService.rejectCall();
  }

  Future<void> endCall() async {
    await callService.hangUp();
  }

  /// 翻译我方语音 (发送前)
  Future<String> translateMyText(String text) async {
    _originalText = text;
    final translated = await translationEngine.translateMySpeech(text);
    _translatedText = translated;
    notifyListeners();
    return translated;
  }

  /// 翻译对方文本
  Future<String> translatePeerText(String text) async {
    _originalText = text;
    final translated = await translationEngine.translatePeerSpeech(text);
    _translatedText = translated;
    notifyListeners();
    return translated;
  }

  @override
  void dispose() {
    for (final sub in _subs) sub.cancel();
    callService.dispose();
    signaling.dispose();
    super.dispose();
  }
}
