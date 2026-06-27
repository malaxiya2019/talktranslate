import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/call.dart';
import '../services/signaling_service.dart';
import '../services/call_service.dart';

/// 通话状态 — 封装 CallService，对外暴露 Selector 友好的字段
///
/// 职责：
///   - 持有 CallService 实例
///   - 转发通话状态（callState, subtitle, mySpeech, peerPhone, pingMs）
///   - 暴露通话操作方法（call, accept, reject, hangup, enterBackgroundMode）
///
/// 注意：CallProvider 本身不保存通话记录（由 AppProvider 处理）
class CallProvider extends ChangeNotifier {
  final CallService callService;

  CallProvider(SignalingService signaling)
      : callService = CallService(signaling) {
    callService.events.listen(_onCallEvent);
  }

  // ── 从 CallService 转发的只读字段 ──

  CallState get callState => callService.state;
  String? get peerPhone => callService.peerPhone;
  String get subtitle => callService.subtitle;
  String get subtitleTranslated => callService.subtitleTranslated;
  String get mySpeech => callService.mySpeech;
  String get mySpeechTranslated => callService.mySpeechTranslated;
  int get pingMs => callService.pingMs;

  // ── 事件处理 ──

  void _onCallEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'status':
      case 'subtitle':
      case 'mySpeech':
      case 'toast':
      case 'call_record':
      case 'snapshot':
      case 'snapshot_clear':
        notifyListeners();
    }
  }

  // ── 通话操作 ──

  Future<void> call(String to) => callService.call(to);
  Future<void> accept() => callService.accept();
  Future<void> reject() => callService.reject();
  Future<void> hangup() => callService.hangup();
  void enterBackgroundMode() => callService.enterBackgroundMode();

  /// 注入 API Key 到翻译管道
  void setPipelineApiKey(String key) {
    callService.pipeline.setApiKey(key);
  }

  /// 注入语言偏好到翻译管道
  void setPipelineLanguages(String myLang, String peerLang) {
    callService.pipeline.setLanguages(myLang, peerLang);
  }

  /// 注入 TTS 开关到翻译管道
  void setPipelineTts(bool enabled) {
    callService.pipeline.setTtsEnabled(enabled);
  }

  /// 从快照恢复通话
  Future<void> resume(CallSnapshot snapshot) =>
      callService.resume(snapshot);

  @override
  void dispose() {
    callService.dispose();
    super.dispose();
  }
}
