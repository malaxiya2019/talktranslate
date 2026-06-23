import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call.dart';
import 'signaling_service.dart';
import 'overlay_service.dart';
import 'call_state_machine.dart';
import 'translation_pipeline.dart';
import 'foreground_service.dart';

/// 通话协调层 — 组装 WebRTC + 信令 + 状态机 + 翻译管道
///
/// 不再直接管理状态或 STT/TTS，只做编排。
class CallService {
  final SignalingService _signal;
  final CallStateMachine _stateMachine = CallStateMachine();
  final TranslationPipeline pipeline = TranslationPipeline();
  final _events = StreamController<Map<String, dynamic>>.broadcast();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String _callId = '';
  String? _peerPhone;

  DateTime? _callStartTime;

  // ── 公开访问 ──

  Stream<Map<String, dynamic>> get events => _events.stream;
  Stream<CallState> get onStateChange => _stateMachine.onStateChange;
  CallState get state => _stateMachine.state;
  CallState get status => _stateMachine.state; // 向后兼容

  MediaStream? get remoteStream => _remoteStream;
  String? get peerPhone => _peerPhone;

  // 字幕（UI 直接读）
  String _subtitle = '';
  String _subtitleTranslated = '';
  String _mySpeech = '';
  String _mySpeechTranslated = '';
  String get subtitle => _subtitle;
  String get subtitleTranslated => _subtitleTranslated;
  String get mySpeech => _mySpeech;
  String get mySpeechTranslated => _mySpeechTranslated;

  static const ICE = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  CallService(this._signal) {
    _signal.events.listen((msg) async {
      try {
        await _onSignal(msg);
      } catch (e) {
        _emitToast('信号异常');
      }
    });
    _stateMachine.onTimeout = _onTimeout;
    _stateMachine.onStateChange.listen(_onStateChange);
    pipeline.onMySpeech = _onMySpeech;
    _setupOverlay();
  }

  // ── 状态机回调 ──

  void _onTimeout(CallState target, String message) {
    _emitToast(message);
  }

  void _onStateChange(CallState newState) {
    _events.add({'type': 'status', 'state': newState.name});
    _persistSnapshot(newState);

    switch (newState) {
      case CallState.idle:
      case CallState.failed:
        _emitCallRecord();
        _cancelAllTimers();
        _cleanupMedia();
        OverlayService().hide();
        ForegroundService().stop();
        break;
      case CallState.inCall:
        _callStartTime = DateTime.now();
        OverlayService().prepare(
          CallSession(
            peerName: _peerPhone ?? '未知',
            callId: _callId,
            startedAt: _callStartTime!,
          ),
        );
        ForegroundService().start(_peerPhone ?? '通话中');
        break;
      case CallState.reconnecting:
        _startReconnect();
        OverlayService().updateState(CallState.reconnecting);
        break;
      default:
        break;
    }
  }

  // ── 断线重连 ──

  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  static const _maxAttempts = 10;

  void _startReconnect() {
    _reconnectAttempt = 0;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempt >= _maxAttempts) {
      _emitToast('重连失败，通话已结束');
      _stateMachine.transition(CallState.failed);
      return;
    }

