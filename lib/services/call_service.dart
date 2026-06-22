import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/call.dart';
import 'signaling_service.dart';
import 'translation_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  final TranslationService translator = TranslationService();
  final FlutterTts tts = FlutterTts();
  bool _ttsEnabled = true;
  String _subtitle = '';        // 对方说的话 (原文)
  String _subtitleTranslated = '';  // 对方说的话 (翻译)
  String _mySpeech = '';        // 我刚说的话
  String _mySpeechTranslated = ''; // 我刚说的话 (翻译)
  String get subtitle => _subtitle;
  String get subtitleTranslated => _subtitleTranslated;
  String get mySpeech => _mySpeech;
  String get mySpeechTranslated => _mySpeechTranslated;

  stt.SpeechToText? _speech;
  bool _sttRunning = false;
  CallStatus get status => _status;
  MediaStream? get remoteStream => _remoteStream;
  String? get peerPhone => _peerPhone;

  static const ICE = {'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ]};

  CallService(this._signal) {
    _signal.events.listen(_onSignal);
    _initTTS();
  }

  Future<void> _initTTS() async {
    try {
      await tts.setLanguage('en-US');
      await tts.setSpeechRate(0.5);
      await tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> speak(String text, String lang) async {
    if (!_ttsEnabled || text.isEmpty) return;
    try {
      await tts.setLanguage(_mapTTSLang(lang));
      await tts.speak(text);
    } catch (_) {}
  }

  String _mapTTSLang(String code) {
    const map = {
      'zh-CN': 'zh-CN', 'en-US': 'en-US', 'ja-JP': 'ja-JP',
      'ko-KR': 'ko-KR', 'es-ES': 'es-ES', 'fr-FR': 'fr-FR',
      'de-DE': 'de-DE', 'pt-BR': 'pt-BR', 'ru-RU': 'ru-RU',
    };
    return map[code] ?? 'en-US';
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
      case 'subtitle':
        _subtitle = msg['text'] as String;
        _subtitleTranslated = (msg['translated'] as String?) ?? '';
        _events.add({'type': 'subtitle', 'text': _subtitle, 'translated': _subtitleTranslated});
        // TTS: 自动朗读翻译结果
        if (_subtitleTranslated.isNotEmpty) {
          speak(_subtitleTranslated, 'zh-CN');
        }
        break;
      case 'hangup':
        _cleanup();
        _events.add({'type': 'toast', 'message': '对方已挂断'});
        break;
    }
  }

  /// 开始语音识别 (STT)
  Future<void> startSTT() async {
    if (_sttRunning) return;
    _speech ??= stt.SpeechToText();
    final ok = await _speech!.initialize();
    if (!ok) return;
    _sttRunning = true;
    _listenSTT();
  }

  void _listenSTT() async {
    while (_sttRunning && _status == CallStatus.connected) {
      final completer = Completer<void>();
      String text = '';

      await _speech!.listen(
        onResult: (r) {
          text = r.recognizedWords;
          if (r.finalResult && !completer.isCompleted) completer.complete();
        },
        localeId: 'zh-CN',
        cancelOnError: true,
        partialResults: true,
      );

      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 5)),
      ]);

      await _speech!.stop();

      if (text.isNotEmpty) {
        _mySpeech = text;
        _events.add({'type': 'mySpeech', 'text': text});

        // 翻译
        String translated = '';
        try {
          translated = await translator.translate(text, 'zh-CN', 'en-US');
        } catch (_) {}
        _mySpeechTranslated = translated;

        if (_callId.isNotEmpty && _peerPhone != null) {
          _signal.sendSubtitle(_callId, text, translated, _peerPhone!);
        }
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _sttRunning = false;
  }

  /// 停止 STT
  Future<void> stopSTT() async {
    _sttRunning = false;
    await _speech?.stop();
  }

  @override
  void _cleanup() {
    stopSTT();
    _pc?.close(); _pc = null;
    _localStream?.getTracks().forEach((t) => t.stop()); _localStream = null;
    _remoteStream = null;
    _status = CallStatus.idle;
    _subtitle = ''; _subtitleTranslated = ''; _mySpeech = ''; _mySpeechTranslated = '';
    _events.add({'type': 'status', 'status': _status});
    _callId = ''; _peerPhone = null;
  }
}
