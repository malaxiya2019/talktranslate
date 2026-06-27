import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 信令服务 — 管理 WebSocket 连接生命周期
///
/// 连接握手顺序（解决重连时 Auth 竞态 Bug）：
///   1. 建立 WebSocket 连接
///   2. 发送 auth（携带 JWT Token）
///   3. 等待 auth_ok 回执
///   4. 发送 register（注册手机号在线）
///   5. 等待 registered 回执
///   6. 释放消息队列 → 业务消息正常流通
///
/// 断线重连时：
///   - 所有业务消息被挂起到 _pendingQueue
///   - 完整握手完成后才释放队列
///   - 避免并发业务请求在 Auth 完成前到达网关
class SignalingService {
  WebSocketChannel? _channel;
  String? _phone;
  String? _serverUrl;
  String? _authToken;
  bool _authenticated = false;
  bool _registered = false;

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  /// 连接就绪 = 信道存在 + Auth 完成 + 已注册
  bool get connected => _channel != null && _authenticated && _registered;

  // ── 消息队列（断线重连时挂起业务消息） ──
  final List<Map<String, dynamic>> _pendingQueue = [];
  bool _queueEnabled = false;

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

  /// 安全发送事件（防止 dispose 后 add 抛异常）
  void _emitEvent(Map<String, dynamic> event) {
    if (!_events.isClosed) _events.add(event);
  }

  void _handlePong(Map<String, dynamic> msg) {
    if (_pingSentAt != null) {
      _lastPingMs = DateTime.now().difference(_pingSentAt!).inMilliseconds;
      _emitEvent({'type': 'pong', 'pingMs': _lastPingMs});
      _pingSentAt = null;
    }
  }

  /// 连接信令服务器
  ///
  /// 握手流程：
  ///   [connect] → [auth (JWT)] → [auth_ok] → [register (phone)] → [registered] ✓
  ///
  /// [token] 可选：传递 JWT token 进行身份认证。
  /// 不传 token 时向后兼容（直接 register），但生产环境建议始终携带。
  Future<void> connect(String url, String phone, {String? token}) async {
    _serverUrl = url;
    _phone = phone;
    _authToken = token;
    _authenticated = false;
    _registered = false;

    final connected = Completer<void>();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (data) {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          switch (msg['type']) {
            case 'auth_ok':
              _authenticated = true;
              _emitEvent({'type': 'auth_ok', 'user': msg['user']});
              // Auth 通过 → 立即发送注册
              send({'type': 'register', 'phone': phone});
              break;

            case 'auth_error':
              _authenticated = false;
              if (!connected.isCompleted) {
                connected.completeError(Exception(msg['message'] ?? 'Auth 失败'));
              }
              _emitEvent({'type': 'error', 'message': msg['message']});
              break;

            case 'registered':
              _registered = true;
              _emitEvent({
                'type': 'registered',
                'phone': msg['phone'],
                'instance': msg['instance'],
              });
              // 注册成功 → 释放消息队列
              _flushPendingQueue();
              if (!connected.isCompleted) connected.complete();
              break;

            case 'pong':
              _handlePong(msg);
              break;

            default:
              // 普通业务消息：只在握手完成后才投递
              if (_authenticated && _registered) {
                _emitEvent(msg);
              }
              break;
          }
        },
        onError: (e) {
          _channel = null;
          if (!connected.isCompleted) connected.completeError(e);
          _emitEvent({'type': 'error', 'message': '信令连接异常: $e'});
        },
        onDone: () {
          _channel = null;
          _authenticated = false;
          _registered = false;
          if (!connected.isCompleted) connected.complete();
          _emitEvent({'type': 'disconnected'});
        },
        cancelOnError: false,
      );

      // 等待 WebSocket 底层就绪
      await _channel!.ready;

      // 第一步：发送 Auth（携带 JWT Token）
      if (_authToken != null && _authToken!.isNotEmpty) {
        send({'type': 'auth', 'token': _authToken});
      } else {
        // 无 Token → 跳过 Auth 步骤，直接 Register（向后兼容）
        _authenticated = true;
        send({'type': 'register', 'phone': phone});
      }

      // 等待握手完成（auth + register），超时 15 秒
      await connected.future.timeout(const Duration(seconds: 15));
    } catch (e) {
      _channel = null;
      _authenticated = false;
      _registered = false;
      _emitEvent({'type': 'error', 'message': '连接失败: $e'});
      rethrow;
    }
  }

  /// 发送消息 — 重连队列模式下进入挂起队列
  void send(Map<String, dynamic> msg) {
    // 握手阶段的消息（auth / register）不受队列限制
    if (_queueEnabled &&
        msg['type'] != 'auth' &&
        msg['type'] != 'register') {
      _pendingQueue.add(msg);
      return;
    }
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (e) {
        _emitEvent({'type': 'error', 'message': '发送失败: $e'});
      }
    }
  }

  /// 释放消息队列 — 握手完成后将积压消息依次发出
  void _flushPendingQueue() {
    if (_pendingQueue.isEmpty) return;
    final queue = List<Map<String, dynamic>>.from(_pendingQueue);
    _pendingQueue.clear();
    for (final msg in queue) {
      try {
        _channel?.sink.add(jsonEncode(msg));
      } catch (_) {
        // 忽略队列释放时的发送错误
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
    _authenticated = false;
    _registered = false;
    _pendingQueue.clear();
    _queueEnabled = false;
  }

  /// 断线重连 — 使用上次的服务器地址、手机号和 JWT Token
  ///
  /// 重连时自动启用消息队列，避免业务消息在握手完成前到达网关。
  /// 完整握手（auth → register）完成后自动释放队列。
  Future<bool> reconnect() async {
    if (_serverUrl == null || _phone == null) return false;

    // 启用消息队列：挂起重连期间的所有业务消息
    _queueEnabled = true;
    disconnect();

    try {
      await connect(_serverUrl!, _phone!, token: _authToken);
      return connected;
    } catch (_) {
      _queueEnabled = false;
      _pendingQueue.clear();
      return false;
    }
  }
}
