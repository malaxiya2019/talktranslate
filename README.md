<div align="center">

# 🗣️ TalkTranslate v2

**实时双语翻译通话 App — Real-time bilingual translation calling app**

[![Build APK](https://github.com/malaxiya2019/talktranslate/actions/workflows/build-apk.yml/badge.svg)](https://github.com/malaxiya2019/talktranslate/actions/workflows/build-apk.yml)
[![GitHub release](https://img.shields.io/badge/version-2.0.2-blue)](https://github.com/malaxiya2019/talktranslate/releases)
![Tests](https://img.shields.io/badge/tests-185%20passing-brightgreen)

</div>

---

## What / 这是什么

**Real-time voice translation during phone calls.**  
Speak your language, the other person hears it in theirs.

**通话中实时语音翻译。** 你说中文，对方听到英文；对方说英文，你听到中文。

## Features / 功能特性

- 📞 **WebRTC 实时通话** — 全双工语音，低延迟
- 🌍 **12 种语言互译** — 中/英/日/韩/西/法/德/葡/阿/泰/越/俄
- 🤖 **多翻译引擎** — DeepSeek / OpenAI / Claude / DeepL / 百度
- 🏠 **悬浮窗模式** — 通话中最小化，字幕实时显示
- 🔐 **加密存储** — API Key 通过 FlutterSecureStorage 硬件级加密
- 👤 **用户系统** — 手机号注册 + JWT 认证
- 🛡️ **端到端加密** — 信令通过 WebSocket Secure (WSS)

## How it works / 工作原理

```
[You: 中文] → STT → LLM翻译 → TTS → [Peer: English]
[Peer: English] → STT → LLM翻译 → TTS → [You: 中文]
```

## Download APK / 下载 APK

GitHub Actions 自动构建：

1. 进入 **[Actions → Build APK](https://github.com/malaxiya2019/talktranslate/actions/workflows/build-apk.yml)**
2. 点击最新的成功 workflow
3. 滚动到 **Artifacts**
4. 下载对应架构：
   - `talktranslate-arm64-v8a` — 大部分 Android 手机（推荐）
   - `talktranslate-armeabi-v7a` — 旧设备
   - `talktranslate-x86_64` — 模拟器 / Chromebook

## Quick Start / 快速开始

### 1. 部署信令服务器（可选）

```bash
docker compose -f server/docker-compose.yml up -d
```

详细部署指南见 [server/DEPLOY.md](server/DEPLOY.md)

### 2. 获取 API Key

从 [platform.deepseek.com](https://platform.deepseek.com) 或 [platform.openai.com](https://platform.openai.com) 获取。

### 3. 在 App 中输入 Key

打开 App → 点击 ⚙️ → 粘贴 API Key → 保存。

## Architecture / 架构

### 前端 (Flutter)

```
lib/
├── main.dart                        # 入口
├── models/
│   ├── language.dart                 # 语言模型
│   └── call.dart                     # 通话状态机 + 通话记录
├── services/
│   ├── translation_service.dart      # LLM 翻译
│   ├── call_service.dart             # WebRTC 通话管理
│   ├── call_state_machine.dart       # 通话状态机
│   ├── call_stream_manager.dart      # 双流异步管理器
│   ├── signaling_service.dart        # WebSocket 信令
│   ├── translation_pipeline.dart     # STT→翻译→TTS 流水线
│   ├── engine_config_service.dart    # 翻译引擎配置
│   ├── network_monitor.dart          # 网络状态监听
│   ├── audio_focus_manager.dart      # 音频焦点管理
│   ├── foreground_service.dart       # 前台服务
│   ├── overlay_service.dart          # 悬浮窗服务
│   ├── session_restore_service.dart  # 会话恢复
│   └── edge_ai_engine.dart           # Edge AI 预留接口
├── providers/
│   ├── app_provider.dart             # 全局状态
│   └── login_provider.dart           # 登录状态
├── screens/
│   ├── app_shell.dart                # 底部导航壳
│   ├── home_screen.dart              # 首页（通话/联系人）
│   ├── call_screen.dart              # 通话页
│   ├── settings_screen.dart          # 设置页
│   ├── register_screen.dart          # 注册页
│   ├── engine_config_screen.dart     # 翻译引擎配置
│   └── history_screen.dart           # 通话历史
└── widgets/
    ├── call/                         # 通话组件
    ├── chat/                         # 聊天/翻译组件
    ├── common/                       # 通用组件
    └── overlay/                      # 悬浮窗组件
```

### 后端 (Node.js + Redis + PostgreSQL)

```
server/
├── index.js              # 信令服务器（WebSocket + REST API）
├── Dockerfile            # Docker 构建
├── docker-compose.yml    # 完整部署（含 Redis + PostgreSQL）
├── nginx.conf            # Nginx 反代 + WSS 配置
└── DEPLOY.md             # 部署指南
```

## Tech Stack / 技术栈

| 层 | 技术 |
|-------|--------|
| UI | Flutter + Material 3 |
| 通话 | WebRTC (`flutter_webrtc`) |
| 语音识别 | `speech_to_text` |
| 语音合成 | `flutter_tts` |
| 翻译 | DeepSeek / OpenAI / Claude / DeepL / 百度 |
| 状态管理 | Provider |
| 信令 | Node.js + WebSocket |
| 认证 | JWT (jsonwebtoken) |
| 存储 | PostgreSQL + Redis |
| 部署 | Docker + docker-compose |

## Testing / 测试

```bash
flutter test  # 105 个测试全部通过
```

## Release Checklist / 发布清单

参见 [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)

## License / 许可证

MIT
