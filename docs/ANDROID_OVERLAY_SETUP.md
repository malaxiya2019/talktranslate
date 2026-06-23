# TalkTranslate — Android 悬浮窗集成指南

## ⚠️ 先检查：Android 目录是否已存在

```bash
ls android/app/src/main/AndroidManifest.xml
```

- **有输出** → 已有 Android 项目，跳到第 ② 步
- **无输出** → 缺失 Android 文件，执行：

```bash
# 安全创建 — 仅补缺失文件，不覆盖已有的自定义内容
flutter create --platforms=android .
# 然后手动 merge 本指南中的配置
```

> **不要盲目运行 `flutter create`** — 它会覆盖 `AndroidManifest.xml`、`build.gradle` 等自定义文件。

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

<!-- 前台服务保活 -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_COMMUNICATION"/>

<!-- Android 13+ 通知 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
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

## ③ Gradle 版本检查

`android/app/build.gradle`:

```groovy
defaultConfig {
    minSdk 23        // Android 6.0+ (悬浮窗必需)
    targetSdk 34     // 推荐 >= 33
}
```

---

## ④ 运行时权限（关键）

Android 10+ 需要**运行时动态请求**悬浮窗权限。TalkTranslate 已集成在 `OverlayService.show()` 中：

```dart
// lib/services/overlay_service.dart 中
await FlutterOverlayWindow.requestPermission();
```

如果首次授权失败，引导用户手动开启：

```dart
// 检查是否有悬浮窗权限
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

if (!await FlutterOverlayWindow.isPermissionGranted()) {
  // 引导用户去设置
  await FlutterOverlayWindow.requestPermission();
}
```

---

## ⑤ 前台服务声明（防杀保活）

如果使用前台服务，在 `<application>` 内添加：

```xml
<service
    android:name=".OverlayService"
    android:exported="false"
    android:foregroundServiceType="mediaProjection"/>
```

> **注意**：`flutter_overlay_window` 内部已管理前台服务，此项为可选增强。

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
| `FOREGROUND_SERVICE` | 后台保活 | 🟡 建议 |
| `POST_NOTIFICATIONS` | Android 13+ 通知 | 🟡 建议 |
| `RECORD_AUDIO` | WebRTC 麦克风 | 🔴 必需 |
| `INTERNET` | 网络通信 | 🔴 必需 |
| `ACCESS_NETWORK_STATE` | 网络状态检测 | 🟢 推荐 |

---

## 国产 ROM 注意事项

| 品牌 | 路径 |
|------|------|
| 小米 | 设置 → 应用 → TalkTranslate → 显示悬浮窗 → 开启 |
| 华为 | 设置 → 应用 → 权限 → 悬浮窗 → TalkTranslate → 开启 |
| OPPO/VIVO | 设置 → 应用管理 → TalkTranslate → 悬浮窗 → 开启 |

---

## 诊断：如果悬浮窗不显示

```
1. 检查 AndroidManifest 是否包含 SYSTEM_ALERT_WINDOW
2. 检查 minSdk >= 23
3. 检查应用权限设置中"悬浮窗"是否已开启
4. adb logcat | grep Overlay 查看错误日志
```
