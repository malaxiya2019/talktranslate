import 'dart:convert';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

/// WebRTC 通话服务
class CallService {
  final uuid = Uuid();

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // 回调
  final StreamController<CallEvent> _events = StreamController.broadcast();
  Stream<CallEvent> get events => _events.stream;

  String? _currentCallId;
  bool get isInCall => _currentCallId != null;

  /// 获取本地音视频流
  Future<MediaStream?> getLocalStream() async {
    if (_localStream != null) return _localStream;

    try {
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': false, // 纯语音通话
      };
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      return _localStream;
    } catch (e) {
      _events.add(CallEvent(type: CallEventType.error, data: '麦克风权限被拒绝: $e'));
      return null;
    }
  }

  /// 创建通话 (主叫)
  Future<String> startCall(String peerId) async {
    _currentCallId = uuid.v4();
    _events.add(CallEvent(type: CallEventType.calling, data: peerId));
    return _currentCallId!;
  }

  /// 接听通话 (被叫)
  Future<void> answerCall(String callId) async {
    _currentCallId = callId;
    _events.add(CallEvent(type: CallEventType.connected, data: callId));
  }

  /// 结束通话
  Future<void> endCall() async {
    try {
      _peerConnection?.close();
      _peerConnection = null;
      _localStream?.getTracks().forEach((t) => t.stop());
      _localStream = null;
      _remoteStream = null;
    } catch (_) {}

    _events.add(CallEvent(type: CallEventType.ended, data: _currentCallId));
    _currentCallId = null;
  }

  void dispose() {
    _events.close();
    endCall();
  }
}

/// 通话事件
class CallEvent {
  static const String calling = 'calling';
  static const String ringing = 'ringing';
  static const String connected = 'connected';
  static const String ended = 'ended';
  static const String error = 'error';

  final String type;
  final String? data;

  const CallEvent({required this.type, this.data});
}
