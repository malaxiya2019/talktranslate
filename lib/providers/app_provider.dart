import 'package:flutter/foundation.dart';
import '../models/language.dart';
import '../models/call.dart';
import '../services/call_service.dart';
import '../services/translation_service.dart';
import '../services/translation_engine.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

/// App 全局状态
class AppProvider extends ChangeNotifier {
  // 服务
  final CallService callService = CallService();
  final TranslationService translationService = TranslationService();
  late final STTService sttService;
  late final TTSService ttsService;
  late final TranslationEngine translationEngine;

  // 语言设置
  Language _myLanguage = Language.supported[0]; // 中文
  Language _peerLanguage = Language.supported[1]; // 英文
  Language? get myLanguage => _myLanguage;
  Language? get peerLanguage => _peerLanguage;

  // 通话状态
  CallStatus _callStatus = CallStatus.idle;
  CallStatus get callStatus => _callStatus;

  // 翻译文本 (UI 显示)
  String _originalText = '';
  String _translatedText = '';
  String get originalText => _originalText;
  String get translatedText => _translatedText;

  // 设置
  String? _apiKey;
  String? get apiKey => _apiKey;

  AppProvider() {
    sttService = STTService();
    ttsService = TTSService();
    translationEngine = TranslationEngine(
      stt: sttService,
      tts: ttsService,
      translation: translationService,
    );

    // 监听翻译引擎事件
    translationEngine.events.listen((event) {
      switch (event.type) {
        case TranslationEventType.recognized:
          _originalText = event.text;
          break;
        case TranslationEventType.translated:
          _translatedText = event.text;
          break;
        case TranslationEventType.error:
          _translatedText = event.text;
          break;
        default:
          break;
      }
      notifyListeners();
    });

    // 监听通话事件
    callService.events.listen((event) {
      switch (event.type) {
        case CallEventType.calling:
          _callStatus = CallStatus.calling;
          break;
        case CallEventType.connected:
          _callStatus = CallStatus.connected;
          break;
        case CallEventType.ended:
          _callStatus = CallStatus.ended;
          break;
      }
      notifyListeners();
    });
  }

  /// 设置语言
  void setMyLanguage(Language lang) {
    _myLanguage = lang;
    translationEngine.setLanguages(
      myLang: lang.code,
      peerLang: _peerLanguage.code,
    );
    notifyListeners();
  }

  void setPeerLanguage(Language lang) {
    _peerLanguage = lang;
    translationEngine.setLanguages(
      myLang: _myLanguage.code,
      peerLang: lang.code,
    );
    notifyListeners();
  }

  /// 交换语言
  void swapLanguages() {
    final temp = _myLanguage;
    _myLanguage = _peerLanguage;
    _peerLanguage = temp;
    translationEngine.setLanguages(
      myLang: _myLanguage.code,
      peerLang: _peerLanguage.code,
    );
    notifyListeners();
  }

  /// 设置 API Key
  void setApiKey(String key) {
    _apiKey = key;
    translationService.setApiKey(key);
    notifyListeners();
  }

  /// 开始通话
  Future<void> startCall(String peerId) async {
    await callService.startCall(peerId);
    await callService.getLocalStream();
    // 开始翻译
    translationEngine.setLanguages(
      myLang: _myLanguage.code,
      peerLang: _peerLanguage.code,
    );
    translationEngine.startListening();
  }

  /// 接听通话
  Future<void> answerCall(String callId) async {
    await callService.answerCall(callId);
    await callService.getLocalStream();
    translationEngine.setLanguages(
      myLang: _myLanguage.code,
      peerLang: _peerLanguage.code,
    );
    translationEngine.startListening();
  }

  /// 结束通话
  Future<void> endCall() async {
    await translationEngine.stop();
    await callService.endCall();
    _callStatus = CallStatus.idle;
    _originalText = '';
    _translatedText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    translationEngine.dispose();
    callService.dispose();
    sttService.dispose();
    ttsService.dispose();
    super.dispose();
  }
}
