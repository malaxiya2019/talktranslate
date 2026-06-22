import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SignalingService {
  WebSocketChannel? _channel;
  String? _phone;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  bool get connected => _channel != null;

  Future<void> connect(String url, String phone) async {
    _phone = phone;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (data) => _events.add(jsonDecode(data as String)),
        onDone: () { _channel = null; _events.add({'type': 'disconnected'}); },
      );
      await Future.delayed(const Duration(milliseconds: 300));
      send({'type': 'register', 'phone': phone});
    } catch (e) {
      _events.add({'type': 'error', 'message': '连接失败: $e'});
    }
  }

  void send(Map<String, dynamic> msg) {
    if (_channel != null) _channel!.sink.add(jsonEncode(msg));
  }

  void call(String to) => send({'type': 'call', 'to': to});
  void accept(String callId) => send({'type': 'accept', 'callId': callId});
  void reject(String callId) => send({'type': 'reject', 'callId': callId});
  void sendOffer(String callId, String sdp) => send({'type': 'offer', 'callId': callId, 'sdp': sdp});
  void sendAnswer(String callId, String sdp) => send({'type': 'answer', 'callId': callId, 'sdp': sdp});
  void sendIce(String callId, Map<String, dynamic> candidate, String to) =>
      send({'type': 'ice', 'callId': callId, 'candidate': candidate, 'to': to});
  void hangup(String callId) => send({'type': 'hangup', 'callId': callId});

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
