import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局语言状态机 — 控制 App UI Locale
///
/// 蓝色地球弹窗（语言选择器）应同时调用此类更新 UI Locale，
/// 而非仅更改翻译引擎的目标语言。
class AppLanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('zh', 'CN');

  Locale get currentLocale => _currentLocale;

  /// 切换全局 UI Locale 并持久化
  Future<void> changeLanguage(String rawLocaleCode) async {
    final parts = rawLocaleCode.split('-');
    _currentLocale = Locale(parts[0], parts.length > 1 ? parts[1] : '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale_lang', rawLocaleCode);
    notifyListeners();
  }
}
