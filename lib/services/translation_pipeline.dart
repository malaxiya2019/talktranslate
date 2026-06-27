import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../models/language.dart';
import 'translation_service.dart';
import 'engine_config_service.dart';

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
///   - AI 翻译（多引擎自动回退）
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

  TranslationPipeline({EngineConfigService? config})
    : _translator = TranslationService(config: config),
      _tts = FlutterTts() {
    _initTts();
  }

  // ── 配置 ──

  /// 设置 DeepSeek API Key（兼容旧接口）
  void setApiKey(String key) => _translator.setApiKey(key);

  /// 设置引擎优先级列表
  void setEnginePriority(List<TranslationEngine> engines) {
    _translator.setEnginePriority(engines);
  }

  void setLanguages(String my, String peer) {
    _myLang = my;
    _peerLang = peer;
  }

  void setTtsEnabled(bool v) => _ttsEnabled = v;

  /// 当前待重试的失败翻译条目数
  int get pendingRetryCount => _translator.pendingRetryCount;

  /// 重试所有失败的翻译
  Future<int> retryFailed() => _translator.retryFailed();

  /// 重试成功的回调
  void Function(RetryEntry entry, String translated)? get onRetrySuccess =>
      _translator.onRetrySuccess;
  set onRetrySuccess(void Function(RetryEntry entry, String translated)? cb) =>
      _translator.onRetrySuccess = cb;

  // ── 对外翻译（对方说的 → 翻译给我听）──

  Future<String> translate(String text, {String? from, String? to}) async {
    if (text.isEmpty) return '';
    // TranslationService 内部已处理所有错误和回退
    return await _translator.translate(
      text,
      from ?? _peerLang,
      to ?? _myLang,
    );
  }

  Future<void> speak(String text, {String? lang}) async {
    if (!_ttsEnabled || text.isEmpty) return;
    try {
      await _tts.setLanguage(LanguageUtil.ttsLocale(lang ?? _myLang));
      await _tts.speak(text);
    } catch (_) {}
  }

  // ── 本端语音识别（我说的 → 翻译给对面）──

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
      // 事件驱动监听：不再轮询 stop/restart
      // pauseFor 参数控制静默自动停止，无需人工超时
      try {
        await _speech!.listen(
          onResult: (r) {
            if (r.finalResult && r.recognizedWords.isNotEmpty) {
              _onSpeechResult(r.recognizedWords);
            }
          },
          listenOptions: stt.SpeechListenOptions(
            localeId: LanguageUtil.sttLocale(_myLang),
            cancelOnError: true,
            partialResults: true,
            listenMode: stt.ListenMode.confirmation,
            pauseFor: const Duration(seconds: 2),
          ),
        );
      } catch (_) {
        // 监听异常退出（如语音权限丢失），短暂等待后重试
      }

      // listen() 因 pauseFor 静默超时或异常自然结束
      // 如果仍在运行，短暂停顿后重新开始监听
      if (_running) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  /// 事件驱动：收到一次完整语音结果后立即处理
  void _onSpeechResult(String text) {
    // 异步处理，不阻塞 onResult 回调
    unawaited(_processSpeechResult(text));
  }

  Future<void> _processSpeechResult(String text) async {
    if (text.isEmpty) return;
    try {
      final translated = await _translator.translate(text, _myLang, _peerLang);
      _resultCtl.add(
        TranslationResult(
          original: text,
          translated: translated,
          sourceLang: _myLang,
          targetLang: _peerLang,
        ),
      );
      onMySpeech?.call(text, translated);
    } catch (e) {
      // 翻译失败时仍保留原文，让 UI 层决定如何处理
      _resultCtl.add(
        TranslationResult(
          original: text,
          translated: '[翻译失败]',
          sourceLang: _myLang,
          targetLang: _peerLang,
        ),
      );
    }
  }

  Future<void> stop() async {
    _running = false;
    await _speech?.stop();
  }

  bool get isRunning => _running;

  void dispose() {
    stop();
    _resultCtl.close();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }
}
