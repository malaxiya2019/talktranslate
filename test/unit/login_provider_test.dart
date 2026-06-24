import 'package:flutter_test/flutter_test.dart';
import 'package:talktranslate/providers/login_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LoginProvider provider;

  setUp(() {
    // SharedPreferences 需要初始化
    SharedPreferences.setMockInitialValues({});
    provider = LoginProvider();
  });

  group('初始状态', () {
    test('默认区号 +86', () {
      expect(provider.countryCode, '+86');
    });

    test('手机号初始为空', () {
      expect(provider.phoneNumber, '');
    });

    test('协议初始未勾选', () {
      expect(provider.isAgreed, false);
    });

    test('按钮初始不可用', () {
      expect(provider.isLoginButtonEnabled, false);
    });

    test('错误信息初始为空', () {
      expect(provider.errorMessage, null);
    });
  });

  group('按钮使能状态机', () {
    test('手机号不足9位 + 未勾选 = 不可用', () {
      provider.setPhoneNumber('1380013');
      provider.setAgreed(false);
      expect(provider.isLoginButtonEnabled, false);
    });

    test('手机号不足9位 + 已勾选 = 不可用', () {
      provider.setPhoneNumber('138');
      provider.setAgreed(true);
      expect(provider.isLoginButtonEnabled, false);
    });

    test('手机号9位 + 未勾选 = 不可用', () {
      provider.setPhoneNumber('1380013800');
      provider.setAgreed(false);
      expect(provider.isLoginButtonEnabled, false);
    });

    test('手机号9位 + 已勾选 = 可用', () {
      provider.setPhoneNumber('1380013800');
      provider.setAgreed(true);
      expect(provider.isLoginButtonEnabled, true);
    });

    test('手机号刚好9位边界', () {
      provider.setPhoneNumber('123456789');
      provider.setAgreed(true);
      expect(provider.isLoginButtonEnabled, true);
    });

    test('手机号超过9位', () {
      provider.setPhoneNumber('8613800138000');
      provider.setAgreed(true);
      expect(provider.isLoginButtonEnabled, true);
    });
  });

  group('E.164 格式', () {
    test('正常号码格式', () {
      provider.setPhoneNumber('13800138000');
      expect(provider.e164Phone, '+8613800138000');
    });

    test('去前导零', () {
      provider.setPhoneNumber('0013800138000');
      expect(provider.e164Phone, '+8613800138000');
    });

    test('修改区号', () {
      provider.setCountryCode('+1');
      provider.setPhoneNumber('5551234567');
      expect(provider.e164Phone, '+15551234567');
    });
  });

  group('连接状态', () {
    test('setConnecting', () {
      provider.setConnecting(true);
      expect(provider.isConnecting, true);
      expect(provider.isConnected, true);

      provider.setConnecting(false);
      expect(provider.isConnecting, false);
    });

    test('setError', () {
      provider.setError('网络错误');
      expect(provider.errorMessage, '网络错误');

      provider.setError(null);
      expect(provider.errorMessage, null);
    });
  });

  group('万能验证码 (debug 模式 = 测试环境)', () {
    test('白名单手机号 + 123456 验证通过', () async {
      provider.setPhoneNumber('1172510903');
      final result = await provider.verifySmsCode('123456');
      expect(result, true);
    });

    test('正确手机号 + 错误验证码 = false', () async {
      provider.setPhoneNumber('1172510903');
      final result = await provider.verifySmsCode('654321');
      expect(result, false);
    });

    test('非白名单手机号 + 123456 = false', () async {
      provider.setPhoneNumber('13800138000');
      final result = await provider.verifySmsCode('123456');
      expect(result, false);
    });

    test('空手机号 + 123456 = false', () async {
      final result = await provider.verifySmsCode('123456');
      expect(result, false);
    });

    test('空验证码 = false', () async {
      provider.setPhoneNumber('1172510903');
      final result = await provider.verifySmsCode('');
      expect(result, false);
    });
  });

  group('reset', () {
    test('重置所有状态到默认值', () {
      provider.setPhoneNumber('13800138000');
      provider.setAgreed(true);
      provider.setConnecting(true);
      provider.setError('错误');
      provider.setCountryCode('+1');

      provider.reset();

      expect(provider.phoneNumber, '');
      expect(provider.isAgreed, false);
      expect(provider.isConnecting, false);
      expect(provider.errorMessage, null);
      expect(provider.countryCode, '+86');
      expect(provider.isLoginButtonEnabled, false);
    });
  });

  group('notifyListeners 触发', () {
    test('setPhoneNumber 触发通知', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.setPhoneNumber('13800138000');
      expect(notifyCount, 1);
    });

    test('setAgreed 触发通知', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.setAgreed(true);
      expect(notifyCount, 1);
    });

    test('reset 触发通知', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.reset();
      expect(notifyCount, 1);
    });
  });
}
