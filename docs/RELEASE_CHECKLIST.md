# TalkTranslate Release Checklist

## ⬜ 1. 版本号更新

- [ ] `pubspec.yaml` — `version: 2.0.0+1` → 新版本号
- [ ] `android/app/build.gradle` — `versionName` 同步
- [ ] `README.md` — 更新版本号

## ⬜ 2. Android 签名配置

```bash
# 生成 keystore
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 填写 android/key.properties
```

- [ ] 生成 keystore
- [ ] 填写 `key.properties`（不要提交到 Git）
- [ ] CI secrets: `KEYSTORE_BASE64`, `KEY_STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`

## ⬜ 3. 权限检查

- [ ] `AndroidManifest.xml` 权限齐全
  - `SYSTEM_ALERT_WINDOW`
  - `FOREGROUND_SERVICE`
  - `POST_NOTIFICATIONS`（Android 13+）
  - `RECORD_AUDIO`
  - `INTERNET`
  - `ACCESS_NETWORK_STATE`

## ✅ 4. 代码审查修复 (v2.0.1)

本次代码审查已修复以下问题：

| # | 问题 | 文件 | 状态 |
|---|------|------|:----:|
| 1 | 通话记录在超时/失败路径下不保存 | `call_service.dart` | ✅ 已修复 |
| 2 | 通话页语言标签硬编码为中文/英文 | `call_screen.dart` | ✅ 改为动态语言选择 |
| 3 | WebSocket Stream 缺少 onError 处理器 | `signaling_service.dart` | ✅ 已添加 |
| 4 | 翻译 HTTP 请求无超时限制 | `translation_service.dart` | ✅ 添加 15s 超时 |
| 5 | "新建通话"按钮 onTap 为空 | `home_screen.dart` | ✅ 添加拨号对话框 |

## ⬜ 5. 构建验证

```bash
flutter clean
flutter pub get
flutter analyze              # 零警告零错误
flutter test                 # 全部通过

# 调试构建
flutter run                  # 真机测试通话流程

# 发布构建
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

- [ ] `flutter analyze` 零错误
- [ ] `flutter test` 全部通过
- [ ] 真机测试：注册 → 呼叫 → 通话 → 字幕 → 挂断
- [ ] 真机测试：悬浮窗最小化 → 权限 → 气泡显示
- [ ] 真机测试：前台服务通知显示
- [ ] 真机测试：杀进程后重新打开 → 状态恢复
- [ ] 真机测试：新建通话对话框 → 输入号码 → 呼叫

## ⬜ 6. Google Play 发布

- [ ] 创建 Google Play Console 开发者账号
- [ ] 创建应用（对应 `com.talktranslate.talktranslate`）
- [ ] 上传 AAB：`build/app/outputs/bundle/release/app-release.aab`
- [ ] 填写商店信息：
  - 标题：TalkTranslate
  - 简短描述：实时翻译语音通话
  - 完整描述：AI 实时翻译 · 12 种语言 · 悬浮窗
- [ ] 截图（至少 2 张）：通话页 + 设置页
- [ ] 隐私政策 URL
- [ ] 内容分级问卷
- [ ] 定价与分发：免费

## ⬜ 7. Android 兼容性

| 检查项 | 要求 | 状态 |
|--------|------|------|
| minSdk | 23 (Android 6.0) | ✅ 已配置 |
| targetSdk | 34 (Android 14) | ✅ |
| 32-bit abi | armeabi-v7a | ✅ split-per-abi |
| 64-bit abi | arm64-v8a | ✅ split-per-abi |
| x86_64 | 模拟器 | ✅ split-per-abi |

## ⬜ 8. 国产 ROM 适配

| 品牌 | 需要用户手动开启 |
|------|-----------------|
| 小米 | 设置 → 应用 → 悬浮窗权限 |
| 华为 | 设置 → 应用 → 权限 → 悬浮窗 |
| OPPO/VIVO | 设置 → 应用管理 → 悬浮窗 |
| 三星 | 默认允许 |

## ⬜ 9. 发布前最终检查

- [ ] 清空 SharedPreferences 后首次启动正常
- [ ] 无 API Key 时优雅提示（不崩溃）
- [ ] WebSocket 断开时自动重连
- [ ] 通话中按 Home 键 → 悬浮窗显示
- [ ] 悬浮窗挂断 → 通话真正结束
- [ ] ProGuard 未混淆关键类（检查 `proguard-rules.pro`）

---

> 版本：v2.0.1-dev
> 更新日期：2026-06-24
> 上一版本：v2.0.0 — 代码审查 + 5 个 Bug 修复
