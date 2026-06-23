import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../models/call.dart';

/// 字幕缓存项
class _SubtitleItem {
  final String text;
  final String translated;
  final DateTime time;
  const _SubtitleItem(this.text, this.translated, this.time);
}

/// 字幕环形缓冲区 — 最多保留 50 条，show() 时回放
class SubtitleBuffer {
  final List<_SubtitleItem> _buffer = [];
  static const _max = 50;

  void add(String text, String translated) {
    _buffer.add(_SubtitleItem(text, translated, DateTime.now()));
    if (_buffer.length > _max) _buffer.removeAt(0);
  }

  /// 获取最近 N 条
  List<_SubtitleItem> recent(int n) =>
      _buffer.sublist((_buffer.length - n).clamp(0, _buffer.length));

  void clear() => _buffer.clear();
  int get length => _buffer.length;
}

/// 悬浮窗管理服务 — 由 CallService 状态机驱动
///
/// 两阶段生命周期：
///   1. prepare(session) — 存会话，不开窗口 (inCall 时)
///   2. show() — 弹出悬浮窗 (用户最小化时)
///   3. hide() — 关闭并清理 (idle/failed 时)
///
/// 字幕更新在窗口显示前会缓存，show() 时一并推送。
class OverlayService {
  static final OverlayService _instance = OverlayService._();
  factory OverlayService() => _instance;
  OverlayService._();

  static const _channel = MethodChannel('talktranslate/foreground');

  bool _active = false;
  bool get isActive => _active;
  CallSession? _currentSession;

  /// 字幕环形缓冲区 — 窗口关闭时持续缓存，打开时回放
  final SubtitleBuffer subtitleBuffer = SubtitleBuffer();
  // 最新一条字幕（快速访问，免遍历 buffer）
  String _cachedSubtitle = '';
  String _cachedTranslated = '';

  /// 悬浮窗操作回调（由 CallService 注册）
  void Function(String action)? onAction;

  /// 准备会话 — 由 CallState.inCall 触发，不开窗口
  void prepare(CallSession session) {
    _currentSession = session;
  }

  /// 弹出悬浮窗 — 由用户最小化触发
  Future<bool> show() async {
    if (_active) return true;
    if (_currentSession == null) return false;

    try {
      await FlutterOverlayWindow.requestPermission();
      await FlutterOverlayWindow.showOverlay(
        overlayTag: "overlay",
        enableDrag: true,
        flag: FlutterOverlayWindow.defaultFlag,
      );
      _active = true;
      _listen();

      // 推送会话信息 + 回放最近的缓存字幕
      await _pushToOverlay({
        'peer': _currentSession!.peerName,
        'state': 'inCall',
        'subtitle': _cachedSubtitle,
        'translated': _cachedTranslated,
        'history': subtitleBuffer.recent(5).map((item) => {
          'text': item.text,
          'translated': item.translated,
        }).toList(),
      });
      return true;
    } catch (_) {
      _active = false;
      return false;
    }
  }

  /// 隐藏并清理 — 由 CallState.idle/failed 触发
  Future<void> hide() async {
    if (_active) {
      try {
        await FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
    }
    _active = false;
    _currentSession = null;
    subtitleBuffer.clear();
    _cachedSubtitle = '';
    _cachedTranslated = '';
  }

  /// 更新状态显示 (窗口已打开时)
  Future<void> updateState(CallState state) async {
    if (!_active) return;
    await _pushToOverlay({'state': state.name});
  }

  /// 更新字幕 — 写入环形缓冲区，窗口已开则实时推送
  Future<void> updateSubtitle(String text, String translated) async {
    subtitleBuffer.add(text, translated);
    _cachedSubtitle = text;
    _cachedTranslated = translated;
    if (!_active) return;
    await _pushToOverlay({
      'subtitle': text,
      'translated': translated,
    });
  }

  /// 将主应用带回前台
  Future<void> bringToForeground() async {
    try {
      await _channel.invokeMethod('bringToForeground');
    } catch (_) {
      // fallback: 如果 MethodChannel 不可用，静默失败
    }
  }

  Future<void> _pushToOverlay(Map<String, dynamic> data) async {
    try {
      if (_currentSession != null) {
        data.putIfAbsent('peer', () => _currentSession!.peerName);
      }
      await FlutterOverlayWindow.shareData(data);
    } catch (_) {}
  }

  void _listen() {
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is String && onAction != null) {
        onAction!(data);
      }
    });
  }
}
