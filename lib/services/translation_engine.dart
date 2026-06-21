import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'translation_service.dart';

/// 翻译引擎 — 持续监听麦克风 → 翻译 → 回调
class TranslationEngine {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TranslationService _translation;

  bool _isRunning = false;
  bool _initialized = false;
  String _myLang = 'zh-CN';
  String _peerLang = 'en-US';

  // 事件流
  final StreamController<TranslateResult> _results = StreamController.broadcast();
  Stream<TranslateResult> get results => _results.stream;

  // 识别文本 (调试)
  String get currentLang => _myLang;

  TranslationEngine({required TranslationService translation}) : _translation = translation;

  void setLanguages({required String myLang, required String peerLang}) {
    _myLang = myLang;
    _peerLang = peerLang;
  }

  /// 初始化
  Future<bool> init() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  /// 开始持续监听
  Future<void> start() async {
    if (_isRunning) return;
    if (!await init()) {
      _results.add(TranslateResult.error('语音识别初始化失败'));
      return;
    }
    _isRunning = true;
    _listen();
  }

  /// 单次监听循环
  Future<void> _listen() async {
    while (_isRunning) {
      final completer = Completer<void>();
      String recognized = '';

      await _speech.listen(
        onResult: (result) {
          recognized = result.recognizedWords;
          if (result.finalResult) {
            if (!completer.isCompleted) completer.complete();
          }
        },
        localeId: _myLang,
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      );

      // 等待结果或超时 (最多等 5 秒)
      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 5)),
      ]);

      await _speech.stop();

      if (recognized.isNotEmpty) {
        _results.add(TranslateResult.recognized(recognized, _myLang));

        // 翻译
        try {
          final translated = await _translation.translate(
            text: recognized,
            from: _myLang,
            to: _peerLang,
          );
          _results.add(TranslateResult.translated(recognized, translated, _peerLang));
        } catch (e) {
          _results.add(TranslateResult.error('翻译失败: $e'));
        }
      }

      // 继续下一轮
      if (_isRunning) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  /// 停止
  Future<void> stop() async {
    _isRunning = false;
    await _speech.stop();
  }

  void dispose() {
    _isRunning = false;
    _speech.stop();
    _results.close();
  }
}

/// 翻译结果
class TranslateResult {
  final String type; // 'recognized' | 'translated' | 'error'
  final String original;
  final String translated;
  final String? language;
  final String? error;

  TranslateResult._({
    required this.type,
    required this.original,
    this.translated = '',
    this.language,
    this.error,
  });

  factory TranslateResult.recognized(String text, String lang) =>
      TranslateResult._(type: 'recognized', original: text, language: lang);

  factory TranslateResult.translated(String original, String translated, String lang) =>
      TranslateResult._(type: 'translated', original: original, translated: translated, language: lang);

  factory TranslateResult.error(String msg) =>
      TranslateResult._(type: 'error', original: '', error: msg);
}
