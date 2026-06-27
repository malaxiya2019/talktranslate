import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/language.dart';
import 'translation_service.dart';
import 'engine_config_service.dart';

/// 翻译结果载荷
class TranslationPayload {
  final String text;
  final String translated;
  final DateTime timestamp;
  const TranslationPayload({
    required this.text,
    required this.translated,
    required this.timestamp,
  });
}

/// 双流异步管理器 — 解耦音频 RTC 流与文本翻译流
///
/// Pipeline A: WebRTC 全双工语音（零延迟传送到对端）
/// Pipeline B: ASR 文本流（由 VAD 触发，异步翻译后发送）
///
/// 两条管线互不阻塞：语音流不影响翻译，翻译不回堵语音。
class CallStreamManager {
  final TranslationService _translator;
  stt.SpeechToText? _speech;

  /// VAD 静音窗口（毫秒）— 对话翻译最优值 800ms
  final int silenceWindowMs = 800;

  bool _running = false;
  String _myLang = 'zh-CN';
  String _peerLang = 'en-US';

  final _payloadCtl = StreamController<TranslationPayload>.broadcast();
  Stream<TranslationPayload> get onPayload => _payloadCtl.stream;

  /// Pipeline A 回调：对端语音到达时调用
  void Function(String text, String translated)? onPeerSpeech;

  /// Pipeline B 回调：本端语音识别完成时调用
  void Function(String text, String translated)? onMySpeechComplete;

  CallStreamManager({EngineConfigService? config})
    : _translator = TranslationService(config: config);

  // ── 配置 ──

  void setApiKey(String key) => _translator.setApiKey(key);
  void setEnginePriority(List<TranslationEngine> engines) {
    _translator.setEnginePriority(engines);
  }
  void setLanguages(String my, String peer) {
    _myLang = my;
    _peerLang = peer;
  }

  // ── Pipeline A: 对端语音处理 ————————————————

  /// 收到对端语音原文，异步翻译并分发
  Future<void> onIncomingSpeech(String text) async {
    if (text.isEmpty) return;
    final translated = await _translator.translate(text, _peerLang, _myLang);
    _payloadCtl.add(TranslationPayload(
      text: text,
      translated: translated,
      timestamp: DateTime.now(),
    ));
    onPeerSpeech?.call(text, translated);
  }

  // ── Pipeline B: 本端 ASR 流 —————————————————

  /// 启动本端语音识别（VAD 驱动）
  Future<void> startListening() async {
    if (_running) return;
    _speech ??= stt.SpeechToText();
    final ok = await _speech!.initialize();
    if (!ok) return;
    _running = true;
    _listenLoop();
  }

  void _listenLoop() async {
    while (_running) {
      final completer = Completer<void>();
      String text = '';

      await _speech!.listen(
        onResult: (r) {
          text = r.recognizedWords;
          if (r.finalResult && !completer.isCompleted) completer.complete();
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: LanguageUtil.sttLocale(_myLang),
          cancelOnError: true,
          partialResults: true,
          listenMode: stt.ListenMode.confirmation,
          pauseFor: Duration(milliseconds: silenceWindowMs),
        ),
      );

      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 5)),
      ]);

      await _speech!.stop();

      if (text.isNotEmpty) {
        final translated = await _translator.translate(text, _myLang, _peerLang);
        _payloadCtl.add(TranslationPayload(
          text: text,
          translated: translated,
          timestamp: DateTime.now(),
        ));
        onMySpeechComplete?.call(text, translated);
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _running = false;
  }

  Future<void> stopListening() async {
    _running = false;
    await _speech?.stop();
  }

  void dispose() {
    stopListening();
    _payloadCtl.close();
  }
}
