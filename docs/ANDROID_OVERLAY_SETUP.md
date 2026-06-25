# TalkTranslate — Android 保活 & 悬浮窗集成指南

## 目录
- [① 获取依赖](#①-获取依赖)
- [② 权限检查清单](#②-权限检查清单)
- [③ 前台服务保活配置](#③-前台服务保活配置)
- [④ 运行时权限](#④-运行时权限)
- [⑤ 电池优化白名单](#⑤-电池优化白名单)
- [⑥ 构建并运行](#⑥-构建并运行)
- [国产 ROM 注意事项](#国产-rom-注意事项)
- [诊断](#诊断)

---

## ① 获取依赖

```bash
cd /path/to/talktranslate
flutter pub get
```

---

## ② 权限检查清单

确保 `android/app/src/main/AndroidManifest.xml` 包含以下全部内容：

### ✅ 必要权限

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- 悬浮窗核心 -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>

<!-- 前台服务保活（Android 14+ 类型精确匹配） -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_COMMUNICATION"/>

<!-- Android 13+ 通知权限 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- 电池优化白名单引导 -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

### ✅ 前台服务声明

通话保活服务（类型匹配实际用途：麦克风 + 通信）：
```xml
<service
    android:name=".CallForegroundService"
    android:exported="false"
    android:foregroundServiceType="microphone|communication"/>
```

悬浮窗服务：
```xml
<service
    android:name=".OverlayService"
    android:exported="false"
    android:foregroundServiceType="mediaProjection"/>
```

### ✅ FlutterOverlayWindow Activity

```xml
<activity android:name="com.xiaohao.overlay_window.FlutterOverlayWindow"
    android:theme="@style/Theme.AppCompat.NoActionBar"
    android:taskAffinity=""
    android:excludeFromRecents="true"
    android:enableOnBackInvokedCallback="false"
    android:showWhenLocked="false"
    android:turnScreenOn="false" />
```

---

## ③ 前台服务保活配置

### 保活策略

TalkTranslate 使用三层保活机制：

| 层 | 机制 | 说明 |
|----|------|------|
| 1 | `startForeground()` 持久通知 | Android 8+ 必须显示通知才能存活 |
| 2 | `START_STICKY` | 被系统杀死后自动重建服务 |
| 3 | `onTaskRemoved()` | 用户滑动杀任务后尝试自启 |

### 通话通知

通话启动后，通知栏显示：

```
TalkTranslate · 张三
📞 通话中 03:25
```

点击通知回到通话界面。

### Flutter 端生命周期

```
CallState.inCall  → ForegroundService().start()  → 前台服务启动
每秒 tick         → ForegroundService().update() → 通知更新时间
CallState.idle    → ForegroundService().stop()   → 前台服务停止
```

---

## ④ 运行时权限

### 悬浮窗权限

Android 10+ 需要运行时动态请求。TalkTranslate 已集成：

```dart
// 自动请求
await FlutterOverlayWindow.requestPermission();
```

### 通知权限 (Android 13+)

应用启动后在设置页的"保活设置"卡片中可一键请求，或在代码中：

```dart
await ForegroundService().requestNotificationPermission();
```

---

## ⑤ 电池优化白名单

### 为什么需要

Android 6+ 的 Doze 模式会在后台杀死应用进程。加入白名单后，通话期间不会被系统中断。

### 设置页操作

1. 打开 App → 设置页
2. 找到 **"🔋 保活设置"** 卡片
3. 如果显示 ❌，点击 **"修复"** 按钮
4. 在弹出的系统设置中开启"允许后台运行"

### 代码调用

```dart
ForegroundService().requestBatteryOptimizationWhitelist();
```

### 国产 ROM 额外步骤

部分国产 ROM 即使加入系统白名单仍可能杀进程，需手动添加：

| 品牌 | 路径 |
|------|------|
| 小米 | 设置 → 应用 → TalkTranslate → **省电策略 → 无限制** |
| 华为 | 设置 → 应用 → 应用启动管理 → TalkTranslate → **手动管理 → 全部允许** |
| OPPO | 设置 → 应用管理 → TalkTranslate → **省电 → 允许后台运行** |
| VIVO | 设置 → 电池 → 后台耗电管理 → TalkTranslate → **允许后台运行** |

---

## ⑥ 构建并运行

```bash
flutter run
```

首次进入通话页 → 点击 **最小化** → 首次会弹悬浮窗权限请求 → 授权 → 回到主页，看到悬浮气泡。

---

## 已配置权限总表

| 权限 | 用途 | 级别 |
|------|------|------|
| `SYSTEM_ALERT_WINDOW` | 悬浮窗覆盖 | 🔴 必需 |
| `FOREGROUND_SERVICE` | 后台保活 | 🔴 必需 |
| `FOREGROUND_SERVICE_MICROPHONE` | Android 14+ 麦克风类型声明 | 🔴 必需 |
| `POST_NOTIFICATIONS` | Android 13+ 通知 | 🔴 必需 |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | 电池白名单引导 | 🟡 建议 |
| `RECORD_AUDIO` | WebRTC 麦克风 | 🔴 必需 |
| `INTERNET` | 网络通信 | 🔴 必需 |
| `ACCESS_NETWORK_STATE` | 网络状态检测 | 🟢 推荐 |

---

## 诊断：如果通话被杀死

```
1. 检查 AndroidManifest 是否包含 FOREGROUND_SERVICE + POST_NOTIFICATIONS
2. 检查 foregroundServiceType 是否为 "microphone|communication"
3. 打开设置页 → 保活设置 → 确认 ✅ 通知权限 + ✅ 电池白名单
4. 检查国产 ROM 的"受保护应用"列表
5. adb logcat | grep -E 'CallForeground|Overlay|talktranslate' 查看日志
```
