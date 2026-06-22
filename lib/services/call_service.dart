import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call.dart';
import 'signaling_service.dart';

class CallService {
  final SignalingService _signal;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String _callId = '';
  String? _peerPhone;
  CallStatus _status = CallStatus.idle;
  CallStatus get status => _status;
  MediaStream? get remoteStream => _remoteStream;
  String? get peerPhone => _peerPhone;

  static const ICE = {'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ]};

  CallService(this._signal) {
    _signal.events.listen(_onSignal);
  }

  Future<MediaStream> getLocalStream() async {
    if (_localStream != null) return _localStream!;
    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    return _localStream!;
  }

  Future<RTCPeerConnection> createPC() async {
    _pc = await createPeerConnection(ICE, {'sdpSemantics': 'unified-plan'});
    (await getLocalStream()).getTracks().forEach((t) => _pc?.addTrack(t, _localStream!));

    _pc!.onIceCandidate = (c) {
      if (c != null && _callId.isNotEmpty) _signal.sendIce(_callId, c.toMap(), _peerPhone ?? '');
    };
    _pc!.onTrack = (e) {
      _remoteStream = e.streams[0];
      _events.add({'type': 'remoteStream'});
    };
    _pc!.onConnectionState = (s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) hangup();
    };
    return _pc!;
  }

  Future<void> call(String phone) async {
    _peerPhone = phone;
    _status = CallStatus.calling;
    _events.add({'type': 'status', 'status': _status});
    await getLocalStream();
    await createPC();
    _signal.call(phone);
  }

  void incoming(String callId, String from) {
    _callId = callId;
    _peerPhone = from;
    _status = CallStatus.ringing;
    _events.add({'type': 'status', 'status': _status});
  }

  Future<void> accept() async {
    _status = CallStatus.connected;
    _events.add({'type': 'status', 'status': _status});
    await getLocalStream();
    _pc = await createPC();
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    _signal.sendOffer(_callId, offer.sdp ?? '');
  }

  Future<void> reject() async {
    _signal.reject(_callId);
    _cleanup();
  }

  Future<void> hangup() async {
    if (_callId.isNotEmpty) _signal.hangup(_callId);
    _cleanup();
  }

  void _cleanup() {
    _pc?.close(); _pc = null;
    _localStream?.getTracks().forEach((t) => t.stop()); _localStream = null;
    _remoteStream = null;
    _status = CallStatus.idle;
    _events.add({'type': 'status', 'status': _status});
    _callId = ''; _peerPhone = null;
  }

  Future<void> _onSignal(Map<String, dynamic> msg) async {
    switch (msg['type']) {
      case 'ringing':
        _callId = msg['callId'] as String;
        _status = CallStatus.ringing;
        _events.add({'type': 'status', 'status': _status});
        break;
      case 'accepted':
        _callId = msg['callId'] as String;
        _status = CallStatus.connected;
        _events.add({'type': 'status', 'status': _status});
        final offer = await _pc!.createOffer();
        await _pc!.setLocalDescription(offer);
        _signal.sendOffer(_callId, offer.sdp ?? '');
        break;
      case 'rejected':
        _cleanup();
        _events.add({'type': 'toast', 'message': '对方已拒接'});
        break;
      case 'offer':
        await _pc?.setRemoteDescription(RTCSessionDescription(msg['sdp'] as String, 'offer'));
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        _signal.sendAnswer(_callId, answer.sdp ?? '');
        break;
      case 'answer':
        await _pc?.setRemoteDescription(RTCSessionDescription(msg['sdp'] as String, 'answer'));
        break;
      case 'ice':
        if (_pc != null && msg['candidate'] != null) {
          final c = msg['candidate'] as Map;
          await _pc!.addCandidate(RTCIceCandidate(
            (c['candidate'] as String?) ?? '',
            (c['sdpMid'] as String?) ?? '',
            (c['sdpMLineIndex'] as int?) ?? 0));
        }
        break;
      case 'hangup':
        _cleanup();
        _events.add({'type': 'toast', 'message': '对方已挂断'});
        break;
    }
  }
}
