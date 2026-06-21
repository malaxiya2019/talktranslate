import 'package:flutter_tts/flutter_tts.dart';

/// 语音合成服务 (TTS)
class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  /// 初始化
  Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  /// 朗读翻译结果
  Future<void> speak(String text, String language) async {
    await initialize();
    await _tts.setLanguage(_mapLangCode(language));
    await _tts.speak(text);
  }

  /// 停止朗读
  Future<void> stop() async {
    await _tts.stop();
  }

  /// 语言代码映射 (flutter_tts 使用的格式)
  String _mapLangCode(String code) {
    final map = {
      'zh-CN': 'zh-CN',
      'en-US': 'en-US',
      'ja-JP': 'ja-JP',
      'ko-KR': 'ko-KR',
      'es-ES': 'es-ES',
      'fr-FR': 'fr-FR',
      'de-DE': 'de-DE',
      'pt-BR': 'pt-BR',
      'ar-SA': 'ar-SA',
      'th-TH': 'th-TH',
      'vi-VN': 'vi-VN',
      'ru-RU': 'ru-RU',
    };
    return map[code] ?? 'en-US';
  }

  void dispose() {
    _tts.stop();
  }
}
