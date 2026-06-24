import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/app_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;
  bool _obscurePwd = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameCtl.dispose();
    _phoneCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameCtl.text.trim();
    final phone = _phoneCtl.text.trim();
    final password = _passwordCtl.text;
    final confirm = _confirmCtl.text;

    if (username.isEmpty) return _error('请输入用户名');
    if (phone.length < 9) return _error('手机号至少9位');
    if (password.length < 6) return _error('密码至少6位');
    if (password != confirm) return _error('两次密码不一致');

    setState(() => _loading = true);

    try {
      final p = context.read<AppProvider>();
      final baseUrl = p.serverUrl.replaceAll('wss://', 'https://').replaceAll('ws://', 'http://');
      final url = '$baseUrl/api/register';
      // Also try without the path if it's a cloudflare tunnel
      final resp = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'phone': phone, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(resp.body) as Map;
      if (data['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('注册成功，请登录')),
          );
          Navigator.pop(context, phone);
        }
      } else {
        _error(data['message'] as String? ?? '注册失败');
      }
    } catch (e) {
      _error('连接失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _error(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新用户注册')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _usernameCtl,
              decoration: const InputDecoration(
                labelText: '用户名',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtl,
              decoration: const InputDecoration(
                labelText: '手机号',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtl,
              obscureText: _obscurePwd,
              decoration: InputDecoration(
                labelText: '密码',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCtl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: '确认密码',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('注册', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
