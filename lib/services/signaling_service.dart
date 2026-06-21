import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 信令服务 — WebSocket 连接 + 通话信令
class SignalingService {
  WebSocketChannel? _channel;
  String? _phone;
  StreamController<SignalingEvent> _events = StreamController.broadcast();
  Stream<SignalingEvent> get events => _events.stream;

  bool get isConnected => _channel != null;

  /// 连接信令服务器
  Future<void> connect(String serverUrl, String phone) async {
    _phone = phone;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _channel!.stream.listen(
        (data) => _handleMessage(jsonDecode(data)),
        onError: (e) => _events.add(SignalingEvent(type: 'error', data: '连接错误: $e')),
        onDone: () {
          _channel = null;
          _events.add(SignalingEvent(type: 'disconnected'));
        },
      );
      // 等待连接建立后注册
      await Future.delayed(const Duration(milliseconds: 500));
      _send({'type': 'register', 'phone': phone});
    } catch (e) {
      _events.add(SignalingEvent(type: 'error', data: '连接失败: $e'));
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'registered':
        _events.add(SignalingEvent(type: 'registered', data: msg['phone']));
        break;
      case 'incoming':
        _events.add(SignalingEvent(type: 'incoming', data: {
          'from': msg['from'],
          'callId': msg['callId'],
        }));
        break;
      case 'ringing':
        _events.add(SignalingEvent(type: 'ringing', data: msg['callId']));
        break;
      case 'accepted':
        _events.add(SignalingEvent(type: 'accepted', data: msg['callId']));
        break;
      case 'rejected':
        _events.add(SignalingEvent(type: 'rejected', data: msg['callId']));
        break;
      case 'offer':
        _events.add(SignalingEvent(type: 'offer', data: msg));
        break;
      case 'answer-sdp':
        _events.add(SignalingEvent(type: 'answer-sdp', data: msg));
        break;
      case 'ice':
        _events.add(SignalingEvent(type: 'ice', data: msg['candidate']));
        break;
      case 'call-ended':
        _events.add(SignalingEvent(type: 'call-ended', data: msg['reason']));
        break;
      case 'online-list':
        _events.add(SignalingEvent(type: 'online-list', data: msg['users']));
        break;
      case 'error':
        _events.add(SignalingEvent(type: 'error', data: msg['message']));
        break;
    }
  }

  void call(String to) => _send({'type': 'call', 'to': to});
  void answer(String callId, bool accepted) => _send({'type': 'answer', 'callId': callId, 'accepted': accepted});
  void sendOffer(String callId, String sdp) => _send({'type': 'offer', 'callId': callId, 'sdp': sdp});
  void sendAnswer(String callId, String sdp) => _send({'type': 'answer-sdp', 'callId': callId, 'sdp': sdp});
  void sendIce(String callId, Map<String, dynamic> candidate, String to) =>
      _send({'type': 'ice', 'callId': callId, 'candidate': candidate, 'to': to});
  void endCall(String callId) => _send({'type': 'end-call', 'callId': callId});

  void _send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _events.close();
  }
}

class SignalingEvent {
  final String type;
  final dynamic data;
  SignalingEvent({required this.type, this.data});
}
