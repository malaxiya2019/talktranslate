import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/language.dart';
import '../services/translation_service.dart';
import '../services/translation_engine.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

/// App 全局状态
class AppProvider extends ChangeNotifier {
  final TranslationService translationService = TranslationService();
  late final STTService sttService;
  late final TTSService ttsService;
  late final TranslationEngine translationEngine;

  Language _myLanguage = Language.supported[0];
  Language _peerLanguage = Language.supported[1];
  Language get myLanguage => _myLanguage;
  Language get peerLanguage => _peerLanguage;

  bool _isTranslating = false;
  bool get isTranslating => _isTranslating;

  String _originalText = '';
  String _translatedText = '';
  String get originalText => _originalText;
  String get translatedText => _translatedText;

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

    translationEngine.events.listen((event) {
      switch (event.type) {
        case TranslationEventType.recognized:
          _originalText = event.text;
          notifyListeners();
        case TranslationEventType.translated:
          _translatedText = event.text;
          notifyListeners();
        case TranslationEventType.listening:
        case TranslationEventType.stopped:
          _isTranslating = event.type == TranslationEventType.listening;
          notifyListeners();
        default:
          break;
      }
    });
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

  Future<void> startTranslation() async {
    translationEngine.setLanguages(myLang: _myLanguage.code, peerLang: _peerLanguage.code);
    translationEngine.startListening();
  }

  Future<void> stopTranslation() async {
    await translationEngine.stop();
    _originalText = '';
    _translatedText = '';
    _isTranslating = false;
    notifyListeners();
  }

  @override
  void dispose() {
    translationEngine.dispose();
    sttService.dispose();
    ttsService.dispose();
    super.dispose();
  }
}
