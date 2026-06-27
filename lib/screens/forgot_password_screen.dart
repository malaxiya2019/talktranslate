import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/settings_provider.dart';
import '../providers/app_provider.dart';

/// 忘记密码页面
///
/// 流程：
///   1. 输入手机号 → 获取重置码
///   2. 输入重置码 + 新密码 → 提交重置
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;
  bool _codeSent = false;
  bool _obscurePwd = true;
  String? _errorMsg;

  @override
  void dispose() {
    _phoneCtl.dispose();
    _codeCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  String get _baseUrl {
    final url = context.read<SettingsProvider>().serverUrl;
    return url.replaceAll('wss://', 'https://').replaceAll('ws://', 'http://');
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtl.text.trim();
    if (phone.isEmpty) return;

    setState(() => _loading = true);
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(resp.body) as Map;
      if (data['ok'] == true) {
        setState(() {
          _codeSent = true;
          _loading = false;
          _errorMsg = null;
        });
        // 测试阶段直接显示验证码（生产环境应发短信）
        final code = data['code'];
        if (code != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('验证码: $code (测试模式)')),
          );
        }
      } else {
        setState(() {
          _loading = false;
          _errorMsg = data['message'] as String? ?? '发送失败';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = '网络错误: $e';
      });
    }
  }

  Future<void> _resetPassword() async {
    final phone = _phoneCtl.text.trim();
    final code = _codeCtl.text.trim();
    final password = _passwordCtl.text;
    final confirm = _confirmCtl.text;

    if (code.isEmpty) return _setError('请输入验证码');
    if (password.length < 6) return _setError('密码至少6位');
    if (password != confirm) return _setError('两次密码不一致');

    setState(() => _loading = true);
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'code': code,
          'newPassword': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(resp.body) as Map;
      if (data['ok'] == true) {
        if (data['token'] != null) {
          context.read<AppProvider>().setAuthToken(data['token'] as String);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码已重置成功')),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _loading = false;
          _errorMsg = data['message'] as String? ?? '重置失败';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = '网络错误: $e';
      });
    }
  }

  void _setError(String msg) {
    setState(() => _errorMsg = msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('重置密码')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 手机号
            TextField(
              controller: _phoneCtl,
              enabled: !_codeSent,
              decoration: const InputDecoration(
                labelText: '手机号',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (!_codeSent) ...[
              // 获取验证码按钮
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : const Text('获取验证码',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],

            if (_codeSent) ...[
              // 验证码
              TextField(
                controller: _codeCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '验证码',
                  prefixIcon: Icon(Icons.sms),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 新密码
              TextField(
                controller: _passwordCtl,
                obscureText: _obscurePwd,
                decoration: InputDecoration(
                  labelText: '新密码',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 确认密码
              TextField(
                controller: _confirmCtl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '确认新密码',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 提交按钮
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : const Text('重置密码',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],

            // 错误信息
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
