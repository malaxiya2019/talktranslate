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

  // ── Ping 检测 ──
  Timer? _pingTimer;
  int _lastPingMs = 0;
  int get lastPingMs => _lastPingMs;
  DateTime? _pingSentAt;

  void startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pingSentAt = DateTime.now();
      send({'type': 'ping', 'time': _pingSentAt!.millisecondsSinceEpoch});
    });
  }

  void stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _handlePong(Map<String, dynamic> msg) {
    if (_pingSentAt != null) {
      _lastPingMs = DateTime.now().difference(_pingSentAt!).inMilliseconds;
      _events.add({'type': 'pong', 'pingMs': _lastPingMs});
      _pingSentAt = null;
    }
  }

  Future<void> connect(String url, String phone) async {
    _serverUrl = url;
    _phone = phone;
    final connected = Completer<void>();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (data) {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          if (msg['type'] == 'registered' && !connected.isCompleted) {
            connected.complete();
          }
          if (msg['type'] == 'pong') {
            _handlePong(msg);
          } else {
            _events.add(msg);
          }
        },
        onError: (e) {
          _channel = null;
          if (!connected.isCompleted) connected.completeError(e);
          _events.add({'type': 'error', 'message': '信令连接异常: $e'});
        },
        onDone: () {
          _channel = null;
          if (!connected.isCompleted) connected.complete();
          _events.add({'type': 'disconnected'});
        },
        cancelOnError: false,
      );
      // 等待 WebSocket 连接就绪后再注册
      await _channel!.ready;
      send({'type': 'register', 'phone': phone});
      // 等待注册确认（超时 10 秒）
      await connected.future.timeout(const Duration(seconds: 10));
    } catch (e) {
      _channel = null;
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
