import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'translation_service.dart';

/// 翻译结果
class TranslationResult {
  final String original;
  final String translated;
  final String sourceLang;
  final String targetLang;

  const TranslationResult({
    required this.original,
    required this.translated,
    required this.sourceLang,
    required this.targetLang,
  });
}

/// 统一管道: STT → Translate → TTS
///
/// 职责：
///   - 语音识别（STT）
///   - AI 翻译
///   - 语音朗读（TTS）
///
/// 输出：Stream<TranslationResult>
class TranslationPipeline {
  final TranslationService _translator;
  final FlutterTts _tts;

  stt.SpeechToText? _speech;
  bool _running = false;

  String _myLang = 'zh-CN';
  String _peerLang = 'en-US';
  bool _ttsEnabled = true;

  /// 本端语音识别结果回调 (text, translated)
  void Function(String text, String translated)? onMySpeech;

  final _resultCtl = StreamController<TranslationResult>.broadcast();
  Stream<TranslationResult> get onResult => _resultCtl.stream;

  TranslationPipeline()
    : _translator = TranslationService(),
      _tts = FlutterTts() {
    _initTts();
  }

  // ── 配置 ──

  void setApiKey(String key) => _translator.setApiKey(key);
  void setLanguages(String my, String peer) {
    _myLang = my;
    _peerLang = peer;
  }

  void setTtsEnabled(bool v) => _ttsEnabled = v;

  // ── 对外翻译（对方说的 → 翻译给我听）──

  Future<String> translate(String text, {String? from, String? to}) async {
    if (text.isEmpty) return '';
    try {
      return await _translator.translate(
        text,
        from ?? _peerLang,
        to ?? _myLang,
      );
    } catch (_) {
      return '[翻译失败] $text';
    }
  }

  Future<void> speak(String text, {String? lang}) async {
    if (!_ttsEnabled || text.isEmpty) return;
    try {
      await _tts.setLanguage(_mapTtsLang(lang ?? _myLang));
      await _tts.speak(text);
    } catch (_) {}
  }

  // ── 本端语音识别（我说的 → 翻译给对面）──

  /// 开始语音识别
  Future<void> start() async {
    if (_running) return;
    _speech ??= stt.SpeechToText();
    final ok = await _speech!.initialize();
    if (!ok) return;
    _running = true;
    _listen();
  }

  void _listen() async {
    while (_running) {
      final completer = Completer<void>();
      String text = '';

      await _speech!.listen(
        onResult: (r) {
          text = r.recognizedWords;
          if (r.finalResult && !completer.isCompleted) completer.complete();
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: _sttLocale(_myLang),
          cancelOnError: true,
          partialResults: true,
        ),
      );

      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 5)),
      ]);

      await _speech!.stop();

      if (text.isNotEmpty) {
        String translated = '';
        try {
          translated = await _translator.translate(text, _myLang, _peerLang);
        } catch (_) {}
        _resultCtl.add(
          TranslationResult(
            original: text,
            translated: translated,
            sourceLang: _myLang,
            targetLang: _peerLang,
          ),
        );
        onMySpeech?.call(text, translated);
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> stop() async {
    _running = false;
    await _speech?.stop();
  }

  bool get isRunning => _running;

  // ── 辅助 ──

  void dispose() {
    stop();
    _resultCtl.close();
  }

  String _sttLocale(String code) {
    const map = {
      'zh-CN': 'zh_CN',
      'en-US': 'en_US',
      'ja-JP': 'ja_JP',
      'ko-KR': 'ko_KR',
      'es-ES': 'es_ES',
      'fr-FR': 'fr_FR',
      'de-DE': 'de_DE',
      'pt-BR': 'pt_BR',
      'ru-RU': 'ru_RU',
      'ar-SA': 'ar_SA',
      'th-TH': 'th_TH',
      'vi-VN': 'vi_VN',
    };
    return map[code] ?? 'en_US';
  }

  String _mapTtsLang(String code) {
    const map = {
      'zh-CN': 'zh-CN',
      'en-US': 'en-US',
      'ja-JP': 'ja-JP',
      'ko-KR': 'ko-KR',
      'es-ES': 'es-ES',
      'fr-FR': 'fr-FR',
      'de-DE': 'de-DE',
      'pt-BR': 'pt-BR',
      'ru-RU': 'ru-RU',
    };
    return map[code] ?? 'en-US';
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }
}
