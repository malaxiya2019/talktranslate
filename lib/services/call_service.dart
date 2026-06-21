import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

/// 通话状态
enum CallState { idle, calling, ringing, connected, ended }

/// WebRTC 通话服务
class CallService {
  final SignalingService _signaling;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _currentCallId;
  CallState _state = CallState.idle;

  CallState get state => _state;
  MediaStream? get remoteStream => _remoteStream;

  final StreamController<CallEvent> _events = StreamController.broadcast();
  Stream<CallEvent> get events => _events.stream;

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  CallService(this._signaling) {
    _signaling.events.listen(_onSignal);
  }

  /// 获取本地音频流
  Future<MediaStream> getLocalStream() async {
    if (_localStream != null) return _localStream!;
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    return _localStream!;
  }

  /// 创建 RTCPeerConnection
  Future<RTCPeerConnection> createPeerConnection() async {
    _pc = await createPeerConnection(_iceServers, {'sdpSemantics': 'unified-plan'});

    _localStream?.getTracks().forEach((track) => _pc?.addTrack(track, _localStream!));

    _pc!.onIceCandidate = (candidate) {
      if (_currentCallId != null && candidate != null) {
        _signaling.sendIce(_currentCallId!, candidate.toMap(), '');
      }
    };

    _pc!.onTrack = (event) {
      _remoteStream = event.streams[0];
      _events.add(CallEvent(type: 'remote-stream'));
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        hangUp();
      }
    };

    return _pc!;
  }

  /// 拨号
  Future<void> startCall(String to) async {
    _state = CallState.calling;
    _events.add(CallEvent(type: 'state-change', data: _state));
    await getLocalStream();
    await createPeerConnection();
    _signaling.call(to);
  }

  /// 接听
  Future<void> answerCall(String callId, String from) async {
    _currentCallId = callId;
    _state = CallState.ringing;
    _events.add(CallEvent(type: 'incoming-call', data: {'from': from, 'callId': callId}));
  }

  Future<void> acceptCall() async {
    await getLocalStream();
    await createPeerConnection();

    // 创建 SDP answer
    final sdp = await _pc!.createOffer({'offerToReceiveAudio': true});
    await _pc!.setLocalDescription(sdp);
    _signaling.sendOffer(_currentCallId!, sdp.sdp);

    _state = CallState.connected;
    _events.add(CallEvent(type: 'state-change', data: _state));
  }

  Future<void> rejectCall() async {
    if (_currentCallId != null) {
      _signaling.answer(_currentCallId!, false);
    }
    _state = CallState.idle;
    _events.add(CallEvent(type: 'state-change', data: _state));
  }

  /// 挂断
  Future<void> hangUp() async {
    if (_currentCallId != null) {
      _signaling.endCall(_currentCallId!);
    }
    _cleanup();
  }

  void _cleanup() {
    _pc?.close();
    _pc = null;
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;
    _remoteStream = null;
    _currentCallId = null;
    _state = CallState.idle;
    _events.add(CallEvent(type: 'state-change', data: _state));
  }

  /// 处理信令事件
  void _onSignal(SignalingEvent event) {
    switch (event.type) {
      case 'ringing':
        _currentCallId = event.data as String;
        _state = CallState.ringing;
        _events.add(CallEvent(type: 'state-change', data: _state));
        break;

      case 'accepted':
        _state = CallState.connected;
        _events.add(CallEvent(type: 'state-change', data: _state));
        // 主叫方创建 offer
        _createOffer();
        break;

      case 'rejected':
        _cleanup();
        _events.add(CallEvent(type: 'call-ended', data: '对方已拒接'));
        break;

      case 'offer':
        _handleOffer(event.data as Map);
        break;

      case 'answer-sdp':
        _handleAnswer(event.data as Map);
        break;

      case 'ice':
        if (_pc != null && event.data != null) {
          _pc!.addCandidate(RTCIceCandidate(
            event.data['candidate'],
            event.data['sdpMid'],
            event.data['sdpMLineIndex'],
          ));
        }
        break;

      case 'call-ended':
        _cleanup();
        _events.add(CallEvent(type: 'call-ended', data: event.data));
        break;
    }
  }

  Future<void> _createOffer() async {
    if (_pc == null) return;
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    _signaling.sendOffer(_currentCallId!, offer.sdp);
  }

  Future<void> _handleOffer(Map data) async {
    if (_pc == null) return;
    await _pc!.setRemoteDescription(RTCSessionDescription(data['sdp'], 'offer'));
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    _signaling.sendAnswer(_currentCallId!, answer.sdp);
  }

  Future<void> _handleAnswer(Map data) async {
    if (_pc == null) return;
    await _pc!.setRemoteDescription(RTCSessionDescription(data['sdp'], 'answer'));
  }

  void dispose() {
    _cleanup();
    _events.close();
  }
}

class CallEvent {
  final String type;
  final dynamic data;
  CallEvent({required this.type, this.data});
}
