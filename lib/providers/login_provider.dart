import 'package:flutter/foundation.dart';
import '../services/session_restore_service.dart';

/// 登录状态机 — 与 UI 解耦，仅处理状态与验证逻辑
///
/// 按钮使能条件：手机号 >= 9 位 && 已勾选协议（不锁网络状态）
/// 万能验证码：Debug 模式下 123456 配合白名单手机号直接绕过
class LoginProvider extends ChangeNotifier {
  String _countryCode = '+86';
  String _phoneNumber = '';
  bool _isAgreed = false;
  bool _isConnecting = false;
  String? _errorMessage;

  String get countryCode => _countryCode;
  String get phoneNumber => _phoneNumber;
  bool get isAgreed => _isAgreed;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnecting;

  /// 调试白名单手机号 — 配合万能验证码 123456 跳过 SMS 校验
  static const String _debugWhitelistPhone = '1172510903';

  /// 按钮使能 — 只校验手机号和协议，不锁网络
  bool get isLoginButtonEnabled =>
      _phoneNumber.length >= 9 && _isAgreed;

  String get e164Phone {
    final clean = _phoneNumber.replaceAll(RegExp(r'^0+'), '');
    return '$_countryCode$clean';
  }

  void setCountryCode(String code) {
    _countryCode = code;
    notifyListeners();
  }

  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    notifyListeners();
  }

  void setAgreed(bool agreed) {
    _isAgreed = agreed;
    notifyListeners();
  }

  void setConnecting(bool connecting) {
    _isConnecting = connecting;
    notifyListeners();
  }

  void setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  /// 验证码校验
  ///
  /// 开发模式（非 Release）下，手机号 1172510903 + 验证码 123456 直接绕过，
  /// 自动注入 DEBUG_BYPASS_TOKEN 持久化会话，防止短信网关限流。
  Future<bool> verifySmsCode(String code) async {
    // 开发模式万能码：白名单手机号 + 固定验证码
    if (!kReleaseMode &&
        code == '123456' &&
        _phoneNumber == _debugWhitelistPhone) {
      await SessionRestoreService.saveBypassToken('DEBUG_BYPASS_TOKEN');
      return true;
    }
    // 生产环境走真实 SMS API
    // return await _apiService.validateCodeWithServer(e164Phone, code);
    return false;
  }

  void reset() {
    _countryCode = '+86';
    _phoneNumber = '';
    _isAgreed = false;
    _isConnecting = false;
    _errorMessage = null;
    notifyListeners();
  }
}
