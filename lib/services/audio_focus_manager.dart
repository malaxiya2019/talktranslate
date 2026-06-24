import 'package:flutter/services.dart';

/// 音频焦点管理 — 处理系统电话/微信语音切入
///
/// 当遭遇系统电话、微信语音切入时自动执行：
///   duck — 压低音量
///   pause — 暂停并释放音频流
///   挂断后自动恢复重连
class AudioFocusManager {
  static const _channel = MethodChannel('talktranslate/audio_focus');

  static final AudioFocusManager _instance = AudioFocusManager._();
  factory AudioFocusManager() => _instance;
  AudioFocusManager._();

  bool _hasFocus = true;
  bool get hasFocus => _hasFocus;

  /// 请求音频焦点 (通话开始时调用)
  Future<void> requestFocus() async {
    try {
      final result = await _channel.invokeMethod('requestFocus');
      _hasFocus = result == true;
    } catch (_) {
      _hasFocus = true; // 非Android平台默认通过
    }
  }

  /// 放弃音频焦点 (通话结束时调用)
  Future<void> abandonFocus() async {
    try {
      await _channel.invokeMethod('abandonFocus');
    } catch (_) {}
    _hasFocus = false;
  }

  /// 监听音频焦点变化
  void Function(bool hasFocus)? onFocusChange;
}
