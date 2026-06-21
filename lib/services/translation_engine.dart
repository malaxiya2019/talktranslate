import 'dart:async';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/translation_service.dart';

/// 翻译引擎 — 实时语音链: STT → 翻译 → TTS
class TranslationEngine {
  final STTService _stt;
  final TTSService _tts;
  final TranslationService _translation;

  bool _isRunning = false;
  String _myLang = 'zh-CN';
  String _peerLang = 'en-US';

  // 事件流
  final StreamController<TranslationEvent> _events = StreamController.broadcast();
  Stream<TranslationEvent> get events => _events.stream;

  TranslationEngine({
    required STTService stt,
    required TTSService tts,
    required TranslationService translation,
  })  : _stt = stt,
        _tts = tts,
        _translation = translation;

  /// 设置语言对
  void setLanguages({required String myLang, required String peerLang}) {
    _myLang = myLang;
    _peerLang = peerLang;
  }

  /// 开始翻译 — 监听我的语音 → 翻译成对方语言 → 播报
  Future<void> startListening() async {
    if (_isRunning) return;
    _isRunning = true;

    _events.add(TranslationEvent(
      type: TranslationEventType.listening,
      text: '🎤 倾听中...',
    ));

    // 监听本地语音
    final sttStream = _stt.startListening(_myLang);
    await for (final recognizedText in sttStream) {
      if (!_isRunning || recognizedText.isEmpty) break;

      _events.add(TranslationEvent(
        type: TranslationEventType.recognized,
        text: recognizedText,
        language: _myLang,
      ));

      // 翻译
      try {
        final translated = await _translation.translate(
          text: recognizedText,
          from: _myLang,
          to: _peerLang,
        );

        _events.add(TranslationEvent(
          type: TranslationEventType.translated,
          text: translated,
          language: _peerLang,
        ));

        // 播报翻译结果 (对方听到)
        await _tts.speak(translated, _peerLang);
      } catch (e) {
        _events.add(TranslationEvent(
          type: TranslationEventType.error,
          text: '翻译失败: $e',
        ));
      }

      // 继续监听下一句
      if (_isRunning) {
        _events.add(TranslationEvent(
          type: TranslationEventType.listening,
          text: '🎤 倾听中...',
        ));
      }
    }
  }

  /// 停止翻译
  Future<void> stop() async {
    _isRunning = false;
    await _stt.stop();
    await _tts.stop();
    _events.add(TranslationEvent(
      type: TranslationEventType.stopped,
      text: '⏹ 已停止',
    ));
  }

  void dispose() {
    _isRunning = false;
    _events.close();
  }
}

/// 翻译事件
class TranslationEvent {
  final TranslationEventType type;
  final String text;
  final String? language;

  const TranslationEvent({
    required this.type,
    required this.text,
    this.language,
  });
}

enum TranslationEventType {
  listening,
  recognized,
  translating,
  translated,
  error,
  stopped,
}
