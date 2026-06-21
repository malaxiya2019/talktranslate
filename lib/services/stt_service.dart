import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// 语音识别服务 (STT)
class STTService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  StreamSubscription? _subscription;

  bool get isListening => _speech.isListening;

  /// 初始化
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize();
    return _initialized;
  }

  /// 开始监听
  Stream<String> startListening(String locale) async* {
    if (!await initialize()) {
      yield '[STT初始化失败]';
      return;
    }

    final completer = Completer<void>();
    String buffer = '';

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          buffer = result.recognizedWords;
          if (!completer.isCompleted) completer.complete();
        }
      },
      localeId: locale,
      cancelOnError: true,
      partialResults: true,
    );

    // 等待结果或超时 (max 10s per utterance)
    await Future.any([
      completer.future,
      Future.delayed(const Duration(seconds: 10)),
    ]);

    await stop();
    yield buffer;
  }

  /// 停止监听
  Future<void> stop() async {
    await _speech.stop();
  }

  void dispose() {
    _subscription?.cancel();
    _speech.stop();
  }
}