    final delay = Duration(
      seconds: [
        1,
        2,
        4,
        8,
        16,
        30,
        30,
        30,
        30,
        30,
      ][_reconnectAttempt.clamp(0, 9)],
    );

    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () async {
      if (_stateMachine.state != CallState.reconnecting) return;
      _emitToast('正在重连 (${_reconnectAttempt}/$_maxAttempts)...');
      final ok = await _signal.reconnect();
      if (ok && _stateMachine.state == CallState.reconnecting) {
        _emitToast('重连成功');
        await _restartIce();
        _stateMachine.transition(CallState.inCall);
      } else if (_stateMachine.state == CallState.reconnecting) {
        _scheduleReconnect();
      }
    });
  }

  void _cancelAllTimers() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
  }

  Future<void> _restartIce() async {
    if (_pc == null) return;
    try {
      final offer = await _pc!.createOffer({'offerToReceiveAudio': true});
      await _pc!.setLocalDescription(offer);
      _signal.sendOffer(_callId, offer.sdp ?? '');
    } catch (e) {
      _emitToast('ICE 重启失败');
    }
  }

  // ── Overlay ──

  void _setupOverlay() {
    OverlayService().onAction = (action) {
      switch (action) {
        case 'open':
          OverlayService().bringToForeground();
          break;
        case 'hangup':
          hangup();
          break;
      }
    };
  }

  void enterBackgroundMode() {
    OverlayService().show();
  }

  // ── WebRTC ──

  Future<MediaStream> getLocalStream() async {
    if (_localStream != null) return _localStream!;
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    return _localStream!;
  }

  Future<RTCPeerConnection> createPC() async {
    _pc = await createPeerConnection(ICE, {'sdpSemantics': 'unified-plan'});
    (await getLocalStream()).getTracks().forEach(
      (t) => _pc?.addTrack(t, _localStream!),
    );

    _pc!.onIceCandidate = (c) {
      if (_callId.isNotEmpty)
        _signal.sendIce(_callId, c.toMap(), _peerPhone ?? '');
    };
    _pc!.onTrack = (e) {
      _remoteStream = e.streams[0];
      _events.add({'type': 'remoteStream'});
    };
    _pc!.onConnectionState = (s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected &&
          _stateMachine.state == CallState.inCall) {
        _stateMachine.transition(CallState.reconnecting);
      }
    };
    return _pc!;
  }

  // ── 呼叫生命周期 ──

  Future<void> call(String phone) async {
    if (_stateMachine.state != CallState.idle) return;
    _peerPhone = phone;
    _stateMachine.transition(CallState.connecting);
    try {
      await getLocalStream();
      await createPC();
      _signal.call(phone);
    } catch (e) {
      _emitToast('呼叫失败');
      _stateMachine.transition(CallState.failed);
    }
  }

  void incoming(String callId, String from) {
    _callId = callId;
    _peerPhone = from;
    _stateMachine.transition(CallState.ringing);
  }

  Future<void> accept() async {
    if (_stateMachine.state != CallState.ringing) return;
    _stateMachine.transition(CallState.connecting);
    try {
      await getLocalStream();
      _pc = await createPC();
      final offer = await _pc!.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': false});
      await _pc!.setLocalDescription(offer);
      _signal.sendOffer(_callId, offer.sdp ?? '');
      pipeline.start();
    } catch (e) {
      _emitToast('接听失败');
      _stateMachine.transition(CallState.failed);
    }
  }

  Future<void> reject() async {
    if (_callId.isNotEmpty) _signal.reject(_callId);
    _stateMachine.transition(CallState.idle);
  }

  Future<void> hangup() async {
    if (_stateMachine.state == CallState.idle) return;
    pipeline.stop();
    if (_callId.isNotEmpty) _signal.hangup(_callId);
    _emitCallRecord();
    _stateMachine.reset();
  }

  // ── 信令处理 ──

  Future<void> _onSignal(Map<String, dynamic> msg) async {
    switch (msg['type']) {
      case 'ringing':
        _callId = msg['callId'] as String;
        _events.add({'type': 'status', 'state': _stateMachine.state.name});
        break;

      case 'accepted':
        _callId = msg['callId'] as String;
        if (_stateMachine.state == CallState.connecting) {
          _stateMachine.transition(CallState.inCall);
        }
        if (_pc != null) {
          final offer = await _pc!.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': false});
          await _pc!.setLocalDescription(offer);
          _signal.sendOffer(_callId, offer.sdp ?? '');
        }
        break;

      case 'rejected':
        _emitToast('对方已拒接');
        _stateMachine.transition(CallState.idle);
        break;

      case 'offer':
        if (msg['sdp'] == null) break;
        await _pc?.setRemoteDescription(
          RTCSessionDescription(msg['sdp'] as String, 'offer'),
        );
        if (_pc != null) {
          final answer = await _pc!.createAnswer();
          await _pc!.setLocalDescription(answer);
          _signal.sendAnswer(_callId, answer.sdp ?? '');
        }
        if (_stateMachine.state != CallState.inCall) {
          _stateMachine.transition(CallState.inCall);
        }
        break;

      case 'answer':
        await _pc?.setRemoteDescription(
          RTCSessionDescription(msg['sdp'] as String, 'answer'),
        );
        break;

      case 'ice':
        if (_pc != null &&
            msg['candidate'] != null &&
            msg['candidate'] is Map) {
          final c = msg['candidate'] as Map;
          await _pc!.addCandidate(
            RTCIceCandidate(
              (c['candidate'] as String?) ?? '',
              (c['sdpMid'] as String?) ?? '',
              (c['sdpMLineIndex'] as int?) ?? 0,
            ),
          );
        }
        break;

      case 'subtitle':
        _subtitle = msg['text'] as String;
        _subtitleTranslated = (msg['translated'] as String?) ?? '';
        _events.add({
          'type': 'subtitle',
          'text': _subtitle,
          'translated': _subtitleTranslated,
        });
        OverlayService().updateSubtitle(_subtitle, _subtitleTranslated);
        if (_subtitleTranslated.isNotEmpty) {
          pipeline.speak(_subtitleTranslated);
        }
        break;

      case 'hangup':
        _emitToast('对方已挂断');
        hangup();
        break;

      case 'disconnected':
        if (_stateMachine.state == CallState.inCall) {
          _stateMachine.transition(CallState.reconnecting);
        } else if (_stateMachine.isCallActive) {
          _emitToast('连接断开');
          _stateMachine.transition(CallState.failed);
        }
        break;
      default:
        break;
    }
  }

  // ── 通话记录 ──

  void _emitCallRecord() {
    if (_callStartTime == null || _peerPhone == null) {
      _callStartTime = null;
      return;
    }
    final duration = DateTime.now().difference(_callStartTime!).inSeconds;
    _events.add({
      'type': 'call_record',
      'peer': _peerPhone,
      'startTime': _callStartTime!.toIso8601String(),
      'duration': duration,
      'transcript': _subtitleTranslated,
    });
    _callStartTime = null;
  }

  // ── 状态快照 (Session Restore) ──

  void _persistSnapshot(CallState state) {
    if (_peerPhone == null) return;
    if (state == CallState.idle) {
      _events.add({'type': 'snapshot_clear'});
      return;
    }
    _events.add({
      'type': 'snapshot',
      'snapshot': CallSnapshot(
        sessionId: _callId.isNotEmpty
            ? _callId
            : DateTime.now().millisecondsSinceEpoch.toString(),
        state: state,
        peerId: _peerPhone!,
        timestamp: DateTime.now(),
      ).toJson(),
    });
  }

  /// 从快照恢复通话状态 — 由 AppProvider 启动时调用
  Future<void> resume(CallSnapshot snapshot) async {
    _peerPhone = snapshot.peerId;
    _callId = snapshot.sessionId;
    _stateMachine.transition(snapshot.state);
    _emitToast('正在恢复通话...');

    // 重连信令
    final ok = await _signal.reconnect();
    if (!ok) {
      _emitToast('恢复失败');
      _stateMachine.reset();
      return;
    }

    // 重连 WebRTC
    await getLocalStream();
    await createPC();
    await _restartIce();

    _emitToast('通话已恢复');
  }

  // ── 清理 ──

  void _cleanupMedia() {
    pipeline.stop();
    _pc?.close();
    _pc = null;
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;
    _remoteStream = null;
    _subtitle = '';
    _subtitleTranslated = '';
    _mySpeech = '';
    _mySpeechTranslated = '';
    _callId = '';
    _peerPhone = null;
  }

  /// 本端语音识别结果 → 更新字幕 + 发送给对面
  void _onMySpeech(String text, String translated) {
    _mySpeech = text;
    _mySpeechTranslated = translated;
    _events.add({'type': 'mySpeech', 'text': text});
    if (_callId.isNotEmpty && _peerPhone != null) {
      _signal.sendSubtitle(_callId, text, translated, _peerPhone!);
    }
  }

  void _emitToast(String message) {
    _events.add({'type': 'toast', 'message': message});
  }

  void dispose() {
    _stateMachine.dispose();
    pipeline.dispose();
    _events.close();
  }
}
