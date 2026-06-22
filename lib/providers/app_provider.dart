import 'package:flutter/foundation.dart';
import '../services/signaling_service.dart';
import '../services/call_service.dart';
import '../models/call.dart';

class AppProvider extends ChangeNotifier {
  final signaling = SignalingService();
  late final CallService callService;

  String? _phone;
  String? get phone => _phone;
  bool _connected = false;
  bool get connected => _connected;
  List<String> _onlineUsers = [];
  List<String> get onlineUsers => _onlineUsers;
  String _serverUrl = 'ws://localhost:3459';
  String get serverUrl => _serverUrl;
  String? _toast;
  String? get toast => _toast;

  AppProvider() {
    callService = CallService(signaling);

    signaling.events.listen((e) {
      switch (e['type']) {
        case 'registered': _connected = true; _phone = e['phone']; notifyListeners(); break;
        case 'disconnected': _connected = false; notifyListeners(); break;
        case 'online': _onlineUsers = List<String>.from(e['users']); notifyListeners(); break;
        case 'incoming': callService.incoming(e['callId'], e['from']); notifyListeners(); break;
        case 'error': _toast = e['message']; notifyListeners(); break;
      }
    });

    callService.events.listen((e) {
      if (e['type'] == 'toast') { _toast = e['message']; notifyListeners(); }
      if (e['type'] == 'status' || e['type'] == 'subtitle' || e['type'] == 'mySpeech') notifyListeners();
    });
  }

  void setServer(String url) { _serverUrl = url; notifyListeners(); }

  Future<void> login(String phone) async {
    _phone = phone;
    await signaling.connect(_serverUrl, phone);
  }

  void logout() { signaling.disconnect(); _connected = false; _phone = null; notifyListeners(); }

  CallStatus get callStatus => callService.status;
  String? get peerPhone => callService.peerPhone;

  String get subtitle => callService.subtitle;
  String get mySpeech => callService.mySpeech;

  Future<void> call(String to) async => await callService.call(to);
  Future<void> accept() async { await callService.accept(); callService.startSTT(); }
  Future<void> reject() async => await callService.reject();
  Future<void> hangup() async => await callService.hangup();

  void clearToast() { _toast = null; notifyListeners(); }
}
