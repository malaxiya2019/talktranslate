/// 悬浮窗独立 Flutter 引擎入口
///
/// 使用 widgets/overlay/ 组件库实现分层 UI。
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../models/call.dart';
import '../widgets/overlay/floating_panel.dart';

void main() => runApp(const _OverlayApp());

class _OverlayApp extends StatelessWidget {
  const _OverlayApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const _OverlayBubble(),
    );
  }
}

class _OverlayBubble extends StatefulWidget {
  const _OverlayBubble();
  @override
  State<_OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<_OverlayBubble> {
  String _peerName = '';
  String _subtitle = '';
  String _translated = '';
  CallState _state = CallState.inCall;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          _peerName = (data['peer'] as String?) ?? _peerName;
          _subtitle = (data['subtitle'] as String?) ?? _subtitle;
          _translated = (data['translated'] as String?) ?? _translated;
          // 解析状态
          final stateStr = data['state'] as String?;
          if (stateStr != null) {
            _state = CallState.values.firstWhere(
              (s) => s.name == stateStr,
              orElse: () => _state,
            );
          }
          // 历史回放
          if (data['history'] != null) {
            final history = data['history'] as List;
            if (history.isNotEmpty) {
              final last = history.last as Map;
              _subtitle = (last['text'] as String?) ?? _subtitle;
              _translated = (last['translated'] as String?) ?? _translated;
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FloatingPanel(
      peerName: _peerName,
      subtitle: _subtitle,
      translated: _translated,
      state: _state,
      expanded: _expanded,
      onTap: () => FlutterOverlayWindow.shareData('open'),
      onLongPress: () => setState(() => _expanded = !_expanded),
      onOpen: () => FlutterOverlayWindow.shareData('open'),
      onHangup: () => FlutterOverlayWindow.shareData('hangup'),
    );
  }
}
