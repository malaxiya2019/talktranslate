import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'translation_service.dart';

/// 说话人
enum Speaker { me, peer }

/// 一条对话记录
class ConversationEntry {
  final Speaker speaker;
  final String original;
  final String translated;
  final DateTime timestamp;

  ConversationEntry({
    required this.speaker,
    required this.original,
    required this.translated,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 翻译引擎 — 持续监听麦克风 → 翻译 → 双向对话流
class TranslationEngine {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TranslationService _translation;

  bool _isRunning = false;
  bool _initialized = false;
  String _myLang = 'zh-CN';
  String _peerLang = 'en-US';

  // 双向字幕追踪
  Speaker _lastSpeaker = Speaker.peer; // 初始为对方，下一段就是"我"
  final List<ConversationEntry> _conversation = [];

  // 事件流
  final StreamController<TranslateResult> _results = StreamController.broadcast();
  Stream<TranslateResult> get results => _results.stream;

  List<ConversationEntry> get conversation => List.unmodifiable(_conversation);

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
    _conversation.clear();
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

      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 6)),
      ]);

      await _speech.stop();

      if (recognized.isNotEmpty) {
        // 交替说话人
        _lastSpeaker = _lastSpeaker == Speaker.me ? Speaker.peer : Speaker.me;

        // 识别事件
        _results.add(TranslateResult(
          type: 'recognized',
          original: recognized,
          language: _myLang,
          speaker: _lastSpeaker,
        ));

        // 翻译
        try {
          final translated = await _translation.translate(
            text: recognized,
            from: _myLang,
            to: _peerLang,
          );

          _conversation.add(ConversationEntry(
            speaker: _lastSpeaker,
            original: recognized,
            translated: translated,
          ));

          _results.add(TranslateResult(
            type: 'translated',
            original: recognized,
            translated: translated,
            language: _peerLang,
            speaker: _lastSpeaker,
          ));
        } catch (e) {
          _results.add(TranslateResult(type: 'error', original: recognized, error: '翻译失败: $e'));
        }
      }

      if (_isRunning) {
        await Future.delayed(const Duration(milliseconds: 400));
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
  final String type;
  final String original;
  final String translated;
  final String? language;
  final String? error;
  final Speaker? speaker;

  TranslateResult({
    required this.type,
    required this.original,
    this.translated = '',
    this.language,
    this.error,
    this.speaker,
  });

  factory TranslateResult.error(String msg) =>
      TranslateResult(type: 'error', original: '', error: msg);
}
