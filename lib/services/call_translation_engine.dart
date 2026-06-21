import '../services/translation_service.dart';

/// 通话翻译引擎 — 实时翻译通话中的文本
class CallTranslationEngine {
  final TranslationService _translation;
  String _myLang = 'zh-CN';
  String _peerLang = 'en-US';

  // 翻译结果回调
  void Function(String original, String translated)? onTranslated;

  CallTranslationEngine({required TranslationService translation}) : _translation = translation;

  void setLanguages({required String myLang, required String peerLang}) {
    _myLang = myLang;
    _peerLang = peerLang;
  }

  /// 翻译文本 (由 UI 触发，发送前翻译)
  Future<String> translateMySpeech(String text) async {
    if (text.isEmpty) return '';
    final translated = await _translation.translate(
      text: text,
      from: _myLang,
      to: _peerLang,
    );
    onTranslated?.call(text, translated);
    return translated;
  }

  /// 翻译对方文本
  Future<String> translatePeerSpeech(String text) async {
    if (text.isEmpty) return '';
    final translated = await _translation.translate(
      text: text,
      from: _peerLang,
      to: _myLang,
    );
    onTranslated?.call(text, translated);
    return translated;
  }
}
