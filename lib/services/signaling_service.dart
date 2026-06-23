import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SignalingService {
  WebSocketChannel? _channel;
  String? _phone;
  String? _serverUrl;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  bool get connected => _channel != null;

  Future<void> connect(String url, String phone) async {
    _serverUrl = url;
    _phone = phone;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (data) => _events.add(jsonDecode(data as String)),
        onError: (e) {
          _channel = null;
          _events.add({'type': 'error', 'message': '信令连接异常: $e'});
        },
        onDone: () {
          _channel = null;
          _events.add({'type': 'disconnected'});
        },
        cancelOnError: false,
      );
      await Future.delayed(const Duration(milliseconds: 300));
      send({'type': 'register', 'phone': phone});
    } catch (e) {
      _events.add({'type': 'error', 'message': '连接失败: $e'});
    }
  }

  void send(Map<String, dynamic> msg) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (e) {
        _events.add({'type': 'error', 'message': '发送失败: $e'});
      }
    }
  }

  void call(String to) => send({'type': 'call', 'to': to});
  void accept(String callId) => send({'type': 'accept', 'callId': callId});
  void reject(String callId) => send({'type': 'reject', 'callId': callId});
  void sendOffer(String callId, String sdp) =>
      send({'type': 'offer', 'callId': callId, 'sdp': sdp});
  void sendAnswer(String callId, String sdp) =>
      send({'type': 'answer', 'callId': callId, 'sdp': sdp});
  void sendIce(String callId, Map<String, dynamic> candidate, String to) =>
      send({'type': 'ice', 'callId': callId, 'candidate': candidate, 'to': to});
  void sendSubtitle(String callId, String text, String translated, String to) =>
      send({
        'type': 'subtitle',
        'callId': callId,
        'text': text,
        'translated': translated,
        'to': to,
      });
  void hangup(String callId) => send({'type': 'hangup', 'callId': callId});

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  /// 断线重连 — 用上次的地址和手机号重新连接
  Future<bool> reconnect() async {
    if (_serverUrl == null || _phone == null) return false;
    disconnect();
    try {
      await connect(_serverUrl!, _phone!);
      return _channel != null;
    } catch (_) {
      return false;
    }
  }
}
