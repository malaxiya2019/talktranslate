import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/language.dart';
import '../services/translation_service.dart';
import '../services/translation_engine.dart';

/// App 全局状态
class AppProvider extends ChangeNotifier {
  final TranslationService translationService = TranslationService();
  late final TranslationEngine engine;

  Language _myLanguage = Language.supported[0];
  Language _peerLanguage = Language.supported[1];
  Language get myLanguage => _myLanguage;
  Language get peerLanguage => _peerLanguage;

  bool _isListening = false;
  bool get isListening => _isListening;

  String _originalText = '';
  String _translatedText = '';
  String get originalText => _originalText;
  String get translatedText => _translatedText;

  String? _apiKey;
  String? get apiKey => _apiKey;

  Speaker? _currentSpeaker;
  Speaker? get currentSpeaker => _currentSpeaker;
  List<ConversationEntry> get conversation => engine.conversation;

  StreamSubscription? _sub;

  AppProvider() {
    engine = TranslationEngine(translation: translationService);
    _sub = engine.results.listen((result) {
      switch (result.type) {
        case 'recognized':
          _originalText = result.original;
          _currentSpeaker = result.speaker;
          break;
        case 'translated':
          _translatedText = result.translated;
          _currentSpeaker = result.speaker;
          break;
        case 'error':
          _translatedText = '⚠ ${result.error}';
          break;
      }
      notifyListeners();
    });
  }

  void setMyLanguage(Language lang) {
    _myLanguage = lang;
    engine.setLanguages(myLang: lang.code, peerLang: _peerLanguage.code);
    notifyListeners();
  }

  void setPeerLanguage(Language lang) {
    _peerLanguage = lang;
    engine.setLanguages(myLang: _myLanguage.code, peerLang: lang.code);
    notifyListeners();
  }

  void swapLanguages() {
    final t = _myLanguage; _myLanguage = _peerLanguage; _peerLanguage = t;
    engine.setLanguages(myLang: _myLanguage.code, peerLang: _peerLanguage.code);
    notifyListeners();
  }

  void setApiKey(String key) {
    _apiKey = key;
    translationService.setApiKey(key);
    notifyListeners();
  }

  Future<void> startTranslation() async {
    engine.setLanguages(myLang: _myLanguage.code, peerLang: _peerLanguage.code);
    await engine.start();
    _isListening = true;
    notifyListeners();
  }

  Future<void> stopTranslation() async {
    await engine.stop();
    _isListening = false;
    _originalText = '';
    _translatedText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    engine.dispose();
    super.dispose();
  }
}
