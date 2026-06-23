import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/call.dart';

/// 通话状态恢复入口控制器
///
/// 职责：
///   1. App 启动时尝试恢复上次通话
///   2. 统一快照读写（不分散在多个模块）
///
/// 调用时机：AppProvider.init() 末尾
class SessionRestoreService {
  static const _key = 'call_snapshot';

  /// 尝试恢复上次通话
  /// 返回被恢复的快照，null 表示无需恢复
  static Future<CallSnapshot?> tryRestore() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null || json.isEmpty) return null;

    try {
      final snapshot = CallSnapshot.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      if (snapshot.isValid && snapshot.state != CallState.idle) {
        return snapshot;
      }

      // 快照过期或已是 idle → 清理
      await prefs.remove(_key);
      return null;
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  /// 保存快照
  static Future<void> save(CallSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }

  /// 清除快照（通话正常结束时）
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
